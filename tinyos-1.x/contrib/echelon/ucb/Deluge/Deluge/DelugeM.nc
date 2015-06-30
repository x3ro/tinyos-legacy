
/**
 * DelugeM.nc - Manages advertisements of image data and communication
 * to update metadata. Also notifies <code>DelugePageTransfer</code>
 * of nodes to request data from.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

module DelugeM {
  provides {
    interface NetProg;
    interface StdControl;
  }
  uses {
    interface BitVecUtils;
    interface DelugeMetadata as Metadata;
    interface StdControl as MetadataControl;
    interface StdControl as PageTransferControl;
    interface DelugePageTransfer as PageTransfer;
    interface Random;
    interface ReceiveMsg as ReceiveAdvMsg;
    interface ReceiveMsg as ReceiveReqUpdMetadataMsg;
    interface ReceiveMsg as ReceiveUpdMetadataMsg;
    interface SendMsg as SendAdvMsg;
    interface SendMsg as SendReqUpdMetadataMsg;
    interface SendMsg as SendUpdMetadataMsg;
    interface Leds;
    interface Timer;

#ifdef DELUGE_REPORTING_UART
    interface SendMsg as SendDbgMsg;
#endif

#ifdef DELUGE_REPORTING_MHOP
    interface Send    as SendDbgMHop;
    interface RouteControl;
#endif

#ifndef PLATFORM_PC
    event result_t sendDurationMsg(uint8_t status, uint16_t value);
#endif
  }
}

implementation {
  // message buffers, pointers, and guard flags
  TOS_Msg  advMsgBuf, updMetadatasMsgBuf, reqMsgBuf;
  bool     isAdvMsgSending, isReqUpdMetadataMsgSending, isUpdMetadataMsgSending;
  DelugeAdvMsg            *pAdvMsg;
  DelugeReqUpdMetadataMsg *pReqUpdMetadataMsg;
  DelugeUpdMetadataMsg    *pUpdMetadataMsg;

  // state variables
  uint8_t   state;                     // general state of protocol
  imgvnum_t newMetadataVNum = 0;       // version of image to match metadata
  imgvnum_t updateMetadataVNum;        // for sending update messages to remember what version we're upgrading
  uint16_t  nodeMostRecentlyAdv;       // node which most recently advertised useful data
  DelugeImgSummary mostRecentSummary;  // img summary corresponding to nodeMostRecentlyAdv
  uint8_t   newDataAdvsRequired;       // number of advertisment to send before requesting more data
  uint8_t   overheardAdvs;             // counter of many advertisment before advertising
  uint8_t   curUpdPkt;                 // counter to keep track of which update packet is being sent
  bool      metadataReady = FALSE;
  int8_t    rebootDelay = -1;
  uint32_t  advPeriod = DELUGE_MAX_ADV_LISTEN_PERIOD;
  bool      receivedDifferentAdv = FALSE;

  // remember the state of COMM so that we can restore when done
  bool isCrcCheck, isPromiscuous;

  enum {
    S_DISABLED,
    S_ADV,
    S_UPDATE_METADATA,
    S_TRANSFERRING,
  };

  enum {
    EP_SENDVERSION = 1,
  };
  uint8_t sendVersion;

  void switchState(uint8_t _state);

  uint8_t checkSum(uint16_t addr, uint8_t group, uint16_t pid) {
    return ~(addr + group + pid);
  }

  void reboot(uint16_t vNum) {
    eeprom_write_byte ((uint8_t*)(AVREEPROM_GROUPID_ADDR), TOS_AM_GROUP);
    eeprom_write_byte ((uint8_t*)(AVREEPROM_LOCALID_ADDR), TOS_LOCAL_ADDRESS);//lsbyte
    eeprom_write_byte ((uint8_t*)AVREEPROM_LOCALID_ADDR+1, (TOS_LOCAL_ADDRESS>>8));//msbyte
    eeprom_write_byte ((uint8_t*)(AVREEPROM_PID_ADDR), vNum);//lsbyte
    eeprom_write_byte ((uint8_t*)(AVREEPROM_PID_ADDR+1), (vNum>>8));//msbyte
    eeprom_write_byte ((uint8_t*)(AVREEPROM_CHECKSUM_ADDR), checkSum(TOS_LOCAL_ADDRESS, TOS_AM_GROUP, vNum));//msbyte
    while (!eeprom_is_ready()); //wait for eeprom to finish
    // disable interrupts
    cli();
    // reboot
    ((start_t)(0x1f800))((uint16_t)1, ((uint32_t)call Metadata.getImgSize()));      
  }

  // returns vnum that is begin executed
  uint16_t loadMoteInfo() {

    uint16_t runningVNum = 0;

#ifndef PLATFORM_PC
    // grab addr, pid, and gid from internal flash
    uint16_t addr, pid;
    uint8_t group, sum;
    addr = eeprom_read_word((uint16_t*)AVREEPROM_LOCALID_ADDR);
    pid = eeprom_read_word((uint16_t*)AVREEPROM_PID_ADDR);
    group = eeprom_read_byte((uint8_t*)AVREEPROM_GROUPID_ADDR);
    sum = eeprom_read_byte((uint8_t*)AVREEPROM_CHECKSUM_ADDR);
    if (sum == checkSum(addr, group, pid)) {
      TOS_AM_GROUP = group;
      atomic TOS_LOCAL_ADDRESS = addr;
      runningVNum = pid;
    } else {
      runningVNum = 0;
    }
    while (!eeprom_is_ready()); //wait for eeprom to finish
#endif

    return runningVNum;

  }

  void initState() {
    switchState(S_DISABLED);
    nodeMostRecentlyAdv = TOS_BCAST_ADDR;
    newDataAdvsRequired = 0;
    curUpdPkt = 0;
    rebootDelay = -1;
  }

  command result_t StdControl.init() {

    uint16_t runningVNum = 0;

#ifndef PLATFORM_PC
    runningVNum = loadMoteInfo();
#endif

    // initialize message buffers, pointers, guard flags
    pAdvMsg = (DelugeAdvMsg*)advMsgBuf.data;
    pAdvMsg->sourceAddr = TOS_LOCAL_ADDRESS;
    pAdvMsg->runningVNum = runningVNum;
    isAdvMsgSending = FALSE;
    pUpdMetadataMsg = (DelugeUpdMetadataMsg*)updMetadatasMsgBuf.data;
    isUpdMetadataMsgSending = FALSE;
    pReqUpdMetadataMsg = (DelugeReqUpdMetadataMsg*)reqMsgBuf.data;
    isReqUpdMetadataMsgSending = FALSE;

    // initialize state variables
    initState();

    call Leds.init();

    return call MetadataControl.init();

  }

  command result_t StdControl.start() {

    result_t result = SUCCESS;

    if (state != S_DISABLED)
      return SUCCESS;

    // remmeber old values so that we can restore
    initState();
    state = S_ADV;
    if (metadataReady) {
      call PageTransferControl.init();
      call PageTransferControl.start();
      call Timer.start(TIMER_ONE_SHOT, 
		       advPeriod + 
		       call Random.rand() % advPeriod);
    }
    else {
      result = rcombine(call MetadataControl.start(), result);
    }
    
    return result;
    
  }

  command result_t StdControl.stop() {

    result_t result = SUCCESS;

    if (state == S_DISABLED)
      return SUCCESS;

    state = S_DISABLED;
    // stop page transfers
    result = rcombine(call PageTransferControl.stop(), result);
    // restore old values of comm
    result = rcombine(call MetadataControl.stop(), result);
    
    return result;

  }

  command result_t NetProg.getVersionsAvailable(uint16_t* vNums) {
    // not implemented
    return FAIL;
  }

  command uint16_t NetProg.getExecutingVersion() {
    return pAdvMsg->runningVNum;
  }
  
  command uint16_t NetProg.getFlashVersion() {
    return call Metadata.getVNum();
  }

  command result_t NetProg.prepBootImg(uint16_t vNum) {
    // not implemented
    return FAIL;
  }

  event result_t Metadata.ready(result_t result) {

    metadataReady = TRUE;
    newMetadataVNum = call Metadata.getVNum();
    dbg(DBG_USR1, "DELUGE: START(vNum=%d)\n", newMetadataVNum);
    dbg(DBG_USR2, "DELUGE: @%lld START(vNum=%d,numPgs=%d,delay=%d)\n", 
	tos_state.tos_time, newMetadataVNum, call Metadata.getNumPgs(),
	NODE_0_STARTUP_DELAY);

    if (state != S_DISABLED) {
      // start advertising
      call PageTransferControl.init();
      call PageTransferControl.start();
      call Timer.start(TIMER_ONE_SHOT, 
		       advPeriod + 
		       call Random.rand() % advPeriod);
    }

    return SUCCESS;

  }

#ifdef DELUGE_REPORTING_MHOP
  TOS_Msg reportMsg;
  static const char program_name[] = IDENT_PROGRAM_NAME;

  task void report() {
    DelugeReportingMsg *drm;
    uint16_t len;

    if (call RouteControl.getParent() == TOS_BCAST_ADDR)
      return;

    if ((drm = (DelugeReportingMsg*) 
	call SendDbgMHop.getBuffer(&reportMsg, &len))) {
      
      call Metadata.getImgSummary(&pAdvMsg->summary);
      drm->vNum = pAdvMsg->summary.vNum;
      if (rebootDelay > 0) {
	drm->runningVNum = pAdvMsg->runningVNum-1;
      } else {
	drm->runningVNum = pAdvMsg->runningVNum;
      }
      drm->unixTime = IDENT_UNIX_TIME;
      memcpy(drm->programName, program_name, MAX_PROGNAME_CHARS);
      drm->numPages = call Metadata.getNumPgs();
      drm->numPagesComplete = call Metadata.getNumPgsComplete();

      if (call SendDbgMHop.send(&reportMsg, sizeof(DelugeReportingMsg))
	  == SUCCESS) {
	dbg(DBG_USR1, "SUCCESS!\n");
	return;
      }
    }
  }

  event result_t SendDbgMHop.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
#endif


  event result_t Timer.fired() {

    // don't do anything if disabled
    if (state == S_DISABLED)
      return SUCCESS;

/*
    if (call Metadata.getNumPgsComplete() == call Metadata.getNumPgs())
      call Leds.redOn();
    else
      call Leds.redOff();
*/

    if (rebootDelay > 0) {
      if (--rebootDelay == 0) 
	reboot(call Metadata.getVNum());
    }

    switch(state) {
    case S_ADV:
      // broadcast advertisement
      // count how many times we advertised new data
      if (newDataAdvsRequired)
	newDataAdvsRequired--;

      if (!receivedDifferentAdv) {
	advPeriod = (3*advPeriod) / 2;
	if (advPeriod > DELUGE_MAX_ADV_LISTEN_PERIOD)
	  advPeriod = DELUGE_MAX_ADV_LISTEN_PERIOD;
      }
      receivedDifferentAdv = FALSE;

      if (overheardAdvs < MAX_OVERHEARD_ADVS &&
	  !isAdvMsgSending) {
	// copy image summary
	call Metadata.getImgSummary(&pAdvMsg->summary);

	isAdvMsgSending = call SendAdvMsg.send(TOS_BCAST_ADDR, sizeof(DelugeAdvMsg), &advMsgBuf);
	if (isAdvMsgSending) {
	  dbg(DBG_USR1, "DELUGE: Sent ADV_MSG(vNum=%d,pagesInImg=%d,numPgsComplete=%d)\n",
	      pAdvMsg->summary.vNum, call Metadata.getNumPgs(), 
	      pAdvMsg->summary.numPgsComplete);
	}
      } else {
#ifdef DELUGE_REPORTING_MHOP	
	post report();
#endif
      }

      overheardAdvs = 0;
      call Timer.start(TIMER_ONE_SHOT, advPeriod + 
		       call Random.rand() % advPeriod);
      break;

    case S_UPDATE_METADATA:
      // request update info for version vector
      if (!isReqUpdMetadataMsgSending) {
	uint16_t dest = (nodeMostRecentlyAdv == TOS_UART_ADDR) 
	  ? TOS_UART_ADDR : TOS_BCAST_ADDR;
	pReqUpdMetadataMsg->vNum = call Metadata.getPrevVNum();
	pReqUpdMetadataMsg->dest = nodeMostRecentlyAdv;
	if (call SendReqUpdMetadataMsg.send(dest, 
					    sizeof(DelugeReqUpdMetadataMsg), 
					    &reqMsgBuf)
	    == FAIL) {
	  // restart timer and try again
	  isReqUpdMetadataMsgSending = FALSE;
	  call Timer.start(TIMER_ONE_SHOT, FAILED_SEND_DELAY);
	}
	else {
	  dbg(DBG_USR1, "DELUGE: Sent REQ_UPD_METADATA_MSG(dest=%d,vnum=%d)\n", 
	      nodeMostRecentlyAdv,pReqUpdMetadataMsg->vNum);
	}
      }
      break;
    case S_TRANSFERRING:
      call Timer.start(TIMER_ONE_SHOT, advPeriod +
		       advPeriod);
      break;
    }

    return SUCCESS;

  }

  event TOS_MsgPtr ReceiveAdvMsg.receive(TOS_MsgPtr pMsg) {

    DelugeAdvMsg *rxAdvMsg = (DelugeAdvMsg*)pMsg->data;
    imgvnum_t vNum = call Metadata.getVNum();
    uint16_t  numPgsComplete = call Metadata.getNumPgsComplete();

    // don't do anything if disabled
    if (state == S_DISABLED)
      return pMsg;

    dbg(DBG_USR1, "DELUGE: Received ADV_MSG(source=%d,vnum=%d,numPgsComplete=%d)\n",
	rxAdvMsg->sourceAddr, rxAdvMsg->summary.vNum, rxAdvMsg->summary.numPgsComplete);

#ifndef PLATFORM_PC
    if (((rxAdvMsg->runningVNum == vNum)
	 || (rxAdvMsg->runningVNum == 0xffff && rxAdvMsg->sourceAddr == TOS_UART_ADDR))
	&& (pAdvMsg->runningVNum < vNum)
	&& (numPgsComplete == call Metadata.getNumPgs())
	&& (numPgsComplete != 0)
	&& (!call Metadata.isUpdating())) {
      pAdvMsg->runningVNum = vNum;
      rebootDelay = 4;
    }
#endif

    switch(state) {
    case S_ADV:
      if (rxAdvMsg->summary.vNum == vNum 
	  && rxAdvMsg->summary.numPgsComplete == numPgsComplete) {
	if (rxAdvMsg->runningVNum == pAdvMsg->runningVNum
	    && rxAdvMsg->sourceAddr != TOS_UART_ADDR) {
	  // record number of similar advs
	  overheardAdvs++;
	}
	else if (rxAdvMsg->sourceAddr == TOS_UART_ADDR
		 && !isAdvMsgSending) {
	  // send a message back to say we're done!
	  call Metadata.getImgSummary(&pAdvMsg->summary);
	  isAdvMsgSending = call SendAdvMsg.send(TOS_UART_ADDR, sizeof(DelugeAdvMsg), &advMsgBuf);
	}
      }
      else {
	if (advPeriod != DELUGE_ADV_LISTEN_PERIOD) {
	  call Timer.stop();
	  call Timer.start(TIMER_ONE_SHOT, advPeriod + call Random.rand() % advPeriod);
	  receivedDifferentAdv = TRUE;
	  advPeriod = DELUGE_ADV_LISTEN_PERIOD;
	}
      }
      // fall through
    case S_TRANSFERRING:
      if (call Metadata.isNewer(&rxAdvMsg->summary)) {
	// there is a newer version to match, have to update metadata
	nodeMostRecentlyAdv = rxAdvMsg->sourceAddr;
	mostRecentSummary = rxAdvMsg->summary;
	switchState(S_UPDATE_METADATA);
	newMetadataVNum = rxAdvMsg->summary.vNum;
	// disable page transfers
	call PageTransferControl.stop();
	// randomized request timeout to prevent collisions
	call Timer.stop();
	call Timer.start(TIMER_ONE_SHOT, 
			 DELUGE_MIN_DELAY + call Random.rand() % DELUGE_ADV_LISTEN_PERIOD);
      }
      else if (rxAdvMsg->summary.vNum == vNum &&
	       rxAdvMsg->summary.numPgsComplete > numPgsComplete &&
	       !newDataAdvsRequired) {
	// remember node which most recently advertised if it has data we need
	nodeMostRecentlyAdv = rxAdvMsg->sourceAddr;
	mostRecentSummary = rxAdvMsg->summary;
	call PageTransfer.setNewSource(nodeMostRecentlyAdv);
      }
      break;
      
    case S_UPDATE_METADATA:
      if (rxAdvMsg->summary.vNum >= newMetadataVNum) {
	// update to reflect most recently advertised node
	nodeMostRecentlyAdv = rxAdvMsg->sourceAddr;
	mostRecentSummary = rxAdvMsg->summary;
	if (rxAdvMsg->summary.vNum > newMetadataVNum) {
	  // found an even newer version, update and reset timer
	  newMetadataVNum = rxAdvMsg->summary.vNum;
	  call Timer.stop();
	  call Timer.start(TIMER_ONE_SHOT, 
			   DELUGE_MIN_DELAY + call Random.rand() % DELUGE_ADV_LISTEN_PERIOD);
	}
      }
      break;
    }

    return pMsg;

  }

  event TOS_MsgPtr ReceiveReqUpdMetadataMsg.receive(TOS_MsgPtr pMsg) {

    DelugeReqUpdMetadataMsg *rxReqMsg = (DelugeReqUpdMetadataMsg*)pMsg->data;

    // don't do anything if disabled
    if (state == S_DISABLED)
      return pMsg;

    if (rxReqMsg->dest != TOS_LOCAL_ADDRESS) {
      // overheard an update metadata request
      if (state == S_UPDATE_METADATA 
	  && rxReqMsg->vNum == call Metadata.getVNum()) {
	// overheard a similar update metadata request, so suppress for a bit
	call Timer.stop();
	call Timer.start(TIMER_ONE_SHOT, advPeriod + 
			 (call Random.rand() % advPeriod));
      }
    }
    else {
      // received a request to update metadata
      dbg(DBG_USR1, "DELUGE: Received REQ_UPD_METADATA_MSG(oldVNum=%d)\n",
	  rxReqMsg->vNum);
      if ((curUpdPkt == 0)
	  && !isUpdMetadataMsgSending) {
	// generate and send page diff
	updateMetadataVNum = rxReqMsg->vNum;
	if (call Metadata.generatePageDiff(&pUpdMetadataMsg->diff, rxReqMsg->vNum, 
					   curUpdPkt)
	    == FAIL) {
	  return pMsg;
	}
	if (call SendUpdMetadataMsg.send(TOS_BCAST_ADDR, sizeof(DelugeUpdMetadataMsg), 
					 &updMetadatasMsgBuf)
	    == SUCCESS) {
	  isUpdMetadataMsgSending = TRUE;
#ifdef PLATFORM_PC
	  {
	    char buf[100];
	    call BitVecUtils.printBitVec(buf, pUpdMetadataMsg->diff.updateVector, 
				         16);
	    dbg(DBG_USR1, 
		"DELUGE: Sent UPD_METADATA_MSG(pktNum=%d,newVNum=%d,imgSize=%d,%s)\n",
		curUpdPkt, pUpdMetadataMsg->diff.vNum, pUpdMetadataMsg->diff.imgSize, buf);
	  }
#endif
	  curUpdPkt++;
	}
	else {
	  // send failed
	  isUpdMetadataMsgSending = FALSE;
	  call Timer.stop();
	  call Timer.start(TIMER_ONE_SHOT, FAILED_SEND_DELAY);
	}
      }
    }      
    
    return pMsg;
    
  }

  event TOS_MsgPtr ReceiveUpdMetadataMsg.receive(TOS_MsgPtr pMsg) {

    DelugeUpdMetadataMsg *rxUpdMetadataMsg = (DelugeUpdMetadataMsg*)pMsg->data;

    // don't do anything if disabled
    if (state == S_DISABLED)
      return pMsg;

    if (rxUpdMetadataMsg->diff.vNum > call Metadata.getVNum()
	|| (call Metadata.isUpdating()
	    && (rxUpdMetadataMsg->diff.vNum == newMetadataVNum
		|| newMetadataVNum == 0xffff))) {

      if (state == S_ADV) {
	switchState(S_UPDATE_METADATA);
	newMetadataVNum = rxUpdMetadataMsg->diff.vNum;
	mostRecentSummary.numPgsComplete = 0;
      }

      // update metadata
      call Metadata.applyPageDiff(&rxUpdMetadataMsg->diff);
      
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT, DELUGE_NACK_TIMEOUT + 
		       call Random.rand() % DELUGE_ADV_LISTEN_PERIOD);

    }

    return pMsg;

  }


