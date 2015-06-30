includes DripTest;

includes Attrs;

module DripTestM {
  provides {
    interface StdControl;
    interface Attr<uint8_t> as DripTestSender 
      @nucleusAttr("DripTestSender");
    interface AttrSet<uint8_t> as DripTestSenderSet 
      @nucleusAttr("DripTestSender");
    interface Attr<uint16_t> as DripTestSendPeriod 
      @nucleusAttr("DripTestSendPeriod");
    interface AttrSet<uint16_t> as DripTestSendPeriodSet 
      @nucleusAttr("DripTestSendPeriod");
  }

  uses {
    interface Leds;

    interface Timer;

    interface Receive as ReceiveDrip;
    interface Drip;

    interface Send;
    interface SendMsg;

//    interface GlobalTime;
  }
}

implementation {

  DripTestMsg cache;

  bool sender;
  uint16_t sendPeriod = 8000;
  
  uint16_t seqno;
  uint32_t lastSendTime;

  uint32_t lastReceiveTime;
  uint32_t lastPropagationDelay;
  uint16_t receiveSeqno;
  uint16_t receiveCount;
  uint16_t sendCount;

  uint16_t retransmitCount;
  uint16_t lastRetransmitCount;

  command result_t StdControl.init() { 
    call Leds.init();
    call Drip.init();
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { return SUCCESS; }

  command result_t StdControl.stop() { return SUCCESS; }

  command result_t DripTestSender.get(uint8_t* buf) {
    memcpy(buf, &sender, 1);
    signal DripTestSender.getDone(buf);
    return SUCCESS;
  }

  command result_t DripTestSenderSet.set(uint8_t* buf) {
    memcpy(&sender, buf, 1);
    if (sender) {
      call Timer.start(TIMER_ONE_SHOT, sendPeriod);
    } else {
      call Timer.stop();
    }
    signal DripTestSenderSet.setDone(buf);
    return SUCCESS;
  }  

  event result_t Timer.fired() {
    call Timer.start(TIMER_ONE_SHOT, sendPeriod);
//    call GlobalTime.getGlobalTime(&lastSendTime);
    seqno++;
    cache.seqno = seqno;
    cache.time = lastSendTime;
    lastRetransmitCount = retransmitCount;
    retransmitCount = 0;
    call Drip.change();
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveDrip.receive(TOS_MsgPtr msg, 
				       void* payload, 
				       uint16_t payloadLen) {
    
    DripTestMsg *rtMsg = (DripTestMsg*)payload;

/*
    if (call GlobalTime.getGlobalTime(&lastReceiveTime) == FAIL) {
      lastReceiveTime = 0;
    } else {
      if (lastReceiveTime > rtMsg->time) {
	lastPropagationDelay = lastReceiveTime - rtMsg->time;
      }
    }
*/

    memcpy(&cache, rtMsg, sizeof(DripTestMsg));

    receiveCount++;
    if (rtMsg->seqno > receiveSeqno) {
      sendCount += rtMsg->seqno - receiveSeqno;
      receiveSeqno = rtMsg->seqno;
    }

    lastRetransmitCount = retransmitCount;
    retransmitCount = 0;

    call Leds.redToggle();
    return msg;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, 
					 void *payload) {

    DripTestMsg *rtMsg = (DripTestMsg*)payload;

    memcpy(rtMsg, &cache, sizeof(DripTestMsg));
    retransmitCount++;

    call Leds.greenToggle();
    call Drip.rebroadcast(msg, payload, sizeof(DripTestMsg));
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  command result_t DripTestSendPeriod.get(uint16_t* buf) {
    memcpy(buf, &sendPeriod, 2);
    signal DripTestSendPeriod.getDone(buf);
    return SUCCESS;
  }

  command result_t DripTestSendPeriodSet.set(uint16_t* buf) {
    memcpy(&sendPeriod, buf, 2);
    signal DripTestSendPeriodSet.setDone(buf);
    return SUCCESS;
  }
}
