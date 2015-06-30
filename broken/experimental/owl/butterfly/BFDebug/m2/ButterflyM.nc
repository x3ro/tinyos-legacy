module ButterflyM {
  provides {
    interface StdControl;
    interface BFDebug;
  }
  uses {
    interface I2CPacket;
    interface I2CPacketSlave;
  }
}
implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call I2CPacketSlave.setAddress(0x42);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t BFDebug.displayInt(int16_t x) {
    static int16_t data;

    data = x;
    return call I2CPacket.writePacket((char *)&data, sizeof data, 0);
  }

  event result_t I2CPacket.writePacketDone(char *data, uint8_t length,
					   result_t result) {
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char *data, uint8_t length,
					  result_t result) {
    return SUCCESS;
  }

  event char *I2CPacketSlave.write(char *data, uint8_t length) {
    signal BFDebug.joystick(data[0]);
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