#ifdef DELUGE_REPORTING_UART
  TOS_Msg durationMsg;

  task void retryDbg() {
    if (call SendDbgMsg.send(TOS_UART_ADDR, sizeof(DelugeDurationMsg), &durationMsg)
        == FAIL)
      post retryDbg();
  }

  event result_t SendDbgMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
#endif

  event result_t Metadata.applyPageDiffDone(result_t result) {

    // don't do anything if disabled
    if (state == S_DISABLED)
      return SUCCESS;

    // reset state to advertising
    switchState(S_ADV);
    
    call Timer.start(TIMER_ONE_SHOT, DELUGE_MIN_DELAY + 
		     call Random.rand() % DELUGE_ADV_LISTEN_PERIOD);

    // reset and enable page transfers
    call PageTransferControl.init();
    call PageTransferControl.start();

#ifdef DELUGE_REPORTING_UART
    {
      DelugeDurationMsg *ddm;
      ddm = (DelugeDurationMsg *)durationMsg.data;
      ddm->sourceAddr = TOS_LOCAL_ADDRESS;
      ddm->status = DELUGE_DL_START;
      ddm->value = call Metadata.getVNum();;
      if (call SendDbgMsg.send(TOS_UART_ADDR, sizeof(DelugeDurationMsg), &durationMsg)
	  == FAIL)
	post retryDbg();
    }
#endif

    return SUCCESS;

  }

  event result_t PageTransfer.transferBegin() {
    switchState(S_TRANSFERRING);
    dbg(DBG_USR1, "DELUGE: STATE(TRANSFER_BEGIN)\n");
    call Timer.stop();
    call Timer.start(TIMER_ONE_SHOT, advPeriod +
		     DELUGE_ADV_LISTEN_PERIOD);
    return SUCCESS;
  }

  event result_t PageTransfer.transferDone(bool isReceiving) {

    dbg(DBG_USR1, "DELUGE: STATE(ADV)\n");
    switchState(S_ADV);
    receivedDifferentAdv = TRUE;
    if (newDataAdvsRequired && isReceiving)
      call Timer.start(TIMER_ONE_SHOT, DELUGE_MIN_DELAY + 
		       call Random.rand() % DELUGE_ADV_LISTEN_PERIOD);
    else
      call Timer.start(TIMER_ONE_SHOT, advPeriod + 
		       call Random.rand() % advPeriod);
    
    return SUCCESS;

  }

  event result_t SendAdvMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    if (pMsg == (TOS_MsgPtr)&advMsgBuf)
      isAdvMsgSending = FALSE;

