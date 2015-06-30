module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface I2CPacketSlave;
}
implementation {
  uint8_t msg[] = "Rev";
  
  task void message() {
    call LCD.display(msg);
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    post message();
    call I2CPacketSlave.setAddress(0x41);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event char *I2CPacketSlave.write(char *data, uint8_t length) {
    uint8_t foo = data[0];
    msg[0] = foo / 10 + '0';
    msg[1] = foo % 10 + '0';
    call LCD.display(msg);
    return data;
  }

  event result_t I2CPacketSlave.read(char **data, uint8_t *length) {
    *length = 0;
    return SUCCESS;
  }

  event result_t I2CPacketSlave.readDone(uint8_t sentLength) {
    return SUCCESS;
  }
}

