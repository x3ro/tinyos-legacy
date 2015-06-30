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
 * Blackbook BClean Module
 * This is the garbage collector.
 * @author David Moss - dmm@rincon.com
 */
 
includes FlashSettings;

module BCleanM {
  provides {
    interface BClean;
  }
  
  uses {
    interface FlashBridge;
    interface SectorMap;
  }
}

implementation {

  /** The current sector index we're looking at */
  uint8_t currentSectorIndex;
  
  /** TRUE if we erased one sector on the last run */
  bool erased = FALSE;
  
  /***************** Prototypes *****************/
  /** Loop to search and destroy erasable sectors */
  task void garbageLoop();
  
  task void eraseComplete();
  
  /***************** BClean Commands ****************/
  /**
   * If the free space on the file system is over a threshold
   * then we should go ahead and defrag and garbage collect.
   * This should be run when the mote has some time and energy
   * to spare in its application.
   * @return SUCCESS if the file system will defrag and gc itself
   */
  command result_t BClean.performCheckup() {
    if(call SectorMap.getFreeSpace() < (FLASH_SECTOR_LENGTH * FLASH_TOTAL_SECTORS) * 0.75) {
      return call BClean.gc();
    }
    return FAIL;
  }
  
  /**  
   * Run the garbage collector, erasing any sectors that 
   * contain any data with 0 valid nodes.
   * @return SUCCESS if the garbage collector is run
   */
  command result_t BClean.gc() {
    currentSectorIndex = 0;
    erased = FALSE;
    post garbageLoop();
    return SUCCESS;
  }
  
  /***************** FlashBridge Events ****************/
  /**
   * Read is complete
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  event void FlashBridge.readDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  /**
   * Write is complete
   * @param addr - the address to write to
   * @param *buf - the buffer to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  event void FlashBridge.writeDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  /**
   * Erase is complete
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  event void FlashBridge.eraseDone(uint16_t sector, result_t result) {
    call SectorMap.eraseComplete(currentSectorIndex);
    currentSectorIndex++;
    erased = TRUE;
    post garbageLoop();
  }
  
  /**
   * Flush is complete
   * @param result - SUCCESS if the flash was flushed
   */
  event void FlashBridge.flushDone(result_t result) {
    post eraseComplete();
  }
  
  /**
   * CRC-16 is computed
   * @param crc - the computed CRC.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  event void FlashBridge.crcDone(uint16_t calculatedCrc, uint32_t addr, uint32_t len, result_t result) {
  }

  /**
   * Signaled when the flash is ready to be used
   * @param result - SUCCESS if we can use the flash.
   */
  event void FlashBridge.ready(result_t result) {
  }
  
  /***************** Tasks ****************/
  /** 
   * When entering the garbageLoop for the first time,
   * make sure the currentSectorIndex = 0
   */
  task void garbageLoop() {
    if(currentSectorIndex <= FLASH_LAST_BLACKBOOK_SECTOR) {
      if(call SectorMap.canErase(currentSectorIndex)) {
        signal BClean.erasing();
        call FlashBridge.erase(currentSectorIndex);
        
      } else {
        currentSectorIndex++;
        post garbageLoop();
        return;
      }
      
    } else {
      call FlashBridge.flush();
    }
  }
  
  /**
   * Erase is complete
   */
  task void eraseComplete() {
    signal BClean.gcDone(erased);
  }
}


