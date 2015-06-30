interface EEPROM{
  
  command result_t write(uint8_t address, uint8_t *data, uint8_t numBytes);
  command result_t read(uint8_t address, uint8_t *data, uint8_t numBytes);
  
  command result_t getUID(uint8_t val[6]);
}
