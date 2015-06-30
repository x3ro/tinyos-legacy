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
 * Atmel AT45DB041B 4Mb Flash on Mica2/Mica2Dot/MicaZ
 * 2048 pages
 * 264 bytes/page
 * 8 pages/block, 1 block = 2112 bytes
 * Sector 0 = 8 pages, 2112 bytes (2k+64)
 * Sector 1 = 248 pages, 65472 bytes (62k+64)
 * Sector 2 = 256 pages, 67584 bytes (64k+1984)
 * Sector 3 = 512 pages, 135168 bytes (128k + 4k)
 * Sector 4 = 512 pages, 135168 bytes (128k + 4k)
 * Sector 5 = 512 pages, 135168 bytes (128k + 4k)
 *
 * Even though the granularity of the sectors changes,
 * All sectors in Blackbook will use the same size -
 * 0x10000 (64kB) sectors since we can erase at the page
 * level.
 *
 * Total of 4,325,376 bits (0.5 megabyte)
 */
enum {
  FLASH_FIRST_BLACKBOOK_SECTOR = 0,
  FLASH_LAST_BLACKBOOK_SECTOR = 7,
  
  FLASH_PAGE_LENGTH = 0x100, 
  FLASH_SECTOR_LENGTH = 0x10000,
  FLASH_SECTOR_SIZE_LOG2 = 16,
  FLASH_TOTAL_SECTORS = 8,
  FLASH_PAGES_PER_SECTOR = 0x100,
  FLASH_PAGE_SIZE_LOG2 = 8,
}; 
