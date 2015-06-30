includes Storage;
includes BlockStorage;
// includes HALSTM25P;

// Eventually these values will be taken from BlockStorage
#define FLASH_SIZE 4*32
#define NUM_BLOCKS 4
#define STM25P_PAGE_SIZE 32
//#define STM25P_PAGE_SIZE 256

module FlashLogSimM {
  provides {
    interface LogWrite;
    interface LogRead;
    interface VolumeInit;
  }
}

implementation {
  // simulated flash memory... eventually use BlockStorage
  uint8_t fakeFlash[NUM_BLOCKS*STM25P_PAGE_SIZE];
  uint32_t currentReadOffset;

  // file metadata... eventually use InternalFlash
  blockstorage_t curBlkId;
  block_addr_t curBlkOffset;

  // calculation of flat offset
  uint32_t pairToIndex(blockstorage_t blkId, block_addr_t blkOffset) {
    return (blkId * STM25P_PAGE_SIZE) + blkOffset;
  }

  // simulate split phase-ness
  task void WappendDone() {
    if(curBlkOffset >= STM25P_PAGE_SIZE) {
      // next page
      curBlkId++;
      curBlkOffset = 0;
    }
    signal LogWrite.appendDone(0, 16, SUCCESS); // very hacked
  }
  task void WeraseDone() {
    signal LogWrite.eraseDone(SUCCESS);
  }
  task void WsyncDone() {
    signal LogWrite.syncDone(STORAGE_OK);
  }
  task void RseekDone() {
    signal LogRead.seekDone(STORAGE_OK);
  }
  task void RreadDone() {
    signal LogRead.readDone(0, 16, SUCCESS);
  }
  task void VinitDone() {
    signal VolumeInit.initDone(STORAGE_OK);
  }

  command result_t VolumeInit.init() {
    currentReadOffset = 0;
    curBlkId = 0;
    curBlkOffset = 0;
    post VinitDone();
    return SUCCESS;
  }

  command result_t LogWrite.erase() {
    // signal LogWrite.eraseDone(SUCCESS);
    curBlkId = 0;
    curBlkOffset = 0;
    post WeraseDone();
    return SUCCESS;
  }

  command result_t LogWrite.append(uint8_t* data, uint32_t numBytes) {
    int i;
    int j;
    
    // should error check if it's going to overflow, but this is just sim
    if(pairToIndex(curBlkId, curBlkOffset) >= NUM_BLOCKS*STM25P_PAGE_SIZE) {
      return FAIL;
    }

    j = 0;
    for(i = pairToIndex(curBlkId, curBlkOffset);
	// for(i = curBlkOffset;
	j < numBytes;
	i++, j++) {
      fakeFlash[i] = data[j];
    }
    curBlkOffset += numBytes;
    //signal LogWrite.appendDone(data, numBytes, SUCCESS);
    post WappendDone();
    return SUCCESS;
  }

  command uint32_t LogWrite.currentOffset() {
    return (curBlkId * STM25P_PAGE_SIZE) + curBlkOffset;
  }

  command result_t LogWrite.sync() {
    //signal LogWrite.syncDone(STORAGE_OK);
    post WsyncDone();
    return SUCCESS;
  }

  command result_t LogRead.read(uint8_t* data, uint32_t numBytes) {
    int i;
    int j;
    int bytesRead;
    
    bytesRead = 0;
    j = 0;
    for(i = currentReadOffset; i < FLASH_SIZE &&
	  i < numBytes + currentReadOffset; i++, j++) {
      data[j] = fakeFlash[i];
      bytesRead++;
    }
    currentReadOffset += bytesRead;
    //signal LogRead.readDone(data, bytesRead, SUCCESS);
    post RreadDone();
    return SUCCESS;
  }

  command result_t LogRead.seek(uint32_t cookie) {
    currentReadOffset = cookie;
    //signal LogRead.seekDone(STORAGE_OK);
    post RseekDone();
    return SUCCESS;
  }
}
