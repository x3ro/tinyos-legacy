includes Drain;
includes DrainTest;
includes Attrs;

module DrainTestM {
  provides interface StdControl;
  provides interface Attr<uint8_t> as DrainTestSender
    @nucleusAttr("DrainTestSender");
  provides interface AttrSet<uint8_t> as DrainTestSenderSet
    @nucleusAttr("DrainTestSender");
  provides interface Attr<uint16_t> as DrainTestSendPeriod 
    @nucleusAttr("DrainTestSendPeriod");
  provides interface AttrSet<uint16_t> as DrainTestSendPeriodSet 
    @nucleusAttr("DrainTestSendPeriod");

  uses {
    interface Leds;

    interface Send;
    interface SendMsg;

    interface Timer;
    interface Random;

//    interface GlobalTime;
  }
}

implementation {
  
  TOS_Msg msgBuf;
  bool msgBufBusy;

  uint16_t seqno;
  uint32_t lastSendTime;

  bool sender;
  uint16_t sendPeriod = 32768U;

  command result_t StdControl.init() { return SUCCESS; }
  
  command result_t StdControl.start() { 
#ifdef PLATFORM_PC
    sender = TRUE;
    call Timer.start(TIMER_ONE_SHOT, sendPeriod);    
#endif
    return SUCCESS; 
  }
  
  
  command result_t StdControl.stop() { return SUCCESS; }

  command result_t DrainTestSender.get(uint8_t* buf) {
    memcpy(buf, &sender, 1);
    signal DrainTestSender.getDone(buf);
    return SUCCESS;
  }

  command result_t DrainTestSenderSet.set(uint8_t* buf) {
    memcpy(&sender, buf, 1);
    if (sender) {
      call Timer.start(TIMER_ONE_SHOT, sendPeriod);
    } else {
      call Timer.stop();
    }
    signal DrainTestSenderSet.setDone(buf);
    return SUCCESS;
  }

  event result_t Timer.fired() {
    uint16_t length;
    DrainTestMsg* testMHMsg = 
      (DrainTestMsg*) call Send.getBuffer(&msgBuf, &length);
    
    call Timer.start(TIMER_ONE_SHOT, sendPeriod);

    if (msgBufBusy) {
      return SUCCESS;
    } else {
      msgBufBusy = TRUE;
    }

    call Leds.yellowOn();

    testMHMsg->seqno = seqno;
//    call GlobalTime.getGlobalTime(&lastSendTime);
    testMHMsg->time = lastSendTime;

    if (call SendMsg.send(TOS_DEFAULT_ADDR, sizeof(DrainTestMsg), &msgBuf)
	== FAIL) {
      msgBufBusy = FALSE;
      dbg(DBG_USR1, "DrainTestM: network busy!\n");
    }
    
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {

    dbg(DBG_USR1, "sendDone(msg=0x%x,success=%d)\n",
	msg, success);

//    if (msg == &msgBuf) {
    if (msgBufBusy == TRUE) {
      msgBufBusy = FALSE;
    } else {
//      call Leds.greenOn();
    }

    call Leds.yellowOff();

    seqno++;

    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  command result_t DrainTestSendPeriod.get(uint16_t* buf) {
    memcpy(buf, &sendPeriod, 2);
    signal DrainTestSendPeriod.getDone(buf);
    return SUCCESS;
  }

  command result_t DrainTestSendPeriodSet.set(uint16_t* buf) {
    memcpy(&sendPeriod, buf, 2);
    signal DrainTestSendPeriodSet.setDone(buf);
    return SUCCESS;
  }
}
