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
 * Media Formatter
 * 
 * Make sure your Makefile includes the target flash type's
 * directory.
 *
 * @author David Moss - dmm@rincon.com
 */

module MediaFormatM {
  provides {
    interface StdControl;
  }
  
  uses {
    interface FlashBridge;
    interface FlashSettings;
    interface Leds;
  }
}

implementation {

  /** The current sector we're trying to erase */
  uint8_t currentEraseUnit;
  
  /***************** Prototypes ****************/
  task void eraseAll();
  
  /***************** Commands ****************/
  command result_t StdControl.init() {
    currentEraseUnit = 0;
    call Leds.init();
    return SUCCESS;
  }
   

  command result_t StdControl.start() {
    call Leds.yellowOn();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** FlashBridge Events ****************/
  /**
   * Signaled when the flash is ready to be used
   * @param result - SUCCESS if we can use the flash.
   */
  event void FlashBridge.ready(result_t result) {
    post eraseAll();
  }
  
  /**
   * Erase is complete
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  event void FlashBridge.eraseDone(uint16_t sector, result_t result) {
    if(!result) {
      post eraseAll();
      return;
    }
    
    currentEraseUnit++;
    post eraseAll();
  }
  
  /**
   * Flush is complete
   * @param result - SUCCESS if the flash was flushed
   */
  event void FlashBridge.flushDone(result_t result) {
    call Leds.yellowOff();
    call Leds.greenOn();
    // And that's it! we're done.
  }
  
  
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
   * CRC-16 is computed
   * @param crc - the computed CRC.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  event void FlashBridge.crcDone(uint16_t calculatedCrc, uint32_t addr, uint32_t len, result_t result) {
  }


  
  /***************** Tasks ****************/
  /**
   * Loop through all sectors and erase them
   */
  task void eraseAll() {
    if(currentEraseUnit <= call FlashSettings.getTotalEraseUnits()) {
      if(!call FlashBridge.erase(currentEraseUnit)) {
        post eraseAll();
      }
    
    } else {
      call FlashBridge.flush();
    }
  }
} 

