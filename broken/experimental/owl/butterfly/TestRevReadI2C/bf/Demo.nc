module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface I2CPacketSlave;
}
implementation {
  uint8_t msg[] = "Read";
  
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

  uint8_t foo;

  event char *I2CPacketSlave.write(char *data, uint8_t length) {
    return data;
  }

  event result_t I2CPacketSlave.read(char **data, uint8_t *length) {
    foo++;
    *data = (char *)&foo;
    *length = 1;
    return SUCCESS;
  }

  event result_t I2CPacketSlave.readDone(uint8_t sentLength) {
    msg[0] = 'Y';
    post message();
    return SUCCESS;
  }
}
