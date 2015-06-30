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
 * Blackbook FlashBridge interface
 * Implement this interface with consistent behavior for any
 * flash type Blackbook should sit on top of
 */
 
interface FlashBridge {

  /** 
   * Read bytes from flash
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  command result_t read(uint32_t addr, void *buf, uint32_t len);
  
  /** 
   * Write bytes to flash
   * @param addr - the address to write to
   * @param *buf - the buffer to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  command result_t write(uint32_t addr, void *buf, uint32_t len);
  
  /**
   * Erase a sector in flash
   * Blackbook only erases in sector granularities, not pages.
   * Sector 0 should be the first sector existing at FS_START_ADDRESS
   * defined in FlashSettings.h
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  command result_t erase(uint16_t sector);
  
  /**
   * Flush written data to flash. This only applies to some flash
   * chips.
   * @return SUCCESS if the flash will be flushed
   */
  command result_t flush();
  
  /**
   * Obtain the CRC of a chunk of data sitting on flash.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  command result_t crc(uint32_t addr, uint32_t len);
  
  
  /**
   * Read is complete
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  event void readDone(uint32_t addr, void *buf, uint32_t len, result_t result);
  
  /**
   * Write is complete
   * @param addr - the address to write to
   * @param *buf - the buffer to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  event void writeDone(uint32_t addr, void *buf, uint32_t len, result_t result);
  
  /**
   * Erase is complete
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  event void eraseDone(uint16_t sector, result_t result);
  
  /**
   * Flush is complete
   * @param result - SUCCESS if the flash was flushed
   */
  event void flushDone(result_t result);
  
  /**
   * CRC-16 is computed
   * @param crc - the computed CRC.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  event void crcDone(uint16_t calculatedCrc, uint32_t addr, uint32_t len, result_t result);

  /**
   * Signaled when the flash is ready to be used
   * @param result - SUCCESS if we can use the flash.
   */
  event void ready(result_t result);
}

