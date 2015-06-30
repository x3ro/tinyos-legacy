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
 * FlashBridge to AT45DB interface
 * through the PageEEPROM component
 * 
 * We add a Timer delay to the start because
 * the radio uses the same SPI bus as the Flash on
 * some motes.  This allows the radio time to startup
 * and then the flash kicks in so Blackbook can boot up
 *
 * TODO's
 * The AT45DB flash bridge uses the PageEEPROM component
 * to access the flash. One problem we ran into was with
 * sync and flush - when data is written to the flash, later
 * on we'd come back and the data wouldn't be there. 
 * The code works correctly because debug output and telos motes
 * proved it.  But the flash write was unreliable. This is because
 * the data would get written to the internal RAM buffer on the
 * AT45DB, but that data wouldn't get programmed to main memory.
 * This happened especially when programming to one page on flash
 * and then programming to another page on flash - the next page's
 * data would be lost.
 *
 * To try to solve these problems, after every flash write, the
 * AT45DB flash bridge component sync()'s, flush()'s, and completes.
 * This shouldn't be necessary, and it also wastes energy.
 * The code could be simplified with some better AT45DB low-level interfaces 
 * - i.e. type in a flash address and get it, instead of calculating pages.
 * Another question to ask Atmel is why the flash pages need to be erased
 * before being re-written.  If the answer is "so that your data
 * won't get corrupted" then it doesn't apply to us - Blackbook
 * takes care of not corrupting existing data. That should
 * double the data throughput to flash.
 *
 * Overall, this interface to the AT45DB needs a lot of work, especially
 * in the low-level hardware interface implementations.  A complete
 * re-write with better matching to the FlashBridge interface and
 * more efficiency would make a good project for someone.  I'm sure
 * the throughput and erasing can be performed much faster than what
 * we're seeing now.
 *
 * @author David Moss (dmm@rincon.com)
 */

includes FlashSettings;
includes PageEEPROM;

module At45dbFlashBridgeM {
  provides {
    interface FlashBridge[uint8_t id];
    interface FlashSettings;
    interface StdControl;
  }
  
  uses {
    interface Timer;
    interface State;
    interface PageEEPROM;
  }
}

