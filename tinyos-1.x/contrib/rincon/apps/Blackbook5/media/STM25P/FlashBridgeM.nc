/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

/**
 * Blackbook to Flash bridge implementation 
 * For the STM25P
 *
 * We add a Timer delay to the start because
 * the radio uses the same SPI bus as the Flash on
 * some motes.  This allows the radio time to startup
 * and then the flash kicks in so Blackbook can boot up
 *
 * @author David Moss (dmm@rincon.com)
 * @author Mark Kranz
 *
 */

includes FlashSettings;

module FlashBridgeM {
  provides {
    interface FlashBridge[uint8_t id];
    interface StdControl;
  }
  
  uses {
#ifdef STM25P_BOOMERANG_VERSION
    interface ResourceCmd as CmdReadCrc;
#endif  
    interface HALSTM25P;
    interface State;
    interface Timer;
  }
}

implementation {
  
  /** The current currentClient */
  uint8_t currentClient;
  
  /** The current address we're working at */
  uint32_t currentAddr;
  
  /** The current pointer to our buffer */
  void *currentBuf;
  
  /** The current length we're dealing with */
  uint32_t currentLen;

  /** The total amount of bytes written */
  uint32_t currentTotal;
  
  /** The current calculated CRC */
  uint16_t currentCrc;
  
  /** The current amount of bytes to write */
  uint16_t currentAmount;
  
  enum {
    S_IDLE = 0,
    S_READ,
    S_WRITE,
    S_ERASE,
    S_ERASE_DONE,
    S_GETCRC,
  };
    
  /***************** Prototypes ****************/
  task void writeTask();
  void write();
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Timer.start(TIMER_ONE_SHOT, 256);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
#ifdef STM25P_BOOMERANG_VERSION
  uint8_t deferredId;
  uint32_t deferredAddr, deferredLen;
  void *deferredBuf;

  event void CmdReadCrc.granted( uint8_t rh ) {
    result_t returnResult = FAIL;

    switch( call State.getState() ) {
    case S_READ:
      returnResult = call HALSTM25P.read(rh, deferredAddr, deferredBuf, deferredLen);
      call State.toIdle();
      signal FlashBridge.readDone[deferredId](deferredAddr, deferredBuf, deferredLen, returnResult);
      break;
    case S_GETCRC:  
      currentCrc = 0;
      returnResult = call HALSTM25P.computeCrc(rh, &currentCrc, currentCrc, deferredAddr, deferredLen);
      call State.toIdle();
      signal FlashBridge.crcDone[deferredId](currentCrc, deferredAddr, deferredLen, returnResult);
      break;
    }

    call CmdReadCrc.release();
  }
#endif


  
  /***************** FlashBridge Commands ****************/
  /** 
   * Read bytes from flash
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  command result_t FlashBridge.read[uint8_t id](uint32_t addr, void *buf, uint32_t len) {   
#ifdef STM25P_BOOMERANG_VERSION
    if(call State.requestState(S_READ)) {
      // save state and request resource
      deferredId = id;
      deferredAddr = addr;
      deferredBuf = buf;
      deferredLen = len;  
      call CmdReadCrc.deferRequest();
    } else {
      return FAIL;
    }      
#else
    result_t returnResult;

    if(call State.requestState(S_READ)) {
      returnResult = call HALSTM25P.read(addr, buf, len);
      call State.toIdle();
      signal FlashBridge.readDone[id](addr, buf, len, returnResult);
    } else {
      return FAIL;
    }
#endif
    
    return SUCCESS;
  }
  
  
  /** 
   * Write bytes to flash
   * @param addr - the address to write to
   * @param *buf - the buffer to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  command result_t FlashBridge.write[uint8_t id](uint32_t addr, void *buf, uint32_t len) {
    if(call State.requestState(S_WRITE)) {
      currentClient = id;
      currentAddr = addr;
      currentBuf = buf;
      currentLen = len;
      currentTotal = 0;
      post writeTask();
      
    } else {
      return FAIL;
    }
    
    return SUCCESS;
  }
  
  
  /**
   * Erase a sector in flash
   * Blackbook only erases in sector granularities, not pages.
   * Sector 0 should be the first sector existing at 0x0
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  command result_t FlashBridge.erase[uint8_t id](uint16_t sector) {
    if(sector > FLASH_TOTAL_SECTORS - 1) {
      return FAIL;
    }
    
    if(call State.requestState(S_ERASE)) {
      currentClient = id;
      currentAddr = sector;
      return call HALSTM25P.sectorErase(currentAddr * FLASH_SECTOR_LENGTH);
      
    } else {
      return FAIL;
    }
  }
  
  
  /**
   * Flush written data to flash. This only applies to some flash
   * chips.
   * @return SUCCESS if the flash will be flushed
   */
  command result_t FlashBridge.flush[uint8_t id]() {
    // Not so fast! Just because this is stubbed out here doesn't
    // mean it isn't in the AT45DB implementation.  If you want
    // your app to be compatible across flash chips and FlashBridge
    // versions, make sure you call this flush() command whenever 
    // you want to ensure the data is actually written to flash.  
    // In the future, this command for the tmote's may take a RAM 
    // page buffer of data and write it to the flash. 
    
    signal FlashBridge.flushDone[id](SUCCESS);
    return SUCCESS;
  }
  
  
  /**
   * Obtain the CRC of a chunk of data sitting on flash.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  command result_t FlashBridge.crc[uint8_t id](uint32_t addr, uint32_t len) {
#ifdef STM25P_BOOMERANG_VERSION        
    if(call State.requestState(S_GETCRC)) {
      deferredId = id;  
      deferredAddr = addr;
      deferredLen = len;  
      call CmdReadCrc.deferRequest();     
    } else {
      return FAIL;
    }
#else
    result_t returnResult;

    if(call State.requestState(S_GETCRC)) {
      currentCrc = 0;
      returnResult = call HALSTM25P.computeCrc(&currentCrc, currentCrc, addr, len);
      call State.toIdle();
      signal FlashBridge.crcDone[id](currentCrc, addr, len, returnResult);
    } else {
      return FAIL;
    }
#endif 
    
    return SUCCESS;
  }
  
  /***************** HALSTM25P Events *****************/
  event void HALSTM25P.pageProgramDone() {
    currentTotal += currentAmount;
    write();
  }
  
  event void HALSTM25P.sectorEraseDone() {
    call State.toIdle();
    signal FlashBridge.eraseDone[currentClient](currentAddr, SUCCESS);
  }
  
  event void HALSTM25P.bulkEraseDone() {
  }
  
  event void HALSTM25P.writeSRDone() {
  }
  
  /***************** Timer Events ****************/
  event result_t Timer.fired() {
    int i; 
    for(i = 0; i < uniqueCount("FlashBridge"); i++) { 
      signal FlashBridge.ready[i](SUCCESS);
    }
    return SUCCESS;
  }
 
  /***************** Tasks ****************/
  /**
   * Write data to the given address in flash with the given length
   * by dividing the data up into pages
   */
  void write() {
    if(currentTotal < currentLen) {
      currentAmount = FLASH_PAGE_LENGTH - ((currentAddr + currentTotal) % FLASH_PAGE_LENGTH);
      
      if (currentLen - currentTotal < currentAmount) {
        currentAmount = currentLen - currentTotal;
      }
    
      if(!call HALSTM25P.pageProgram(currentAddr + currentTotal, currentBuf + currentTotal, currentAmount)) {
        post writeTask();
      }
      
    } else {
      call State.toIdle();
      signal FlashBridge.writeDone[currentClient](currentAddr, currentBuf, currentTotal, SUCCESS);
    }
  }
  
  task void writeTask() {
    write();
  }
  
  
  /***************** Functions ****************/

  
  /***************** Defaults ****************/
  default event void FlashBridge.readDone[uint8_t id](uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  default event void FlashBridge.writeDone[uint8_t id](uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  default event void FlashBridge.eraseDone[uint8_t id](uint16_t sector, result_t result) {
  }
  
  default event void FlashBridge.flushDone[uint8_t id](result_t result) {
  }
  
  default event void FlashBridge.crcDone[uint8_t id](uint16_t calculatedCrc, uint32_t addr, uint32_t len, result_t result) {
  }
  
  default event void FlashBridge.ready[uint8_t id](result_t result) {
  }
  
}













