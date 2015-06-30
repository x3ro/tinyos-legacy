interface SimpleEEPROM {
  command result_t read(int addr, int size, char* buf);
  command result_t writeByte(int addr, char data);
  command result_t asyncWrite(int addr, int size, char* buf);

  event void asyncWriteDone(char success); 
}
