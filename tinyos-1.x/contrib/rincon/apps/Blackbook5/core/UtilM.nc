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
 * Blackbook Utilities
 * @author dmm
 */

includes Blackbook;
includes FlashSettings;
includes Storage;

module UtilM {
  provides {
    interface Util;
  }
  uses {
    interface GenericCrc;
  }
}

implementation {
  
  /***************** Util Commands ****************/
  /**
   * Convert the specified length of data
   * into number of flash pages. This always rounds up except
   * when it's right on.
   * @return the number of pages on flash required
   *     to hold the data
   */
  command uint16_t Util.convertBytesToPages(uint32_t bytes) {
    return (bytes >> FLASH_PAGE_SIZE_LOG2) + 1;
  }
    
  /**
   * Convert the specified number of flash pages
   * to bytes
   * @return the number of bytes in the given number of flash pages
   */
  command uint32_t Util.convertPagesToBytes(uint16_t pages) {
    return pages * FLASH_PAGE_LENGTH;
  }
  
  /**
   * Get the address of the first byte of the next page  
   * based on a given address
   * @param currentAddress -
   */
  command uint32_t Util.getNextPageAddress(uint32_t currentAddress) {
    return FLASH_PAGE_LENGTH * ((currentAddress >> FLASH_PAGE_SIZE_LOG2) + 1);
  }
  
  /**
   * Get the address of the first byte of the next sector
   * @param currentAddress -
   * @return the base address of the next flash sector
   */
  command uint32_t Util.getNextSectorAddress(uint32_t currentAddress) {
    return FLASH_SECTOR_LENGTH * ((currentAddress >> FLASH_SECTOR_SIZE_LOG2) + 1);
  }
  
  /**
   * Copy a string filename from one char
   * array to a filename
   */
  command void Util.filenameCpy(filename *to, char *from) {
    int i;
    char *destPtr = (char *) to->getName;
    memset(destPtr, '\0', FILENAME_LENGTH);
 
    for(i = 0; i < FILENAME_LENGTH-1; i++) {
      if(!(*destPtr++ = *from++)) {
        return;
      }
    }
    *destPtr = '\0';
  }
  
  /**
   * @return the crc-16 of a a given filename
   */
  command uint16_t Util.filenameCrc(filename *focusedFilename) {
    return call GenericCrc.crc16(0, focusedFilename, FILENAME_LENGTH);
  }
}

