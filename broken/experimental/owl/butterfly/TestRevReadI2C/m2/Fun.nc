module Fun {
  provides interface StdControl;
  uses {
    interface Leds;
    interface IntOutput;
    interface I2CPacket;
    interface Timer;
  }
}
implementation {
  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Leds.greenOn();
    call Timer.start(TIMER_REPEAT, 2000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    static char buf;
    if (!call I2CPacket.readPacket(&buf, 1, 0))
      ;//call Leds.yellowToggle();
    return SUCCESS;
  }

  event result_t I2CPacket.writePacketDone(char *x, uint8_t l, result_t result) {
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char *data, uint8_t l, result_t result) {
    call IntOutput.output(*(uint8_t *)data);
    return SUCCESS; 
  }

  event result_t IntOutput.outputComplete(result_t success) {
    return SUCCESS;
  }
}
