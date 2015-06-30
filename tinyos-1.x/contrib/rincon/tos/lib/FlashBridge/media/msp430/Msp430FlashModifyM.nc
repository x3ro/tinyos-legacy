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
 * Modify bytes on flash with the ability to cleanly overwrite
 * bytes that have already been written
 *
 * Users should use the FlashBridge to know when the flash is
 * ready to be written.
 * 
 * We know from the Msp430FlashBridge implementation that Msp430 
 * flash transactions are not split-phase.  We use this fact
 * in this particular implementation to do some sneaky stuff
 * that you wouldn't normally do without a global originalContents, complex 
 * state machine, and proper event handling.
 * 
 * The modify process here is a standard read-modify-write:
 *   1: Read the segment of the msp430 flash into RAM.
 *   2: Erase the segment of flash.
 *   3: Write the data back to flash with modifications in place.
 * 
 * @author David Moss
 */

module Msp430FlashModifyM {
  provides {
    interface FlashModify[uint8_t id]; 
  }
  
  uses {
    interface FlashSettings;
    interface FlashBridge;
    interface State;
  }
}

implementation {
  
  /** The current client we're working with */
  uint8_t currentClient;
  
  /** The contents of a segment (erase unit) on our msp430's internal flash */
  uint8_t originalContents[128];
  
  /**
   * States
   */
  enum {
    S_IDLE,
    S_BUSY,
  };
  
  /***************** Prototypes ****************/
  result_t modify(uint32_t addr, uint8_t *buf, uint32_t len);
  
  /***************** FlashModify Commands ****************/
  /**
   * Modify bytes at the given location on flash
   * @param addr The address to modify
   * @param *buf Pointer to the originalContents to write to flash
   * @param len The length of data to write
   * @return SUCCESS if the bytes will be modified
   */
  command result_t FlashModify.modify[uint8_t id](uint32_t addr, void *buf, uint32_t len) {
    if(!call State.requestState(S_BUSY)) {
      return FAIL;
    }
    
    if(addr + len > call FlashSettings.getFlashSize()) {
      call State.toIdle();
      return FAIL;
    }
    
    currentClient = id;
    
    // modify() clears the State and signals the modified event
    return modify(addr, buf, len);
  }
  
  
  /***************** FlashBridge Events ****************/
  /**
   * Read is complete
   * @param addr - the address to read from
   * @param *buf - the originalContents to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  event void FlashBridge.readDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  /**
   * Write is complete
   * @param addr - the address to write to
   * @param *buf - the originalContents to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  event void FlashBridge.writeDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
  
  /**
   * Erase is complete
   * @param eraseUnitIndex - the erase unit id to erase
   * @return SUCCESS if the erase unit will be erased
   */
  event void FlashBridge.eraseDone(uint16_t eraseUnitIndex, result_t result) {
  }
  
  /**
   * Flush is complete
   * @param result - SUCCESS if the flash was flushed
   */
  event void FlashBridge.flushDone(result_t result) {
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
  
  
  /***************** Functions ****************/
  /**
   * This function can probably be applied to flash chips many small
   * erase units.  But it won't work for huge erase units.
   */
  result_t modify(uint32_t addr, uint8_t *buf, uint32_t len) {
    uint8_t eraseUnit;
    uint32_t eraseUnitAddress;
    uint8_t *contentsPtr;
    int i;
    
    for(eraseUnit = 0; eraseUnit < call FlashSettings.getTotalEraseUnits(); eraseUnit++) {
      eraseUnitAddress = eraseUnit * call FlashSettings.getEraseUnitSize();
      
      // Find out if the modified memory is within the current erase unit bounds
      if(((addr + len > eraseUnitAddress) && (addr < (eraseUnitAddress + call FlashSettings.getEraseUnitSize())))
          || ((addr < eraseUnitAddress) && (addr + len > eraseUnitAddress + call FlashSettings.getEraseUnitSize()))
          || ((addr + len > eraseUnitAddress) && (addr + len < eraseUnitAddress + call FlashSettings.getEraseUnitSize()))) {
          
        // The modified bytes are within this erase unit
        call FlashBridge.read(eraseUnitAddress, originalContents, call FlashSettings.getEraseUnitSize());
        call FlashBridge.erase(eraseUnit);        
        contentsPtr = originalContents;
        
        for(i = eraseUnitAddress; i < eraseUnitAddress + call FlashSettings.getEraseUnitSize(); i++) {
          if(i < addr || i >= addr + len) {
            call FlashBridge.write(i, contentsPtr, 1);
          } else {
            call FlashBridge.write(i, buf, 1);
            *buf++;
          }
          *contentsPtr++;
        }
      }
    }
    
    call State.toIdle();
    signal FlashModify.modified[currentClient](addr, buf, len, SUCCESS);
    return SUCCESS;
  }
  
  
  /***************** Defaults ****************/
  default event void FlashModify.modified[uint8_t id](uint32_t addr, void *buf, uint32_t len, result_t result) {
  }
    
}

