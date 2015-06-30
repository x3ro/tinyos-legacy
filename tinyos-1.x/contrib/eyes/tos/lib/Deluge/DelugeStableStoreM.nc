// $Id: DelugeStableStoreM.nc,v 1.3 2004/09/20 09:22:49 janhauer Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Provides stable storage services to Deluge.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module DelugeStableStoreM {
  provides {
    interface StdControl;
    interface DelugeImgStableStore as ImgStableStore[uint8_t id];
    interface DelugeMetadataStableStore as MetadataStableStore;
  }
  uses {
    interface AllocationReq;
    interface InternalFlash as IFlash;
    interface PageEEPROM as Flash;
    interface StdControl as FlashControl;
    interface StdControl as SubControl;
  }
}

#define DELUGE_DBG_NUM_PAGES 5

implementation {

  enum {
    S_IDLE,
    S_ALLOCATE,
    S_READ_METADATA,
    S_READ_DATA,
    S_WRITE_METADATA,
    S_WRITE_DATA,
    S_SYNC_DATA,
    S_CHECKING_CRC,
    S_COMPUTING_CRC,
    S_READ_CRC,
    S_WRITE_CRC,
  };

  uint32_t     rwOffset;
  uint16_t     rwLength;
  uint8_t      *rwPtr;
  uint16_t     crc;
  uint8_t      imgID;
  uint8_t      state;
  uint8_t      compID;

#ifdef PLATFORM_PC
  uint8_t  numBaseNodes = 22;
  uint16_t baseNodes[22] = { 0, 1, 2, 156, 176, 196, 216, 236, 237, 257, 277, 297, 317, 479, 489, 499, 509, 519, 529, 539, 549, 559, };
//  uint16_t baseNodes[13] = { 0, 1, 104, 124, 144, 145, 165, 185, 267, 277, 287, 297, 307, };
#endif

  void actualSignal(result_t result) {
    uint8_t tmpState = state;
    state = S_IDLE;
    switch(tmpState) {
    case S_READ_METADATA:
      signal MetadataStableStore.getMetadataDone(result); break;
    case S_WRITE_METADATA: 
      signal MetadataStableStore.writeMetadataDone(result); break;
    case S_SYNC_DATA: 
      signal ImgStableStore.syncImgDataDone[compID](result); break;
    case S_CHECKING_CRC: case S_COMPUTING_CRC: 
      signal ImgStableStore.checkCrcDone[compID](result); break;
    case S_READ_DATA: case S_READ_CRC:
      signal ImgStableStore.getImgDataDone[compID](result); break;
    case S_WRITE_DATA: case S_WRITE_CRC:
      signal ImgStableStore.writeImgDataDone[compID](result); break;
    }
  }

  task void signalSuccess() { actualSignal(SUCCESS); }
  task void signalFail() { actualSignal(FAIL); }

  result_t signalDone(result_t result) {
    if (result == SUCCESS)
      post signalSuccess();
    else
      post signalFail();
    return SUCCESS;
  }

  eeprompageoffset_t calcNumBytes() {

    eeprompageoffset_t pageOffset = rwOffset % (uint32_t)DELUGE_FLASH_PAGE_SIZE;
    eeprompageoffset_t numBytes;

    if (rwLength < DELUGE_FLASH_PAGE_SIZE - pageOffset)
      numBytes = rwLength;
    else
      numBytes = DELUGE_FLASH_PAGE_SIZE - pageOffset;

    if (state == S_COMPUTING_CRC && numBytes > DELUGE_PKT_PAYLOAD_SIZE)
      numBytes = DELUGE_PKT_PAYLOAD_SIZE;

    return numBytes;

  }

  result_t doOperation(bool increment) {

    eeprompage_t startPage;
    eeprompageoffset_t pageOffset;
    eeprompageoffset_t lastBytes = calcNumBytes();
    result_t result = FAIL;

    if (increment) {
      if (rwLength <= lastBytes) {
	if (state == S_COMPUTING_CRC)
	  state = S_CHECKING_CRC;
	else
	  return signalDone(SUCCESS);
      }
      else {
	rwLength -= lastBytes;
	rwOffset += lastBytes;
	if (state != S_COMPUTING_CRC)
	  rwPtr += lastBytes;
      }
    }

    startPage = call ImgStableStore.imgNum2FlashPage[compID](imgID);
    startPage += rwOffset / DELUGE_FLASH_PAGE_SIZE;
    pageOffset = rwOffset % DELUGE_FLASH_PAGE_SIZE;

    switch(state) {
    case S_READ_DATA: case S_COMPUTING_CRC:
      result = call Flash.read(startPage, pageOffset, rwPtr, calcNumBytes());
      break;
    case S_READ_CRC: case S_CHECKING_CRC:
      result = call Flash.read(startPage, DELUGE_FLASH_PAGE_SIZE, rwPtr, sizeof(uint16_t));
      break;
    case S_WRITE_DATA:
      result = call Flash.write(startPage, pageOffset, rwPtr, calcNumBytes());
      break;
    case S_WRITE_CRC:
      result = call Flash.write(startPage, DELUGE_FLASH_PAGE_SIZE, rwPtr, sizeof(uint16_t));
      break;
    case S_SYNC_DATA:
      result = call Flash.syncAll();
      break;
    }

    return result;

  }  

  result_t newRequest(uint8_t newState, uint8_t id, uint8_t imgNum, 
		      uint32_t offset, void* buf, uint32_t len) {

    if (state != S_IDLE)
      return FAIL;

#ifdef DELUGE_GOLDEN_IMAGE
    if (imgNum >= DELUGE_NUM_IMGS && imgNum != DELUGE_GOLDEN_IMAGE_NUM)
      return FAIL;
#else
    if (imgNum >= DELUGE_NUM_IMGS)
      return FAIL;
#endif

    compID = id;
    imgID = imgNum;
    rwPtr = buf;
    rwOffset = offset;
    rwLength = len;
    crc = 0;

    state = newState;
    if (doOperation(FALSE) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command result_t StdControl.init() { 
    uint32_t start, length;

    result_t result = call SubControl.init();

    state = S_ALLOCATE;

    start = (uint32_t)DELUGE_GOLDEN_IMAGE_PAGE * (uint32_t)DELUGE_FLASH_PAGE_SIZE;
    length = (uint32_t)call ImgStableStore.imgNum2FlashPage[0](DELUGE_NUM_IMGS);
    length *= (uint32_t)DELUGE_FLASH_PAGE_SIZE;

    return rcombine(call AllocationReq.requestAddr(start, length), result);
  }

  command result_t StdControl.start() { 
    return call SubControl.start();
  }

  command result_t StdControl.stop() { return SUCCESS; }

  event result_t AllocationReq.requestProcessed(result_t result) {
    // if allocation request fails, keep StableStore locked up
    if (result == SUCCESS)
      state = S_IDLE;
    return SUCCESS;
  }

  command result_t MetadataStableStore.getMetadata(DelugeMetadata* metadata) {

    if (state != S_IDLE)
      return FAIL;
    
    state = S_READ_METADATA;

#ifdef PLATFORM_PC
    {
      uint8_t* tmp = (uint8_t*)metadata;
      uint8_t  i;
      memset(metadata, 0x0, sizeof(DelugeMetadata));
      if (TOS_LOCAL_ADDRESS == 0) {
	metadata->imgSummary[0].vNum = 1;
	metadata->imgSummary[0].numPgs = DELUGE_DBG_NUM_PAGES;
	metadata->imgSummary[0].numPgsComplete = DELUGE_DBG_NUM_PAGES;
	for ( i = sizeof(metadata->crc), metadata->crc = 0; i < sizeof(DelugeMetadata); i++ )
	  metadata->crc = crcByte(metadata->crc, tmp[i]);
      }
      return signalDone(SUCCESS);
    }
#endif

    if (call Flash.read(DELUGE_FLASH_METADATA_PAGE, 0, metadata, sizeof(DelugeMetadata)) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command result_t MetadataStableStore.writeMetadata(DelugeMetadata* metadata) {

    if (state != S_IDLE)
      return FAIL;

    state = S_WRITE_METADATA;
    if (call Flash.write(DELUGE_FLASH_METADATA_PAGE, 0, metadata, sizeof(DelugeMetadata)) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command eeprompage_t ImgStableStore.imgNum2FlashPage[uint8_t id](uint8_t imgNum) {
    uint32_t     maxImageBytes;
    eeprompage_t flashPage;

    if (imgNum == DELUGE_GOLDEN_IMAGE_NUM)
      return DELUGE_GOLDEN_IMAGE_PAGE;

    maxImageBytes = (uint32_t)DELUGE_MAX_IMAGE_SIZE * (uint32_t)1024;
    flashPage = ((maxImageBytes-(uint32_t)1)/(uint32_t)DELUGE_FLASH_PAGE_SIZE)+(uint32_t)1;
    flashPage *= imgNum;
    flashPage += DELUGE_FLASH_METADATA_PAGE + 1;
    return flashPage;
  }

  command uint8_t ImgStableStore.flashPage2ImgNum[uint8_t id](eeprompage_t flashPage) {
    uint32_t maxImageBytes;
    uint32_t imgNum;

    if (flashPage == DELUGE_GOLDEN_IMAGE_PAGE)
      return DELUGE_GOLDEN_IMAGE_NUM;

    maxImageBytes = (uint32_t)DELUGE_MAX_IMAGE_SIZE * (uint32_t)1024;
    imgNum = flashPage;
    imgNum -= DELUGE_FLASH_METADATA_PAGE + 1;
    imgNum /= ((maxImageBytes-(uint32_t)1)/(uint32_t)DELUGE_FLASH_PAGE_SIZE)+(uint32_t)1;
    return imgNum;
  }

  command result_t ImgStableStore.getImgData[uint8_t id](uint8_t imgNum, uint32_t offset,
							 void* dest, uint32_t length) {
    return newRequest(S_READ_DATA, id, imgNum, offset, dest, length);
  }

  command result_t ImgStableStore.writeImgData[uint8_t id](uint8_t imgNum, uint32_t offset, 
							   void* source, uint32_t length) {
    return newRequest(S_WRITE_DATA, id, imgNum, offset, source, length);
  }

  command result_t ImgStableStore.syncImgData[uint8_t id]() {
    return newRequest(S_SYNC_DATA, id, 0, 0, 0, 0);
  }

  command result_t ImgStableStore.checkCrc[uint8_t id](uint8_t imgNum, pgnum_t pgNum, void* buf) {
    uint32_t offset = (uint32_t)pgNum * (uint32_t)DELUGE_BYTES_PER_PAGE;
    return newRequest(S_COMPUTING_CRC, id, imgNum, offset, buf, DELUGE_BYTES_PER_PAGE);
  }

  command result_t ImgStableStore.getPageCrc[uint8_t id](uint8_t imgNum, pgnum_t pgNum, void* _crc) {
    uint32_t offset = (uint32_t)(pgNum+1) * DELUGE_BYTES_PER_PAGE;
    return newRequest(S_READ_CRC, id, imgNum, offset, _crc, sizeof(uint16_t));
  }

  command result_t ImgStableStore.writePageCrc[uint8_t id](uint8_t imgNum, pgnum_t pgNum, void* _crc) {
    uint32_t offset = (uint32_t)(pgNum+1) * DELUGE_BYTES_PER_PAGE;
    return newRequest(S_WRITE_CRC, id, imgNum, offset, _crc, sizeof(uint16_t));
  }

  event result_t Flash.readDone(result_t result) { 

    uint8_t i;

    if (result == FAIL)
      return signalDone(FAIL);

    switch(state) {
    case S_READ_CRC: case S_READ_METADATA:
      return signalDone(result);
    case S_COMPUTING_CRC:
      for ( i = 0; i < calcNumBytes(); i++ ) 
	crc = crcByte(crc, rwPtr[i]);
      break;
    case S_CHECKING_CRC:
      if (rwPtr[0] == ((crc >> 0x0) & 0xff)
	  && rwPtr[1] == ((crc >> 0x8) & 0xff))
	return signalDone(SUCCESS);
      return signalDone(FAIL);
    }

    if (doOperation(TRUE) == FAIL)
      signalDone(FAIL);

    return SUCCESS;

  }

  event result_t Flash.writeDone(result_t result) {

    if (result == FAIL)
      return signalDone(FAIL);

    switch(state) {
    case S_WRITE_CRC: case S_WRITE_METADATA:
      if (call Flash.syncAll() == FAIL)
	return signalDone(FAIL);
      break;
    case S_WRITE_DATA:
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_MICAZ)
      if (call Flash.syncAll() == FAIL)
	return signalDone(FAIL);
#else
      if (doOperation(TRUE) == FAIL)
	return signalDone(FAIL);
#endif
      break;
    }

    return SUCCESS;

  }

  event result_t Flash.syncDone(result_t result) { 

    switch(state) {
    case S_WRITE_CRC: case S_WRITE_METADATA: case S_SYNC_DATA:
      return signalDone(result);
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_MICAZ)
    case S_WRITE_DATA:
      if (result == FAIL)
	return signalDone(result);
      
      if (doOperation(TRUE) == FAIL)
	signalDone(FAIL);
      break;
#endif
    }

    return SUCCESS;

  }


  event result_t Flash.flushDone(result_t result) { return SUCCESS; }
  event result_t Flash.eraseDone(result_t result) { return SUCCESS; }
  event result_t Flash.computeCrcDone(result_t result, uint16_t _crc) { return SUCCESS; }

  default event result_t ImgStableStore.getImgDataDone[uint8_t id](result_t result) { return FAIL; }
  default event result_t ImgStableStore.checkCrcDone[uint8_t id](result_t result) { return FAIL; }
  default event result_t ImgStableStore.writeImgDataDone[uint8_t id](result_t result) { return FAIL; }
  default event result_t ImgStableStore.syncImgDataDone[uint8_t id](result_t result) { return FAIL; }

  // added, because MetadataStableStore is not connected to
  default event result_t MetadataStableStore.getMetadataDone(result_t result) { return FAIL; }
  default event result_t MetadataStableStore.writeMetadataDone(result_t result) { return FAIL; }  
}
