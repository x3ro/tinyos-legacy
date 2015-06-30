module DelugeControlM {
  provides interface StdControl;
  uses {
    interface NetProg;

    interface Receive;
    interface Drip;
    interface Naming;

    interface Timer;
    interface Random;

    interface InternalFlash as IFlash;
  }
}
implementation {

  uint8_t runningImgNum;
  uint8_t currentSeqno;
  uint8_t simpleReboot = FALSE;

  NamingMsg namingMsgCache;
  NetProgCmdMsg cmdMsgCache;

  command result_t StdControl.init() {
#ifndef PLATFORM_PC
    call IFlash.read((uint8_t*)IFLASH_CMDSEQNO_ADDR, &currentSeqno, sizeof(currentSeqno));
#endif

    if (currentSeqno == 0xff || currentSeqno == 0)
      currentSeqno = 1;
    
    (void) unique("Drip");
    call Drip.init();
    call Drip.setSeqno(currentSeqno);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    runningImgNum = call NetProg.getExecutingImgNum();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    uint8_t seqno;

    atomic {
      seqno = currentSeqno;
    }

#ifndef PLATFORM_PC
    call IFlash.write((uint8_t*)IFLASH_CMDSEQNO_ADDR, &seqno, sizeof(seqno));
#endif

    if (simpleReboot) {
      call NetProg.reboot();  // SHOULD NOT RETURN!
    } else {
      call NetProg.programImgAndReboot(runningImgNum); // SHOULD NOT RETURN!
    }
    
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, 
				   void* payload, uint16_t payloadLen) {

    NamingMsg *namingMsg = (NamingMsg *) payload;
    NetProgCmdMsg *cmdMsg = 
      (NetProgCmdMsg *) call Naming.getBuffer(namingMsg);
    DripMsg *dripMsg = (DripMsg*) msg->data;

    memcpy(&namingMsgCache, namingMsg, sizeof(NamingMsg));
    memcpy(&cmdMsgCache, cmdMsg, sizeof(NetProgCmdMsg));

    currentSeqno = dripMsg->metadata.seqno;
    
    if (!call Naming.isEndpoint(namingMsg))
      return msg;

    if (cmdMsg->rebootNode == TRUE) {
      simpleReboot = TRUE;
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT, 
		       (cmdMsg->rebootDelay == 0 ? DELUGE_REBOOT_DELAY : 
			cmdMsg->rebootDelay));
    
    } else if (cmdMsg->runningImgNumChanged == TRUE) {
      simpleReboot = FALSE;
      runningImgNum = cmdMsg->runningImgNum;
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT, 
		       (cmdMsg->rebootDelay == 0 ? DELUGE_REBOOT_DELAY : 
			cmdMsg->rebootDelay));
    }

    return msg;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *pData) {

    if (call Naming.isIntermediary(&namingMsgCache)) {

      NetProgCmdMsg *cmdMsg;
      
      NamingMsg *namingMsg = (NamingMsg*) pData;
      memcpy(namingMsg, &namingMsgCache, sizeof(namingMsgCache));

      call Naming.prepareRebroadcast(msg, namingMsg);

      cmdMsg = (NetProgCmdMsg *) call Naming.getBuffer(namingMsg);
      memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));

      call Drip.rebroadcast(msg, pData, sizeof(namingMsgCache) + 
			    sizeof(cmdMsgCache));
      return SUCCESS;
    }

    return FAIL;
  }

  
}

