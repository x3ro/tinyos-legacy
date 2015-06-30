module Fun {
  provides interface StdControl;
  uses {
    interface Leds;
    interface I2CPacketSlave;
  }
}
implementation {
  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Leds.greenOn();
    call I2CPacketSlave.setAddress(0x42);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event char *I2CPacketSlave.write(char *data, uint8_t length) {
    return data;
  }

  char cnt = 5;

  event result_t I2CPacketSlave.read(char **data, uint8_t *length) {
    *data = &cnt;
    *length = 1;
    call Leds.redToggle();
    return SUCCESS;
  }

  event result_t I2CPacketSlave.readDone(uint8_t sentLength) {
    cnt++;
    return SUCCESS;
  }

}
