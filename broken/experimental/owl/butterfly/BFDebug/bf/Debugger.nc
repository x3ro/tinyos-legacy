module Debugger {
  provides interface StdControl;
  uses {
    interface LCD;
    interface Joystick;
    interface I2CPacket;
    interface I2CPacketSlave;
  }
}
implementation {

  uint8_t msg[] = "Debug";
  
  void i2cSend(uint8_t n) {
    static uint16_t  imsg;

    imsg = n;
    call I2CPacket.writePacket((char *)&imsg, sizeof imsg, 0);
  }

  event result_t I2CPacket.writePacketDone(char *x, uint8_t l, result_t result) {
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char *x, uint8_t l, result_t result) {
    return SUCCESS;
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call LCD.display(msg);
    call I2CPacketSlave.setAddress(0x41);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Joystick.fire() {
    i2cSend(4);
    return SUCCESS;
  }

  event result_t Joystick.move(uint8_t direction) {
    i2cSend(direction);
    return SUCCESS;
  }

  event char *I2CPacketSlave.write(char *data, uint8_t length) {
    uint16_t val = *(uint16_t *)data;

    sprintf(msg, "%d", val);
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

