
/**
 * DelugePageTransferM.nc - Handles the transfer of individual data
 * pages between neighboring nodes.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

module DelugePageTransferM {
  provides {
    interface DelugePageTransfer as PageTransfer;
    interface StdControl;
  }
  uses {
    interface BitVecUtils;
    interface DelugeMetadata as Metadata;
    interface Random;
    interface ReceiveMsg as ReceiveDataMsg;
    interface ReceiveMsg as ReceiveReqMsg;
    interface Timer as ReqTimer;
    interface DelugeImgStableStore as StableStore;
    interface SendMsg as SendDataMsg;
    interface SendMsg as SendReqMsg;
    interface Timer as SendTimer;
    interface Leds;

#ifdef DELUGE_REPORTING_UART
    interface SendMsg as SendDbgMsg;
#endif

#ifndef PLATFORM_PC
    event result_t sendDurationMsg(uint8_t status, uint16_t value);
#endif
  }
}

implementation {

  // message buffers, pointers, and guard flags
  TOS_Msg dataMsgBuf, reqMsgBuf;
  DelugeDataMsg* pDataMsg;
  DelugeReqMsg*  pReqMsg;
  bool isDataMsgSending, isReqMsgSending;

  // send/receive page buffers, and state variables for buffers
  uint8_t  receiveBuf[DELUGE_BYTES_PER_PAGE];     // buffer for receiving page
  uint8_t  sendBuf[DELUGE_BYTES_PER_PAGE];        // buffer for sending page
  uint8_t  pktsToSend[DELUGE_PKT_BITVEC_SIZE];    // bit vec of packets to send
  uint16_t numPktsToReceive;               // number of packets left to receive
  uint16_t numPktsReceived;                // number of packets received since last request
  uint16_t pgNumInReceiveBuf;              // num of the page currently in receive buf
  uint16_t pgNumInSendBuf;                 // num of the page currently in send buf

  // state variables
  uint8_t  pktNumLastSent;                 // counter of packets sending, num of packet last sent
  uint16_t dataSourceAddr;                 // the node data requested from
  uint16_t newDataSourceAddr;              // if fail, that's the number to request next, new node to request data from
  uint8_t  sendState;                      // state of page transmits
  uint8_t  receiveState;                   // state of page receives
  uint8_t  numReqTriesLeft;                // number of remaining requests allowed for a receive attempt
  uint16_t loadingPage = DELUGE_NO_PAGE;

  enum {
    S_DISABLED, // don't send or receive (happen when upgrading meta data or bootting up)
    S_IDLE,     
    S_SENDING,
    S_RECEIVING,
  };

  void     changeReceiveState(uint8_t state);
  void     changeSendState(uint8_t state);
  result_t setupNextPage();

  command result_t StdControl.init() {

    // initialize message buffers, pointers, guard flags
    pDataMsg = (DelugeDataMsg*)dataMsgBuf.data;
    pDataMsg->sourceAddr = TOS_LOCAL_ADDRESS;
    isDataMsgSending = FALSE;
    pReqMsg = (DelugeReqMsg*)reqMsgBuf.data;
    memset(pReqMsg->requestedPkts, 0xff, DELUGE_PKT_BITVEC_SIZE);
    isReqMsgSending = FALSE;

    // initialize state variables
    memset(pktsToSend, 0x0, DELUGE_PKT_BITVEC_SIZE);
    pgNumInSendBuf = DELUGE_NO_PAGE;
    pgNumInReceiveBuf = DELUGE_NO_PAGE;
    changeReceiveState(S_DISABLED);
    changeSendState(S_DISABLED);
    newDataSourceAddr = TOS_BCAST_ADDR;
    numReqTriesLeft = DELUGE_MAX_NUM_REQ_TRIES;

    return SUCCESS;

  }

  command result_t StdControl.start() {
    // get ready to receive next page
    setupNextPage();

    // enable receives and sends
    changeReceiveState(S_IDLE);
    changeSendState(S_IDLE);

    return SUCCESS;
  }
  command result_t StdControl.stop() {
    // disable receives and sends
    changeReceiveState(S_DISABLED);
    changeSendState(S_DISABLED);
    return SUCCESS;
  }

  command result_t PageTransfer.setNewSource(uint16_t sourceAddr) {

    if (pgNumInReceiveBuf == DELUGE_NO_PAGE 
	&& !setupNextPage())
      return FAIL;

    if (receiveState == S_IDLE) {
      // update address of source node
      dataSourceAddr = sourceAddr;
      numReqTriesLeft = DELUGE_MAX_NUM_REQ_TRIES;

      // currently idle, so request data from source
      changeReceiveState(S_RECEIVING);

      // randomize request to prevent collision
      call ReqTimer.start(TIMER_ONE_SHOT, DELUGE_MIN_DELAY + 
			  call Random.rand() % DELUGE_MAX_REQ_DELAY);
    }
    else if (dataSourceAddr != sourceAddr) {
      // update address of source node for new requests
//      newDataSourceAddr = sourceAddr;
    }

    return SUCCESS;

  }

  void sendDataMsg() {
    uint16_t nextPkt;

    if (sendState == S_IDLE)
      return;

    if (!isDataMsgSending) {
      if (!call BitVecUtils.indexOf(&nextPkt, pktNumLastSent, pktsToSend, 
				    DELUGE_PKTS_PER_PAGE)
	  && !call BitVecUtils.indexOf(&nextPkt, 0, pktsToSend, 
				       DELUGE_PKTS_PER_PAGE)) {
	// no more packets to send
	dbg(DBG_USR1, "DELUGE: SEND_DONE\n");
	changeSendState(S_IDLE);
	return;
      }
      
      isDataMsgSending = TRUE;
      pDataMsg->pgNum = pgNumInSendBuf;
      pDataMsg->pktNum = (uint8_t)nextPkt;
      memcpy(pDataMsg->data, sendBuf + (pDataMsg->pktNum*DELUGE_PKT_PAYLOAD_SIZE),
	     DELUGE_PKT_PAYLOAD_SIZE);
      if (call SendDataMsg.send(TOS_BCAST_ADDR, sizeof(DelugeDataMsg), &dataMsgBuf)) {
	// data packet send success, update bitvec
	BITVEC_CLEAR(pktsToSend, pDataMsg->pktNum);
	pktNumLastSent = pDataMsg->pktNum;
      }
      else {
	// data packet send failed, wait a bit and try again
	dbg(DBG_USR1, "packet send fail\n");
	isDataMsgSending = FALSE;
	call SendTimer.start(TIMER_ONE_SHOT, FAILED_SEND_DELAY);
      }
    }
  }

  event result_t ReqTimer.fired() {

    if (isReqMsgSending
	|| (dataSourceAddr == TOS_BCAST_ADDR))
      return SUCCESS;
    
    if (receiveState == S_IDLE)
      changeReceiveState(S_RECEIVING);
    
    if (2*numPktsReceived >= numPktsToReceive) {
      // got a good ratio of packets, reset counter
      numReqTriesLeft = DELUGE_MAX_NUM_REQ_TRIES_GOOD;
    }
    else if (numReqTriesLeft == 0
	     || numPktsReceived > 0) {
      // tried too many times on dataSourceAddr, give up
      if (newDataSourceAddr != TOS_BCAST_ADDR) {
	// switch to new source
	dataSourceAddr = newDataSourceAddr;
	newDataSourceAddr = TOS_BCAST_ADDR;
	numReqTriesLeft = DELUGE_MAX_NUM_REQ_TRIES;
	// try another node
	dbg(DBG_USR2, "DELUGE: @%lld RECEIVE_SWITCH(source=%d)\n", 
	    tos_state.tos_time, dataSourceAddr);      }
      else {
	// no other node to try, give up
	changeReceiveState(S_IDLE);
	return SUCCESS;
      }
    }

    // reset packet counter
    numPktsReceived = 0;
    call BitVecUtils.countOnes(&numPktsToReceive, pReqMsg->requestedPkts,
			       DELUGE_PKTS_PER_PAGE);

    isReqMsgSending = TRUE;
    pReqMsg->dest = dataSourceAddr;
    {
      uint16_t dest = (dataSourceAddr == TOS_UART_ADDR) 
	? TOS_UART_ADDR : TOS_BCAST_ADDR;
      if (call SendReqMsg.send(dest, sizeof(DelugeReqMsg), &reqMsgBuf)
	  == SUCCESS) {
	numReqTriesLeft--;
      }
      else {
	// send failed, wait a bit and try again
	isReqMsgSending = FALSE;
	call ReqTimer.start(TIMER_ONE_SHOT, FAILED_SEND_DELAY);
      }
    }
    return SUCCESS;
  }

  event result_t SendTimer.fired() {
    // send data message
    sendDataMsg();
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveReqMsg.receive(TOS_MsgPtr pMsg) {

    DelugeReqMsg *rxReqMsg = (DelugeReqMsg*)pMsg->data;
    int i;

    if (loadingPage != DELUGE_NO_PAGE)
      return pMsg;

    if (rxReqMsg->vNum == call Metadata.getVNum())
      signal PageTransfer.overheardData(rxReqMsg->pgNum);

    if (rxReqMsg->dest != TOS_LOCAL_ADDRESS) {
      // possibly do some request message suppression here
      if (receiveState == S_RECEIVING
	  && rxReqMsg->vNum == call Metadata.getVNum()
	  && rxReqMsg->pgNum == pgNumInReceiveBuf) {
	call ReqTimer.stop();
	call ReqTimer.start(TIMER_ONE_SHOT, 
			    DELUGE_NACK_TIMEOUT + call Random.rand() % DELUGE_NACK_TIMEOUT);	
      }
      return pMsg;
    }


    // data has been requested from this node
    dbg(DBG_USR1, "DELUGE: Received REQ_MSG(vNum=%d,pgNum=%d)\n",
	rxReqMsg->vNum, rxReqMsg->pgNum);
    if (rxReqMsg->pgNum >= call Metadata.getNumPgsComplete()) {
      // don't have this page, ignore request
      return pMsg;
    }

    if ((rxReqMsg->pgNum == pgNumInSendBuf) 
	|| (sendState == S_IDLE)) {
      // take union of packet bit vectors
      for ( i = 0; i < DELUGE_PKT_BITVEC_SIZE; i++ )
	pktsToSend[i] |= rxReqMsg->requestedPkts[i];
//      if (sendState != S_SENDING)
//	memset(pktsToSend, 0xff, DELUGE_PKT_BITVEC_SIZE);
#ifdef PLATFORM_PC
      {
	char buf[100];
	call BitVecUtils.printBitVec(buf, pktsToSend, DELUGE_PKTS_PER_PAGE);
	dbg(DBG_USR1, "DELUGE: PKTS_TO_SEND(%s)\n", buf);
      }
#endif
    }

    if (sendState == S_IDLE) {
      // not currently sending, so start sending data
      pktNumLastSent = 0;
      if (pgNumInSendBuf != rxReqMsg->pgNum) {
	// have to grab page from flash
	dbg(DBG_USR1, "DELUGE: SEND_BUF(pgNum=%d)\n", rxReqMsg->pgNum);
	if (call StableStore.getImgData((uint32_t)rxReqMsg->pgNum*(uint32_t)DELUGE_BYTES_PER_PAGE, 
					sendBuf, DELUGE_BYTES_PER_PAGE)
	    == FAIL) {
	  dbg(DBG_USR1, "HELP!\n");
	}
	else {
	  changeSendState(S_SENDING);
	  loadingPage = rxReqMsg->pgNum;
	}
      }
      else {
	// already have in send buf, start sending right away
	changeSendState(S_SENDING);
	sendDataMsg();
      }
    }

    return pMsg;

  }

  task void writeImgData() {
    if (!call StableStore.setImgAttributes(0xBEEF, call Metadata.getImgSize())
	|| !call StableStore.writeImgData((uint32_t)pgNumInReceiveBuf*(uint32_t)DELUGE_BYTES_PER_PAGE, 
					  receiveBuf, DELUGE_BYTES_PER_PAGE)) {
      // write failed, try again
      post writeImgData();
    }
  }

  event TOS_MsgPtr ReceiveDataMsg.receive(TOS_MsgPtr pMsg) {

    DelugeDataMsg *rxDataMsg = (DelugeDataMsg*)pMsg->data;
    uint16_t tmp;

//    dbg(DBG_USR1, "DELUGE: Received DATA_MSG(source=%d,pgNum=%d,pktNum=%d)\n",
//	rxDataMsg->sourceAddr, rxDataMsg->pgNum, rxDataMsg->pktNum);

    if (rxDataMsg->vNum == call Metadata.getVNum()) {
      signal PageTransfer.overheardData(rxDataMsg->pgNum);
      if (receiveState == S_RECEIVING
	  && rxDataMsg->sourceAddr == dataSourceAddr
	  && newDataSourceAddr != TOS_BCAST_ADDR) {
	dataSourceAddr = newDataSourceAddr;
	newDataSourceAddr = TOS_BCAST_ADDR;
      }
    }

    if (rxDataMsg->pgNum == pgNumInReceiveBuf) {
      switch(receiveState) {
      case S_IDLE:
	if (rxDataMsg->sourceAddr != dataSourceAddr) {
	  dataSourceAddr = rxDataMsg->sourceAddr;
	  numReqTriesLeft = DELUGE_MAX_NUM_REQ_TRIES;
	  changeReceiveState(S_RECEIVING);
	  numPktsReceived = 0;
	  call BitVecUtils.countOnes(&numPktsToReceive, pReqMsg->requestedPkts,
				     DELUGE_PKTS_PER_PAGE);
	  call ReqTimer.start(TIMER_ONE_SHOT, 
			      DELUGE_NACK_TIMEOUT + call Random.rand() % DELUGE_NACK_TIMEOUT);
	}
	break;
      case S_RECEIVING:
	// update NACK timeout since nodes are still sending
	call ReqTimer.stop();
	call ReqTimer.start(TIMER_ONE_SHOT, 
			    DELUGE_NACK_TIMEOUT + call Random.rand() % DELUGE_NACK_TIMEOUT);	
	break;
      }
    }

    if (rxDataMsg->vNum == call Metadata.getVNum()
	&& rxDataMsg->pgNum == pgNumInReceiveBuf
	&& BITVEC_GET(pReqMsg->requestedPkts, rxDataMsg->pktNum)) {
      // got a packet we need
      // call Leds.redToggle();
      BITVEC_CLEAR(pReqMsg->requestedPkts, rxDataMsg->pktNum);
      if (rxDataMsg->sourceAddr == dataSourceAddr)
	numPktsReceived++;
      dbg(DBG_USR1, "DELUGE: SAVING(pgNum=%d,pktNum=%d)\n", 
	  rxDataMsg->pgNum,rxDataMsg->pktNum);
      memcpy(receiveBuf + (rxDataMsg->pktNum*DELUGE_PKT_PAYLOAD_SIZE), 
	     rxDataMsg->data, DELUGE_PKT_PAYLOAD_SIZE);

      if (!call BitVecUtils.indexOf(&tmp, 0, pReqMsg->requestedPkts, DELUGE_PKTS_PER_PAGE)) {
	// received all packets of this page
	call ReqTimer.stop();
	post writeImgData();
      }
    }

    return pMsg;

  }

  event result_t StableStore.getImgDataDone(result_t result) {
    if (result == SUCCESS) {
      // success, begin sending
      pgNumInSendBuf = loadingPage;
      pDataMsg->vNum = call Metadata.getVNum();
      loadingPage = DELUGE_NO_PAGE;
      sendDataMsg();
    }
    else {
      // fail, something bad happened forget sending
      changeSendState(S_IDLE);
      pgNumInSendBuf = DELUGE_NO_PAGE;
      loadingPage = DELUGE_NO_PAGE;
    }
    return SUCCESS;
  }

  event result_t StableStore.writeImgDataDone(result_t result) {

    if (result) {
      // success, get ready for next page
      dbg(DBG_USR1, "DELUGE: FLUSH(pgNum=%d)\n", pgNumInReceiveBuf);
      dbg(DBG_USR2, "DELUGE: @%lld FLUSH(pgNum=%d)\n", 
	  tos_state.tos_time, pgNumInReceiveBuf);

      memset(receiveBuf, 0xee, DELUGE_BYTES_PER_PAGE);

      // update metadata
      call Metadata.pgFlushed(pgNumInReceiveBuf);
      
      // get ready to receive next page
      setupNextPage();
      
      // update state
      signal PageTransfer.receivedNewData();
      changeReceiveState(S_IDLE);
    }
    else {
      // fail, something bad happened, try again
      post writeImgData();
    }

    return SUCCESS;

  }

  event result_t SendReqMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {

    if (pMsg == &reqMsgBuf) {
#ifdef PLATFORM_PC
      {
	char buf[100];
	call BitVecUtils.printBitVec(buf, pReqMsg->requestedPkts, DELUGE_PKTS_PER_PAGE);
	dbg(DBG_USR1, "DELUGE: Sent REQ_MSG(vNum=%d,pgNum=%d,%s)\n",
	    pReqMsg->vNum, pReqMsg->pgNum, buf);
      }
#endif      
      isReqMsgSending = FALSE;
      // start timeout timer in case request is not serviced
      call ReqTimer.start(TIMER_ONE_SHOT, 
			  DELUGE_NACK_TIMEOUT + call Random.rand() % DELUGE_NACK_TIMEOUT);

      if (pReqMsg->pgNum != pgNumInReceiveBuf) {
	// finished receiving page while sending, update
	pReqMsg->vNum = call Metadata.getVNum();
	pReqMsg->pgNum = pgNumInReceiveBuf;
	memset(pReqMsg->requestedPkts, 0xff, DELUGE_PKT_BITVEC_SIZE);
      }
    }

    return SUCCESS;

  }

  event result_t SendDataMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {

    if (pMsg == &dataMsgBuf) {
      dbg(DBG_USR1, "DELUGE: Sent DATA_MSG(vNum=%d,pgNum=%d,pktNum=%d)\n",
	  pDataMsg->vNum, pDataMsg->pgNum, pDataMsg->pktNum);
      isDataMsgSending = FALSE;
      sendDataMsg();
    }

    return SUCCESS;

  }

  void changeSendState(uint8_t state) {

    if (sendState != state && sendState != S_DISABLED
	&& receiveState == S_IDLE) {
      switch(state) {
      case S_IDLE: signal PageTransfer.transferDone(FALSE); break;
      case S_SENDING: signal PageTransfer.transferBegin(); break;
      }
    }

#ifdef PLATFORM_PC
    if (sendState != state && sendState != S_DISABLED) {
      if (state == S_IDLE)
	dbg(DBG_USR2, "DELUGE: @%lld SENDING_END\n", tos_state.tos_time);
      else if (state == S_SENDING)
	dbg(DBG_USR2, "DELUGE: @%lld SENDING_BEGIN\n", tos_state.tos_time);
    }
#endif

    sendState = state;
    
  }

  void changeReceiveState(uint8_t state) {

    if (receiveState != state && receiveState != S_DISABLED
	&& sendState == S_IDLE) {
      switch(state) {
      case S_IDLE: signal PageTransfer.transferDone(TRUE); break;
      case S_RECEIVING: signal PageTransfer.transferBegin(); break;
      }
    }

    if (state == S_RECEIVING) {
      numReqTriesLeft = DELUGE_MAX_NUM_REQ_TRIES;
      numPktsReceived = 0;
    }

#ifdef PLATFORM_PC
    if (receiveState != state && receiveState != S_DISABLED) {
      if (state == S_IDLE)
	dbg(DBG_USR2, "DELUGE: @%lld RECEIVE_END\n", tos_state.tos_time);
      else if (state == S_RECEIVING)
	dbg(DBG_USR2, "DELUGE: @%lld RECEIVE_BEGIN(source=%d)\n", 
	    tos_state.tos_time, dataSourceAddr);
    }
#endif

    receiveState = state;

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
  
  result_t setupNextPage() {

    uint16_t pageToGet;
    
    if (call Metadata.getNextIncompletePage(&pageToGet) == SUCCESS) {
      pgNumInReceiveBuf = pageToGet;
      dataSourceAddr = newDataSourceAddr = TOS_BCAST_ADDR;
      dbg(DBG_USR1, "DELUGE: RECEIVE_BUF(pgNum=%d)\n", pgNumInReceiveBuf);
      if (!isReqMsgSending) {
	pReqMsg->vNum = call Metadata.getVNum();
	pReqMsg->pgNum = pgNumInReceiveBuf;
	memset(pReqMsg->requestedPkts, 0xff, DELUGE_PKT_BITVEC_SIZE);
      }
#ifdef DELUGE_REPORTING_UART
      {
	DelugeDurationMsg *ddm;
	ddm = (DelugeDurationMsg *)durationMsg.data;
	ddm->sourceAddr = TOS_LOCAL_ADDRESS;
	ddm->status = DELUGE_PG_DONE;
	ddm->value = pgNumInReceiveBuf;
	if (call SendDbgMsg.send(TOS_UART_ADDR, sizeof(DelugeDurationMsg), &durationMsg)
	    == FAIL)
	  post retryDbg();
      }
#endif
      return SUCCESS;
    }

    // no pages to get
    dbg(DBG_USR1, "DELUGE: RECEIVE_BUF(pgNum=%d)\n", pgNumInReceiveBuf);
    pgNumInReceiveBuf = DELUGE_NO_PAGE;
#ifdef DELUGE_REPORTING_UART
    {
      DelugeDurationMsg *ddm;
      ddm = (DelugeDurationMsg *)durationMsg.data;
      ddm->sourceAddr = TOS_LOCAL_ADDRESS;
      ddm->status = DELUGE_DL_END;
      ddm->value = call Metadata.getVNum();
      if (call SendDbgMsg.send(TOS_UART_ADDR, sizeof(DelugeDurationMsg), &durationMsg)
	  == FAIL)
	post retryDbg();
    }
#endif
    return FAIL;
  }

  event result_t Metadata.applyPageDiffDone(result_t result) { return SUCCESS; }
  event result_t Metadata.ready(result_t result) { return SUCCESS; }

}