#ifdef DELUGE_REPORTING_MHOP
    post report();
#endif
    return SUCCESS;
  }

  event result_t SendUpdMetadataMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {

    if (pMsg == (TOS_MsgPtr)&updMetadatasMsgBuf) {
      isUpdMetadataMsgSending = FALSE;
      // generate and send page diff if there are more
      if (call Metadata.generatePageDiff(&pUpdMetadataMsg->diff, 
					 updateMetadataVNum, curUpdPkt) 
	  == FAIL) {
	// no more updates to send
	curUpdPkt = 0;
	return SUCCESS;
      }
      
      // more updates to send, so send again
      if (call SendUpdMetadataMsg.send(TOS_BCAST_ADDR, sizeof(DelugeUpdMetadataMsg), 
				       &updMetadatasMsgBuf)
	  == SUCCESS) {
	isUpdMetadataMsgSending = TRUE;
#ifdef PLATFORM_PC
	{
	  char buf[100];
	  call BitVecUtils.printBitVec(buf, pUpdMetadataMsg->diff.updateVector, 
				       16);
	  dbg(DBG_USR1, 
	      "DELUGE: Sent UPD_METADATA_MSG(pktNum=%d,newVNum=%d,imgSize=%d,%s)\n",
	      curUpdPkt,pUpdMetadataMsg->diff.vNum, pUpdMetadataMsg->diff.imgSize, buf);
	}
#endif
	curUpdPkt++;
      }
      else {
	// send failed
	isUpdMetadataMsgSending = FALSE;
	call Timer.stop();
	call Timer.start(TIMER_ONE_SHOT, FAILED_SEND_DELAY);
      }
    }
    
    return SUCCESS;
  }

  event result_t SendReqUpdMetadataMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    if (pMsg == (TOS_MsgPtr)&reqMsgBuf) {
      isReqUpdMetadataMsgSending = FALSE;
      call Timer.start(TIMER_ONE_SHOT, DELUGE_NACK_TIMEOUT +
		       call Random.rand() % DELUGE_ADV_LISTEN_PERIOD);
    }
    return SUCCESS;
  }

  event result_t PageTransfer.receivedNewData() {
    newDataAdvsRequired = NUM_NEWDATA_ADVS_REQUIRED;
    overheardAdvs = 0;
    if (state == S_ADV) {
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT, DELUGE_MIN_DELAY +
		       call Random.rand() % DELUGE_ADV_LISTEN_PERIOD);
    }
    return SUCCESS;
  }

  event result_t PageTransfer.overheardData(uint16_t pgNum) {
    return SUCCESS;
  }

/*
  event result_t Epidemic.changeHandler(uint8_t channel, uint8_t *pData) {
    return SUCCESS;
  }

  event result_t MessageLogger.logMessageDone(LogMessage *msg, 
					      result_t success) {
    return SUCCESS;
  }
*/

  void switchState(uint8_t _state) {

    // can only switch state out of disabled by setting state itself
    if (state == S_DISABLED)
      return;

    switch(_state) {
    case S_ADV:
      overheardAdvs = 0;
      break;
    }

    state = _state;

  }

}
