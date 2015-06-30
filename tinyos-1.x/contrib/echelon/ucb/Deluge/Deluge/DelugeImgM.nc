module DelugeImgM {
  provides {
    interface BootImg;
    interface StdControl;
  }
  uses {
    interface Leds;
    interface PageEEPROM as Flash;
  }
}
implementation {

#define EXTERNAL_PAGE_SIZE ((uint32_t) 256)
#define EEPROM_PAGE_START ((uint32_t) 1)
#define MIN(x, y) ((x) > (y)) ? (y) : (x)

  uint32_t writeBytes;
  uint8_t isWriting;
  uint32_t writeOffset;
  uint32_t writeLength;
  uint8_t *writePtr;
  uint32_t lastBytesToWrite;

  uint32_t readBytes;
  uint8_t isReading;
  uint32_t readOffset;
  uint32_t readLength;
  uint8_t *readPtr;
  uint32_t lastBytesToRead;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  command result_t BootImg.setImgAttributes(uint16_t pid, uint32_t imgSize) {
    return SUCCESS;
  }

  result_t doRead() {
    void *startReadLocation = readPtr + readBytes;
    uint32_t startByteAddr = readOffset + readBytes;
    uint32_t lowerPageBoundary = startByteAddr / EXTERNAL_PAGE_SIZE;
    uint32_t upperPageBoundary = lowerPageBoundary + ((uint32_t) 1);
    uint32_t bytesToRead = MIN(readLength - readBytes, upperPageBoundary * EXTERNAL_PAGE_SIZE - startByteAddr);
    uint32_t pageOffset = startByteAddr % EXTERNAL_PAGE_SIZE;
    uint8_t result;
    lastBytesToRead = bytesToRead;
    
    result = call Flash.read(EEPROM_PAGE_START + lowerPageBoundary, pageOffset, startReadLocation, bytesToRead);
    if (result == FAIL) {
      TOSH_CLR_RED_LED_PIN();
      lastBytesToRead = 0;
      return FAIL;
    } 
    return SUCCESS;
  }

  command result_t BootImg.read(uint8_t* data, uint32_t offset, uint16_t length) {
    if (isReading == 1) return FAIL;
    isReading = 1;
    readPtr = data;
    readOffset = offset;
    readLength = length;
    readBytes = 0;

    if (doRead() == FAIL) {
      isReading = 0;
      return FAIL;
    }
    return SUCCESS;
  }

  event result_t Flash.readDone(result_t result) {
    if (result == SUCCESS) {
      readBytes += lastBytesToRead; 
    } else {
      isReading = 0;
      return signal BootImg.readDone(FAIL);
    }
    if (readBytes >= readLength) {
      isReading = 0;
      
      signal BootImg.readDone(SUCCESS);
      return SUCCESS;
    } 
    if (doRead() == FAIL) {
      isReading = 0;
      return signal BootImg.readDone(FAIL);
    }
    return SUCCESS;
  }


  result_t doWrite() {
    void *startWriteLocation = writePtr + writeBytes;
    uint32_t startByteAddr = writeOffset + writeBytes;
    uint32_t lowerPageBoundary = startByteAddr / EXTERNAL_PAGE_SIZE;
    uint32_t upperPageBoundary = lowerPageBoundary + ((uint32_t) 1);
    uint32_t bytesToWrite = MIN(writeLength - writeBytes, upperPageBoundary * EXTERNAL_PAGE_SIZE - startByteAddr);
    uint32_t pageOffset = startByteAddr % EXTERNAL_PAGE_SIZE;
    uint8_t result;
    lastBytesToWrite = bytesToWrite;
    
    result = call Flash.write(EEPROM_PAGE_START + lowerPageBoundary, pageOffset, startWriteLocation, bytesToWrite);
    if (result == FAIL) {
      TOSH_CLR_RED_LED_PIN();
      lastBytesToWrite = 0;
      return FAIL;
    } 
    return SUCCESS;
  }

  event result_t Flash.writeDone(result_t result) {
    if (result == SUCCESS) {
      writeBytes += lastBytesToWrite; 
    } else {
      isWriting = 0;
      return signal BootImg.writeDone(FAIL);
    }
    if (writeBytes >= writeLength) {
      isWriting = 0;
      
      signal BootImg.writeDone(SUCCESS);
      return SUCCESS;
    } 
    
    // XXX: BIG HACK! Should not need to sync everytime, but
    //      somehow it is needed to ensure that data is written out.
    return call Flash.syncAll();
  }

  command result_t BootImg.write(uint8_t* data, uint32_t offset, uint16_t length) {
    if (isWriting == 1) return FAIL;
    isWriting = 1;
    writePtr = data;
    writeOffset = offset;
    writeLength = length;
    writeBytes = 0;

    if (doWrite() == FAIL) {
      isWriting = 0;
      return FAIL;
    }
    return SUCCESS;
  }
  command result_t BootImg.sync() {
    return call Flash.syncAll();
  }
  event result_t Flash.syncDone(result_t result) {
    if (isWriting) {
      if (doWrite() == FAIL) {
	isWriting = 0;
	return signal BootImg.writeDone(FAIL);
      }
      return SUCCESS;
    }
    else
      return signal BootImg.syncDone(result);
  }
  event result_t Flash.flushDone(result_t result) {
    return SUCCESS;
  }


  event result_t Flash.eraseDone(result_t result) {
    return SUCCESS;
  }
  event result_t Flash.computeCrcDone(result_t result, uint16_t crc) {
    return SUCCESS;
  }

}
