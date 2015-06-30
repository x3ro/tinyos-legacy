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

module FlashBridgeM {
  provides {
    interface FlashBridge[uint8_t id];
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
     
    if(addr + len > FLASH_SEGMENT_LENGTH * FLASH_TOTAL_SEGMENTS) {
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
    
    if(addr + len > FLASH_SEGMENT_LENGTH * FLASH_TOTAL_SEGMENTS) {
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
   * Erase a segment in internal flash
   *
   * @param segment - the segment to erase, starting at 0
   * @return SUCCESS if the segment will be erased
   */
  command result_t FlashBridge.erase[uint8_t id](uint16_t segment) {
    int8_t *addressPtr;
    if(segment > 1) {
      return FAIL;
    }
    
    addressPtr = (int8_t *) (FLASH_OFFSET + (FLASH_SEGMENT_LENGTH * (int8_t) segment));

    atomic {
      FCTL2 = FWKEY + FSSEL1 + FN2;
      FCTL3 = FWKEY;
      FCTL1 = FWKEY + ERASE;
      *addressPtr = 0;
      FCTL3 = FWKEY + LOCK;
    }
    
    signal FlashBridge.eraseDone[id](segment, SUCCESS);
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
    
    if(addr + len > FLASH_SEGMENT_LENGTH * FLASH_TOTAL_SEGMENTS) {
      return FAIL;
    }
    
    addressPtr += FLASH_OFFSET;
    
    signal FlashBridge.crcDone[id](call GenericCrc.crc16(0, addressPtr, len), addr, len, SUCCESS);
    return SUCCESS;
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

