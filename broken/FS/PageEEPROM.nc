includes PageEEPROM;
interface PageEEPROM {
  command result_t write(eeprompage_t page, eeprompageoffset_t offset,
			 void *data, eeprompageoffset_t n);
  event result_t writeDone(result_t result);

  command result_t erase(eeprompage_t page, uint8_t eraseKind);
  event result_t eraseDone(result_t result);

  command result_t sync(eeprompage_t page);
  event result_t syncDone(result_t result);

  command result_t flush(eeprompage_t page);
  event result_t flushDone(result_t result);

  command result_t read(eeprompage_t page, eeprompageoffset_t offset,
			void *data, eeprompageoffset_t n);
  event result_t readDone(result_t result);

  command result_t computeCrc(eeprompage_t page, eeprompageoffset_t offset,
			      eeprompageoffset_t n);
  event result_t computeCrcDone(result_t result, uint16_t crc);
}
