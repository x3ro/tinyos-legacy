module Fun {
  provides interface StdControl;
  uses {
    interface Leds;
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

  uint8_t cnt;

  event result_t Timer.fired() {
    cnt++;
    call Leds.greenToggle();
    if (!call I2CPacket.writePacket(&cnt, 1, 0))
      ;//call Leds.yellowToggle();
    return SUCCESS;
  }

  event result_t I2CPacket.writePacketDone(char *x, uint8_t l, result_t result) {
    if (result)
      call Leds.redToggle();
    else
      call Leds.yellowOn();
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char *data, uint8_t l, result_t result) { return SUCCESS; }

}
