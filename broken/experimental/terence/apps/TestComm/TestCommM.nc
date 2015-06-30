includes AM;
module TestCommM {
  provides {
    interface StdControl;
  }
  uses {
    interface SendMsg;
    interface Timer;
    interface ReceiveMsg;
    interface Leds;
  }
}

implementation {
  enum {
    DATA_INTERVAL = 50,
  };

  TOS_Msg msgToSend;


  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    msgToSend.data[0] = 10;

    call Timer.start(TIMER_REPEAT, 200);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  event result_t Timer.fired() {
    uint8_t result;
    call Leds.yellowToggle();
    msgToSend.data[0] = msgToSend.data[0] + 1;
    result = call SendMsg.send(200, DATA_LENGTH, &msgToSend);
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (success == SUCCESS) {
      call Leds.redToggle();
    }
    return SUCCESS;
  }
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    call Leds.greenToggle();
    return m;
  }


}
