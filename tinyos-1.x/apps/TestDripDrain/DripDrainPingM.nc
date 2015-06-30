includes DripDrainPing;

module DripDrainPingM {
  provides interface StdControl;
  uses interface Send;
  uses interface SendMsg;
  uses interface Receive;
  uses interface Drip;
  uses interface Leds;
}
implementation {

  TOS_Msg myBuf;
  DripDrainPingMsg dripCache;
  bool myBufBusy;
  
  task void sendReply();

  command result_t StdControl.init() {
    call Leds.redOn();
    call Drip.init();
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }

  command result_t StdControl.stop() { return SUCCESS; }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr buf,
				   void* payload, uint16_t len) {

    DripDrainPingMsg* msg = (DripDrainPingMsg*) payload;
    memcpy(&dripCache, msg, sizeof(DripDrainPingMsg));

    post sendReply();
    return buf;
  }

  task void sendReply() {
    uint16_t length;
    DripDrainPingMsg* msg = call Send.getBuffer(&myBuf, &length);

    if (myBufBusy) {
      return;
    }

    call Leds.yellowToggle();

    myBufBusy = TRUE;
    memcpy(msg, &dripCache, sizeof(DripDrainPingMsg));
    call SendMsg.send(TOS_DEFAULT_ADDR,
		      sizeof(DripDrainPingMsg),
		      &myBuf);
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr buf, void* payload) {
    memcpy(payload, &dripCache, sizeof(DripDrainPingMsg));
    call Drip.rebroadcast(buf, payload, sizeof(DripDrainPingMsg));
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr buf, result_t result) { 
    return SUCCESS;
  }
  event result_t SendMsg.sendDone(TOS_MsgPtr buf, result_t result) { 
    myBufBusy = FALSE;
    return SUCCESS;
  }
}
