enum {
  I2CSLAVE_LAST = 0x100,

  // Or this with your address to respond to general calls
  I2CSLAVE_GENERAL_CALL = 0x80,

  // User overrideable maximum I2C slave write packet size
#ifdef TOSH_I2CSLAVE_PACKETSIZE
  I2CSLAVE_PACKETSIZE = TOSH_I2CSLAVE_PACKETSIZE
#else
  I2CSLAVE_PACKETSIZE = 10
#endif
};

enum {
  I2C_NOACK_FLAG = 0x08,     // send ack after byte recv (except last byte)
  I2C_ACK_END_FLAG = 0x04,   // send ack after last byte recv'd
  I2C_ADDR_8BITS_FLAG = 0x80, // the address is a full 8-bits with no terminating r/w flag
};
