interface MSP430I2CPacket {
  command result_t readPacket(uint16_t _addr, uint8_t _length, uint8_t* _data);
  command result_t writePacket(uint16_t _addr, uint8_t _length, uint8_t* _data);

  event void readPacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);
  event void writePacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);
}
