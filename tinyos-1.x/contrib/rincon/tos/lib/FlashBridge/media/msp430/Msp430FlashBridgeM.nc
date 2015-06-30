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
 * FlashBridge implementation for the MSP430 internal flash
 * Start address is 0x0
 * End address is 0xFF
 *
 * @author David Moss
 */

includes FlashSettings;

module Msp430FlashBridgeM {
  provides {
    interface FlashBridge[uint8_t id];
    interface FlashSettings;
    interface StdControl;
  }

  uses {
    interface GenericCrc;
  }
}

implementation {

  enum {
    FLASH_OFFSET = 0x1000,
  };
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    int i;
    for(i = 0; i < uniqueCount("FlashBridge"); i++) { 
      signal FlashBridge.ready[i](SUCCESS);
    }
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
    void *addressPtr = (uint16_t *) ((uint16_t) addr); 
     
    if(addr + len > call FlashSettings.getFlashSize()) {
      return FAIL;
    }
    
    addressPtr += FLASH_OFFSET;
 
    memcpy(buf, addressPtr, len);
    signal FlashBridge.readDone[id](addr, buf, len, SUCCESS);
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
    void *addressPtr = (uint16_t *) ((uint16_t) addr); 
    
    if(addr + len > call FlashSettings.getFlashSize()) {
      return FAIL;
    }
    
    addressPtr += FLASH_OFFSET;

    atomic {
      FCTL2 = FWKEY + FSSEL1 + FN2;
      FCTL3 = FWKEY;      
      FCTL1 = FWKEY + WRT;
      memcpy(addressPtr, buf, len);
      FCTL3 = FWKEY + LOCK;
    }
    
    signal FlashBridge.writeDone[id](addr, buf, len, SUCCESS);
    return SUCCESS;
  }
  
  /**
   * Erase a eraseUnitIndex in internal flash
   *
   * @param eraseUnitIndex - the eraseUnitIndex to erase, starting at 0
   * @return SUCCESS if the eraseUnitIndex will be erased
   */
  command result_t FlashBridge.erase[uint8_t id](uint16_t eraseUnitIndex) {
    uint16_t *addressPtr;
    if(eraseUnitIndex > call FlashSettings.getTotalEraseUnits()) {
      return FAIL;
    }
    
    addressPtr = (uint16_t *) (FLASH_OFFSET + ((uint16_t) call FlashSettings.getEraseUnitSize() * (uint16_t) eraseUnitIndex));

    atomic {
      FCTL2 = FWKEY + FSSEL1 + FN2;
      FCTL3 = FWKEY;
      FCTL1 = FWKEY + ERASE;
      *addressPtr = 0;
      FCTL3 = FWKEY + LOCK;
    }
    
    signal FlashBridge.eraseDone[id](eraseUnitIndex, SUCCESS);
    return SUCCESS;
  }
  
  /**
   * Flush written data to flash. This only applies to some flash
   * chips.
   * @return SUCCESS if the flash will be flushed
   */
  command result_t FlashBridge.flush[uint8_t id]() {
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
    void *addressPtr = (uint16_t *) ((uint16_t) addr); 
    
    if(addr + len > call FlashSettings.getFlashSize()) {
      return FAIL;
    }
    
    addressPtr += FLASH_OFFSET;
    
    signal FlashBridge.crcDone[id](call GenericCrc.crc16(0, addressPtr, len), addr, len, SUCCESS);
    return SUCCESS;
  }
  
  /***************** FlashSettings Commands ****************/
  /**
   * @return the total size of the flash
   */
  command uint32_t FlashSettings.getFlashSize() {
    return MSP430_ERASE_UNIT_LENGTH * MSP430_ERASE_UNITS;
  }
  
  /**
   * @return the total number of erase units on the flash
   */
  command uint32_t FlashSettings.getTotalEraseUnits() {
    return MSP430_ERASE_UNITS;
  }
  
  /**
   * @return the erase unit size
   */
  command uint32_t FlashSettings.getEraseUnitSize() {
    return MSP430_ERASE_UNIT_LENGTH;
  }
  
  /**
   * @return the total write units on flash
   */
  command uint32_t FlashSettings.getTotalWriteUnits() {
    return MSP430_WRITE_UNITS;
  }
  
  /**
   * @return the total write unit size
   */
  command uint32_t FlashSettings.getWriteUnitSize() {
    return MSP430_WRITE_UNIT_LENGTH;
  }
  
  /**
   * @return the fill byte used on this flash when the flash is empty
   */
  command uint8_t FlashSettings.getFillByte() {
    return MSP430_FILL_BYTE;
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
    return MSP430_ERASE_UNIT_LENGTH_LOG2;
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
    return MSP430_WRITE_UNIT_LENGTH_LOG2;
  }
  
  

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

