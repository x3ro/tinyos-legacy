
/**
 * XnpImgM.nc - Reads and writes srec data in Xnp compatible format.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

module XnpImgM {
  provides {
    interface BootImg;
    interface StdControl;
  }
  uses {
    interface PageEEPROM as Flash;
  }
}

implementation {
  
  uint8_t       tmpRWbuf[FLASH_BYTES_PER_XNP_LINE];
  xnpSrecLine_t *xnpLine;
  uint8_t* rwBuf;
  uint16_t pid;
  uint32_t rwDataOffset;
  uint32_t imgSize;
  uint16_t rwDataLen, rwFlashLen;  
  uint16_t rwNumBytesToCopy;
  bool     isBusy, writingLastLine;

  command result_t StdControl.init() {
    isBusy = FALSE;
    writingLastLine = FALSE;
    xnpLine = (xnpSrecLine_t*)tmpRWbuf;
    return SUCCESS;
  }
  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  command result_t BootImg.setImgAttributes(uint16_t _pid, uint32_t _size) {

    if (isBusy)
      return FAIL;

    pid = _pid;
    imgSize = _size;

    return SUCCESS;

  }

  command result_t BootImg.read(uint8_t* data, uint32_t offset, uint16_t length) {

    uint16_t flashPage, flashOffset;
    bool isAligned;

    if (isBusy)
      return FAIL;
    
    isBusy = TRUE;
    
    rwBuf = data;
    rwDataOffset = offset;
    rwNumBytesToCopy = length;
    
    if (rwDataOffset % XNP_BYTES_PER_LINE) {
      // offset not aligned, read partial line
      isAligned = FALSE;
      rwDataLen = XNP_BYTES_PER_LINE-rwDataOffset%XNP_BYTES_PER_LINE;
      if (rwNumBytesToCopy < rwDataLen)
	rwDataLen = length;
      rwFlashLen = rwDataLen;
    }
    else {
      // offset aligned, read whole line
      isAligned = TRUE;
      rwDataLen = (rwNumBytesToCopy > XNP_BYTES_PER_LINE) ? XNP_BYTES_PER_LINE : rwNumBytesToCopy;
      rwFlashLen = (rwDataLen == XNP_BYTES_PER_LINE) ? sizeof(xnpSrecLine_t) : rwDataLen + 8;
    }

    flashPage = OFFSET_TO_FLASH_PAGE(rwDataOffset);
    flashOffset = OFFSET_TO_FLASH_OFFSET(rwDataOffset);
    if (isAligned)
      flashOffset -= XNP_HEADER_SIZE;
    
    if (call Flash.read(flashPage, flashOffset, tmpRWbuf, rwFlashLen) == FAIL) {
      isBusy = FALSE;
      return FAIL;
    }

    return SUCCESS;

  }
  
  event result_t Flash.readDone(result_t result) {

    uint16_t flashPage, flashOffset;

    if (result == FAIL) {
      isBusy = FALSE;
      return signal BootImg.readDone(result);
    }
    
    memcpy(rwBuf, tmpRWbuf, rwDataLen);
    rwBuf += rwDataLen;
    rwDataOffset += rwDataLen;
    rwNumBytesToCopy -= rwDataLen;
    if (rwNumBytesToCopy == 0) {
      // all done
      isBusy = FALSE;
      return signal BootImg.readDone(result);
    }

    // keep reading more data
    // offset aligned
    rwDataLen = (rwNumBytesToCopy > XNP_BYTES_PER_LINE) ? XNP_BYTES_PER_LINE : rwNumBytesToCopy;
    rwFlashLen = (rwDataLen == XNP_BYTES_PER_LINE) ? sizeof(xnpSrecLine_t) : rwDataLen + 8;    

    flashPage = OFFSET_TO_FLASH_PAGE(rwDataOffset);
    flashOffset = OFFSET_TO_FLASH_OFFSET(rwDataOffset)-XNP_HEADER_SIZE;

    if (call Flash.read(flashPage, flashOffset, &tmpRWbuf, rwFlashLen) 
	== FAIL) {
      isBusy = FALSE;
      return signal BootImg.readDone(FAIL);
    }

    return SUCCESS;

  }
  
  command result_t BootImg.write(uint8_t* data, uint32_t offset, uint16_t length) {

    bool isAligned;
    uint16_t flashPage, flashOffset;

    if (isBusy)
      return FAIL;
    
    isBusy = TRUE;
    
    rwBuf = data;
    rwDataOffset = offset;
    rwNumBytesToCopy = length;

    dbg(DBG_USR3, "rwNumBytesToCopy = %d\n", length);

    if ((rwDataOffset % XNP_BYTES_PER_LINE) != 0) {
      // offset not aligned, write partial line
      rwDataLen = XNP_BYTES_PER_LINE-rwDataOffset%XNP_BYTES_PER_LINE;
      if (rwNumBytesToCopy < rwDataLen)
	rwDataLen = length;
      rwFlashLen = rwDataLen;
      memcpy(tmpRWbuf, rwBuf, rwFlashLen);
      isAligned = FALSE;
    }
    else {
      // offset aligned, write whole line
      rwDataLen = (rwNumBytesToCopy > XNP_BYTES_PER_LINE) ? XNP_BYTES_PER_LINE : rwNumBytesToCopy;
      rwFlashLen = (rwDataLen == XNP_BYTES_PER_LINE) ? sizeof(xnpSrecLine_t) : rwDataLen + 8;
      xnpLine->pid = pid;
      xnpLine->cid = rwDataOffset / XNP_BYTES_PER_LINE;
      xnpLine->type = (rwDataOffset == 0) ? 0x0 : 0x1;
      xnpLine->length = rwDataLen+3;
      xnpLine->addr = (rwDataOffset == 0) ? 0x0 : rwDataOffset-XNP_BYTES_PER_LINE;
      memcpy(xnpLine->data, rwBuf, rwDataLen);
      xnpLine->checksum = 0x0;
      isAligned = TRUE;
    }

    flashPage = OFFSET_TO_FLASH_PAGE(rwDataOffset);
    flashOffset = OFFSET_TO_FLASH_OFFSET(rwDataOffset);
    if (isAligned)
      flashOffset -= XNP_HEADER_SIZE;

    if (call Flash.write(flashPage, flashOffset, tmpRWbuf, rwFlashLen) == FAIL) {
      isBusy = FALSE;
      return FAIL;
    }
    
    return SUCCESS;
    
  }

  event result_t Flash.writeDone(result_t result) {

    uint16_t flashPage, flashOffset;

    if (result == FAIL
	|| writingLastLine) {
      isBusy = FALSE;
      writingLastLine = FALSE;
      return signal BootImg.writeDone(result);
    }

    rwBuf += rwDataLen;
    rwDataOffset += rwDataLen;
    rwNumBytesToCopy -= rwDataLen;
    if (rwDataOffset-XNP_BYTES_PER_LINE >= imgSize-1) {
      // write out S9 line
      rwDataOffset = (((rwDataOffset-1)/XNP_BYTES_PER_LINE)+1)*XNP_BYTES_PER_LINE;
      writingLastLine = TRUE;
    }
    else if (rwNumBytesToCopy == 0) {
      // done writing page
      isBusy = FALSE;
      return signal BootImg.writeDone(result);
    }

    // keep writing more data
    // offset aligned
    rwDataLen = (rwNumBytesToCopy > XNP_BYTES_PER_LINE) ? XNP_BYTES_PER_LINE : rwNumBytesToCopy;
    rwFlashLen = (rwDataLen % XNP_BYTES_PER_LINE) ? rwDataLen + 8 : sizeof(xnpSrecLine_t);
    xnpLine->pid = pid;
    xnpLine->cid = rwDataOffset / XNP_BYTES_PER_LINE;
    xnpLine->checksum = 0x0;
    if (!writingLastLine) {
      xnpLine->type = 0x1;
      xnpLine->length = rwDataLen+3;
      xnpLine->addr = rwDataOffset-XNP_BYTES_PER_LINE;
      memcpy(xnpLine->data, rwBuf, rwDataLen);
    }
    else {
      xnpLine->type = 0x9;
      xnpLine->length = 0x3;
      xnpLine->addr = 0x0;
    }
    
    flashPage = OFFSET_TO_FLASH_PAGE(rwDataOffset);
    flashOffset = OFFSET_TO_FLASH_OFFSET(rwDataOffset)-XNP_HEADER_SIZE;
    
    if (call Flash.write(flashPage, flashOffset, &tmpRWbuf, rwFlashLen) == FAIL) {
      isBusy = FALSE;
      return signal BootImg.writeDone(FAIL);
    }

    return SUCCESS;

  }

  command result_t BootImg.sync() {
    return call Flash.syncAll();
  }

  event result_t Flash.syncDone(result_t result) {
    return signal BootImg.syncDone(result);
  }

  event result_t Flash.flushDone(result_t result) { return SUCCESS; }
  event result_t Flash.eraseDone(result_t result) { return SUCCESS; }
  event result_t Flash.computeCrcDone(result_t result, uint16_t crc) { return SUCCESS; }

}
