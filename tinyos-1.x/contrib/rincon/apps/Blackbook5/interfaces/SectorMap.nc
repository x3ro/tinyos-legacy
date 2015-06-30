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
 * Blackbook SectorMap Interface
 */
 
includes Blackbook;

interface SectorMap {
  
  /**
   * @return the total sectors on flash
   */
  command uint8_t getTotalSectors();
  
  /**
   * Obtain the largest sector that is not in use
   * on the flash
   * @return the largest available sector to write to 
   */
  command flashsector *nextLargestIdleSector();
  
  /**
   * Obtain the largest sector that is not in use
   * on the flash.  This will allow us to see exactly
   * how much space exists for the next flashnode without
   * affecting the global variable that decides which sector
   * that may be.  This is especially useful for dictating the
   * size of a file that is part of a continuous-write operation
   * and the file size needs to fit exactly in one sector.
   *
   * @return the largest available sector that will be written to
   *      when a SectorMap.nextLargestIdleSector() command is called
   */
  command flashsector *viewNextLargestIdleSector();
  
  /**
   * Get the flashsector at the specified address in flash.
   * @return the flashsector that exists at the given address
   *     NULL if the flashAddress is out of bounds.
   */
  command flashsector *getSectorAtAddress(uint32_t flashAddress);
  
  /**
   * Get the sector at a specified volume index
   */
  command flashsector *getSectorAtVolume(uint8_t volume);
  
  /**
   * @return the total nodes in the given sector
   */
  command uint8_t getNodesInSector(flashsector *focusedSector);
  
  /**
   * @return TRUE if the sector can be erased
   */
  command bool canErase(uint8_t volume);
  
  /**
   * Document the existence of a flashnode in a sector on flash.
   * @param focusedNode - the flashnode to document
   */
  command void documentNode(flashnode *focusedNode);
  
  /**
   * Remove a valid flashnode from its sector.
   * The flashnode must be finalized before removing it.
   * This helps the garbage collector know which sectors to erase.
   */
  command void removeNode(flashnode *focusedNode);
  
  /**
   * Retreive the earliest available write address in a given sector.
   * @return the write address of the sector relative to 0x0
   */
  command uint32_t getSectorWriteAddress(flashsector *focusedSector);
  
  /**
   * @return TRUE if the given flashnode is within the bounds of the given sector
   */
  command bool isInSector(flashsector *focusedSector, flashnode *focusedNode);
  
  /**
   * Retrieve the base address of the flashsector relative to 0x0.
   * @return the relative address of the flashsector from 0x0
   */
  command uint32_t getSectorBaseAddress(flashsector *focusedSector);
  
  /**
   * Obtain the remaining free bytes in a specified
   * flashsector
   * @param focusedSector - the flashsector to find the free bytes in
   * @return the number of free page bytes in the flashsector
   */
  command uint32_t bytesRemaining(flashsector *focusedSector);

  /**
   * Obtain the total amount of free space on the flash.
   * @return the total amount of free space on the flash
   */
  command uint32_t getFreeSpace();
  
  /**
   * The sector was erased by the garbage collector
   * @param sectorIndex - the sector erased
   */
  command void eraseComplete(uint8_t sectorIndex);
  
  /** 
   * Reserve a sector for writing
   * @param *focusedSector pointer to the sector we want to reserve
   */
  command void reserveSector(flashsector *focusedSector);
  
  /**
   * Free a sector that was reserved for writing
   * @param *focusedSector pointer to the sector we want to free
   */
  command void freeSector(flashsector *focusedSector);
}