implementation {

  /** The current address we're working at */
  uint32_t currentAddr;
  
  /** The current pointer to our buffer */
  void *currentBuf;
  
  /** The current length we're dealing with */
  uint32_t currentLen;
  
  /** The current currentClient we're working with */
  uint8_t currentClient;
  
  /** Total amount of bytes read or written */
  uint32_t currentTotal;
  
  /** Total current CRC */
  uint16_t currentCrc;
  
  /** Amount of data to transact */  
  uint16_t amount;

  enum {
    S_IDLE = 0,
    S_READ,
    S_WRITE,
    S_ERASE,
    S_FLUSH, 
    S_GETCRC,
  };
  
  /***************** Prototypes ***************/
  /** Convert the given address and length into PageEEPROM parameters */
  task void calculateParams();
  
  /** Erase a eraseUnitIndex */
  task void erase();
  
  /** Ensure data written is stored on flash */
  task void flush();
  task void sync();
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    // Call a delay Timer to allow compatibility with the CC2420 and the CC1000
    call Timer.start(TIMER_ONE_SHOT, 128);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /***************** FlashBridge Commands ****************/
    /** 
   * Read bytes from flash
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  command result_t FlashBridge.read[uint8_t id](uint32_t addr, void *buf, uint32_t len) {
    if(addr + len > AT45DB_ERASE_UNIT_LENGTH * AT45DB_ERASE_UNITS) {
      return FAIL;
    }
    
    if(call State.requestState(S_READ)) {
      currentClient = id;
      currentAddr = addr;
      currentBuf = buf;
      currentLen = len;
      currentTotal = 0;
      post calculateParams();
      
    } else {
      return FAIL;
    }
    
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
    if(addr + len  > AT45DB_ERASE_UNIT_LENGTH * AT45DB_ERASE_UNITS) {
      return FAIL;
    }
    
    if(call State.requestState(S_WRITE)) {
      currentClient = id;
      currentAddr = addr;
      currentBuf = buf;
      currentLen = len;
      currentTotal = 0;
      post calculateParams();
      
    } else {
      return FAIL;
    }
    
    return SUCCESS;
  }
  
  
  /**
   * Erase an erase unit in flash
   * @param eraseUnitIndex - the eraseUnitIndex id to erase
   * @return SUCCESS if the eraseUnitIndex will be erased
   */
  command result_t FlashBridge.erase[uint8_t id](uint16_t eraseUnitIndex) {
    if(eraseUnitIndex > AT45DB_ERASE_UNITS - 1) {
      return FAIL;
    }
    
    if(call State.requestState(S_ERASE)) {
      currentClient = id;
      currentAddr = eraseUnitIndex * (uint32_t) AT45DB_ERASE_UNIT_LENGTH;
      currentLen = (uint32_t) AT45DB_ERASE_UNIT_LENGTH;
      currentTotal = 0;
      post erase();
      
    } else {
      return FAIL;
    }
    
    return SUCCESS;
  }
  
  
  /**
   * Ensure the data written is stored to flash.
   * @return SUCCESS if the flash will be flushed
   */
  command result_t FlashBridge.flush[uint8_t id]() {
    if(call State.requestState(S_FLUSH)) {
      currentClient = id;
      post flush();
    
    } else {
      return FAIL;
    }
    
    return SUCCESS;
  }
  
  
  /**
   * Obtain the CRC of a chunk of data sitting on flash.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  command result_t FlashBridge.crc[uint8_t id](uint32_t addr, uint32_t len) {
    if(addr + len  > AT45DB_ERASE_UNIT_LENGTH * AT45DB_ERASE_UNITS) {
      return FAIL;
    }
    
    if(call State.requestState(S_GETCRC)) {
      currentClient = id;
      currentAddr = addr;
      currentLen = len;
      currentTotal = 0;
      currentCrc = 0;
      post calculateParams();
      
    } else {
      return FAIL;
    }
    
    return SUCCESS;
  }
  
  
  /***************** FlashSettings Commands ****************/
  /**
   * @return the total size of the flash
   */
  command uint32_t FlashSettings.getFlashSize() {
    return AT45DB_ERASE_UNIT_LENGTH * AT45DB_ERASE_UNITS;
  }
  
  /**
   * @return the total number of erase units on the flash
   */
  command uint32_t FlashSettings.getTotalEraseUnits() {
    return AT45DB_ERASE_UNITS;
  }
  
  /**
   * @return the erase unit size
   */
  command uint32_t FlashSettings.getEraseUnitSize() {
    return AT45DB_ERASE_UNIT_LENGTH;
  }
  
  /**
   * @return the total write units on flash
   */
  command uint32_t FlashSettings.getTotalWriteUnits() {
    return AT45DB_WRITE_UNITS;
  }
  
  /**
   * @return the total write unit size
   */
  command uint32_t FlashSettings.getWriteUnitSize() {
    return AT45DB_WRITE_UNIT_LENGTH;
  }
  
  /**
   * @return the fill byte used on this flash when the flash is empty
   */
  command uint8_t FlashSettings.getFillByte() {
    return AT45DB_FILL_BYTE;
  }
  
  /**
   * We can use the Log base-2 value to calculate
   * the erase unit number by taking an address and
   * shifting it right by the log2 size of the erase units.
   *
   * Here's an example. If erase units are size 0x10000
   * then that means that the log base-2 value is
   * 16. If we want to know which erase unit index address
   * 0x12345 exists within, we take (0x12345 >> 16) == 1.
   * Erase unit index number 1. Simple enough.
   *
   * @return the erase unit size in Log base-2 format
   */
  command uint8_t FlashSettings.getEraseUnitSizeLog2() {
    return AT45DB_ERASE_UNIT_LENGTH_LOG2;
  }
  
  /**
   * We can use the Log base-2 value to calculate
   * the write unit number by taking an address and
   * shifting it right by the log2 size of the write units.
   *
   * Here's an example. If erase units are size 0x100
   * then that means that the log base-2 value is
   * 8. If we want to know which erase unit index address
   * 0x123 exists within, we take (0x123 >> 8) == 1.
   * Write unit index number 1. Simple enough.
   *
   * @return the write unit size in Log2 base-2 format
   */
  command uint8_t FlashSettings.getWriteUnitSizeLog2() {
    return AT45DB_WRITE_UNIT_LENGTH_LOG2;
  }
  
  
  /***************** PageEEPROM Events ****************/
  event result_t PageEEPROM.writeDone(result_t result) {
    if(call State.getState() == S_WRITE) {
      currentTotal += amount;
      post flush();
    }
    return SUCCESS; 
  }
  
  event result_t PageEEPROM.readDone(result_t result) {
    if(call State.getState() == S_READ) {
      currentTotal += amount;
      post calculateParams();
    }
    return SUCCESS; 
  }
  
  event result_t PageEEPROM.eraseDone(result_t result) {
    if(call State.getState() == S_ERASE) {
      post erase();
    }     
    return SUCCESS;  
  }
  
    
  event result_t PageEEPROM.flushDone(result_t result) {
    post sync();
    return SUCCESS; 
  }
  
  event result_t PageEEPROM.syncDone(result_t result) {
    if(call State.getState() == S_FLUSH) {
      call State.toIdle();
      signal FlashBridge.flushDone[currentClient](result);

    } else if(call State.getState() == S_ERASE) {
      call State.toIdle();
      signal FlashBridge.eraseDone[currentClient]((currentAddr >> AT45DB_ERASE_UNIT_LENGTH_LOG2), SUCCESS);
      
    } else if(call State.getState() == S_WRITE) {
      post calculateParams();
    }
    
    
    return SUCCESS; 
  }
  
  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t pageCrc) {
    if(call State.getState() == S_GETCRC) {
      currentTotal += amount;
      currentCrc = pageCrc;
      post calculateParams();
    }
    return SUCCESS;
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
   * Calculate the PageEEPROM parameters need to read or write 
   * to some address and length
   */
  task void calculateParams() {
    uint16_t offset;
    uint16_t startPage = ((currentAddr + currentTotal) >> AT45DB_WRITE_UNIT_LENGTH_LOG2);

    if(currentTotal < currentLen) {
      // More data exists
      offset = (currentAddr + currentTotal) & 0xFF;
      if(startPage == ((currentAddr + currentLen) >> AT45DB_WRITE_UNIT_LENGTH_LOG2)) {
        amount = currentLen - currentTotal;
      } else {
        amount = AT45DB_WRITE_UNIT_LENGTH - offset;
      }

      if(call State.getState() == S_READ) {
        if(!call PageEEPROM.read(startPage, offset, currentBuf + currentTotal, amount)) {
          post calculateParams();
          return;
        }
    
      } else if(call State.getState() == S_WRITE) {
        if(!call PageEEPROM.write(startPage, offset, currentBuf + currentTotal, amount)) {
          post calculateParams();
          return;
        }
        
      } else if(call State.getState() == S_GETCRC) {
        if(!call PageEEPROM.computeCrcContinue(startPage, offset, amount, currentCrc)) {
          post calculateParams();
          return;
        }
      }
    
    } else {
      // No more data exists
      if(call State.getState() == S_READ) {
        call State.toIdle();
        signal FlashBridge.readDone[currentClient](currentAddr, currentBuf, currentTotal, SUCCESS);
      
      } else if(call State.getState() == S_WRITE) {
        call State.toIdle();
        signal FlashBridge.writeDone[currentClient](currentAddr, currentBuf, currentTotal, SUCCESS);
      
      } else if(call State.getState() == S_GETCRC) {
        call State.toIdle();
        signal FlashBridge.crcDone[currentClient](currentCrc, currentAddr, currentLen, SUCCESS);
      }
    }
  }
  
  
  /**
   * Erase a given eraseUnitIndex of pages starting at the currentAddr
   */
  task void erase() {
    if(currentTotal < AT45DB_ERASE_UNIT_LENGTH) {
      // More pages to erase
      // TODO this should reliably erase from the END of the eraseUnitIndex 
      //   to the BEGINNING of the eraseUnitIndex to maintain fault tolerance.
      
      if(!call PageEEPROM.erase((currentAddr + currentTotal) >> AT45DB_WRITE_UNIT_LENGTH_LOG2, TOS_EEPROM_ERASE)) {
        post erase();
      
      } else {
        currentTotal += AT45DB_WRITE_UNIT_LENGTH;
      }
      
    } else {
      // No more pages to erase
      post flush();
    }
  }
  
  
  /**
   * Ensure the data written is stored to flash
   * TODO not sure what the difference is between sync and flush
   * here, but we'll call them both anyway.
   */
  task void flush() {
    if(!call PageEEPROM.flushAll()) {
      post flush();
    }
  }
  
  task void sync() {
    if(!call PageEEPROM.syncAll()) {
      post sync();
    }
  }
  
  
  /***************** Defaults ****************/
  default event void FlashBridge.readDone[uint8_t id](uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  default event void FlashBridge.writeDone[uint8_t id](uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  default event void FlashBridge.eraseDone[uint8_t id](uint16_t eraseUnitIndex, result_t result) {
  }
  
  default event void FlashBridge.flushDone[uint8_t id](result_t result) {
  }
  
  default event void FlashBridge.crcDone[uint8_t id](uint16_t calculatedCrc, uint32_t addr, uint32_t len, result_t result) {
  }
  
  default event void FlashBridge.ready[uint8_t id](result_t result) {
  }
  

}



