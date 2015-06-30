module PingPongM {
  provides {
    interface StdControl; 
  }

  uses {
    interface Leds;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface Timer as SendTimer;
    interface Timer as BlinkTimer;
    interface XE1205Control;
    interface CSMAControl;

    async command result_t enableInitialBackoff(); 
    async command result_t disableInitialBackoff();
  }
  
}

implementation {

  uint32_t msgs_received;
  uint32_t msgs_sent;
  TOS_Msg sendMsg;
  uint8_t length=28;
  uint32_t bitrate = PINGPONG_DEFAULT_BITRATE;
  bool initiator;

  uint8_t nMsgSmoke=10;

  command result_t StdControl.init() __attribute__ ((noinline)) {
#ifdef PING_INITIATOR
    initiator=TRUE;
#else
    initiator=FALSE;
#endif
    


    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call XE1205Control.TunePreset(2);
    call XE1205Control.SetBitrate(bitrate);
    call XE1205Control.SetRFPower(2);

    call CSMAControl.disableCCA();
    call disableInitialBackoff();

    if (initiator)
      return call SendTimer.start(TIMER_REPEAT, 200);
    else 
      return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SendTimer.stop();
    return SUCCESS;
  }


  bool finished_test(uint8_t i)  __attribute__ ((noinline)) {
    return i + 1;
  }

  void sendPkt(uint8_t len) {
    uint8_t i;

    sendMsg.group = TOS_DEFAULT_AM_GROUP;
    sendMsg.addr = 0xf0f0;
    sendMsg.type = 4;
    sendMsg.length = len;

    for (i = 0; i < sendMsg.length; i++) {
      sendMsg.data[i] = i+1;
    }

    if (call Send.send(&sendMsg) == SUCCESS) 
      msgs_sent++;

#ifdef SMOKETEST
    if (initiator && (msgs_sent == (nMsgSmoke + 1))) {
      finished_test(msgs_sent);
    }
#endif


  }

  event result_t SendTimer.fired() {
    sendPkt(length);
    return SUCCESS;
  }

  event result_t BlinkTimer.fired() {
    call Leds.redOff();
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr p, result_t res) {
    if (res != SUCCESS) {
      call Leds.redOff();
      call SendTimer.stop();
    }
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr m) {

    uint8_t i;

    msgs_received++;
    call Leds.redOn();

    call BlinkTimer.start(TIMER_ONE_SHOT, 50);

    if (initiator == FALSE) {
      sendPkt(m->length);
    }

    // clear message
    for (i = 0; i < sizeof (struct TOS_Msg); i++) 
      ((uint8_t*)m)[i]=0;

    return m;
  }

}

