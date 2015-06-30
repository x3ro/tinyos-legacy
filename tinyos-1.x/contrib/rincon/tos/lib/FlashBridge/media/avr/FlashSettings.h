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
 
/*
 * Flash Information 
 * Internal AVR EEPROM
 * 4096 bytes total
 * Because this is an EEPROM, we do not need to erase before write.
 * However, because we're abstracting it to act the same as other
 * memories, FlashBridge will allow you to explicitly erase segments of the 
 * EEPROM.  This will write 0xFF's to all the bytes in the segment.
 * This is important because some apps expect to read 0xFF's to know
 * if that area of memory is available to safely write.
 * 
 * The erase unit size (segment length) below was simply chosen as
 * a multiple of 4096.
 * 
 */ 

enum {
  AVR_WRITE_UNIT_LENGTH = 1,
  AVR_ERASE_UNIT_LENGTH = 0x80,
  AVR_WRITE_UNITS = 4096,
  AVR_ERASE_UNITS = 32,
  AVR_FILL_BYTE = 0xFF,
  
  AVR_WRITE_UNIT_LENGTH_LOG2 = 0,
  AVR_ERASE_UNIT_LENGTH_LOG2 = 7,
}; 


