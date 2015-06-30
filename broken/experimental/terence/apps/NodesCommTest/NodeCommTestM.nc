module NodeCommTestM {
  provides {
    interface StdControl;
  } 
  uses {
    interface SendMsg;
    interface ReceiveMsg;
    interface Timer;
    interface Leds;
  }


}
implementation {
  uint8_t counter;
  TOS_Msg myMsg;
  uint8_t sending;
  command result_t StdControl.init() {

    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Leds.init();
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  event result_t Timer.fired() {    
    counter ++;
    if (counter / 10 != TOS_LOCAL_ADDRESS) 
      { return SUCCESS; }
    if (sending == 1) return SUCCESS;
    sending = call SendMsg.send(TOS_BCAST_ADDR, 1, &myMsg);

    return SUCCESS;
  }
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowToggle();
    sending = 0;
    return SUCCESS;
  }
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    call Leds.redToggle();
    call Leds.greenOff();
    call Leds.yellowOff();
    return m;
  }



}
