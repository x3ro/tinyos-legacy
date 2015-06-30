module Fun {
  provides interface StdControl;
  uses {
    interface Leds;
  }
}
implementation {

  task void poll() {
    if (TOSH_READ_I2C_BUS1_SDA_PIN())
      call Leds.redOn();
    else
      call Leds.redOff();
    if (TOSH_READ_I2C_BUS1_SCL_PIN())
      call Leds.yellowOn();
    else
      call Leds.yellowOff();
    post poll();
  }

  command result_t StdControl.init() {
    call Leds.init();
    TOSH_MAKE_I2C_BUS1_SDA_INPUT();
    TOSH_MAKE_I2C_BUS1_SCL_INPUT();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Leds.greenOn();
    post poll();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

}
