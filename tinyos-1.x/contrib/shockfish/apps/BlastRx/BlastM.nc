module BlastRX {
  provides {
    interface StdControl; 
  }

  uses {
    interface Leds;
    interface ReceiveMsg as Receive;
  }

}

implementation {

  uint32_t msgs_received;

  command result_t StdControl.init() {
    msgs_received = 0;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr m) {
    call Leds.redToggle();
    return m;
  }




