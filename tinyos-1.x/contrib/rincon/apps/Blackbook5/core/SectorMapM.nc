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
 * Blackbook SectorMap Module
 * Keeps track of memory usage and reserves sectors for
 * writing, helps decide where to place new nodes.
 * @author David Moss (dmm@rincon.com)
 */
 
includes Blackbook;
includes FlashSettings;

module SectorMapM {
  provides {
    interface SectorMap;
    interface StdControl;
  }
  
  uses {
    interface Util;
    interface NodeMap;
  }
}

implementation {

  /** Array of flashSectors on the flash */
  flashsector flashSectors[FLASH_TOTAL_SECTORS];
  
  /** Contains the last sector index we allocated new nodes to, to spread them around */
  uint8_t currentSectorIndex;
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    int i;
    for(i = 0; i < call SectorMap.getTotalSectors(); i++) {
      flashSectors[i].index = i;
      flashSectors[i].writePage = 0;
      flashSectors[i].inUse = FALSE;
      flashSectors[i].totalNodes = 0;
    }
    
    currentSectorIndex = FLASH_FIRST_BLACKBOOK_SECTOR;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** SectorMap Commands ****************/
  /**
   * @return the total sectors on flash
   */
  command uint8_t SectorMap.getTotalSectors() {
    return FLASH_LAST_BLACKBOOK_SECTOR - FLASH_FIRST_BLACKBOOK_SECTOR + 1;
  }
  
  /**
   * Obtain the largest sector that is not in use
   * on the flash.  We use a global to store the
   * current sector index we're evaluating
   * so that each call to this function will
   * spread nodes more evenly around the flash.
   * @return the largest available sector to write to 
   */
  command flashsector *SectorMap.nextLargestIdleSector() {
    int leastPages; 
    int sectorIndex;
    flashsector *largestSector = NULL;
   
    leastPages = FLASH_PAGES_PER_SECTOR;
    
    for(sectorIndex = FLASH_FIRST_BLACKBOOK_SECTOR; sectorIndex <= FLASH_LAST_BLACKBOOK_SECTOR; sectorIndex++) {
      currentSectorIndex++;
      if(currentSectorIndex > FLASH_LAST_BLACKBOOK_SECTOR) {
        currentSectorIndex = FLASH_FIRST_BLACKBOOK_SECTOR;
      }
      
      if(!flashSectors[currentSectorIndex].inUse && flashSectors[currentSectorIndex].writePage != FLASH_PAGES_PER_SECTOR && flashSectors[currentSectorIndex].writePage < leastPages) {
        leastPages = flashSectors[currentSectorIndex].writePage;
        largestSector = &flashSectors[currentSectorIndex];
      }
    }
    
    currentSectorIndex = largestSector->index;
    return largestSector;
  }
  
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
  command flashsector *SectorMap.viewNextLargestIdleSector() {
    int leastPages; 
    int sectorIndex;
    uint8_t virtualSectorIndex;
    flashsector *largestSector = NULL;
    
    virtualSectorIndex = currentSectorIndex;
    leastPages = FLASH_PAGES_PER_SECTOR;
    
    for(sectorIndex = FLASH_FIRST_BLACKBOOK_SECTOR; sectorIndex <= FLASH_LAST_BLACKBOOK_SECTOR; sectorIndex++) {
      virtualSectorIndex++;
      if(virtualSectorIndex > FLASH_LAST_BLACKBOOK_SECTOR) {
        virtualSectorIndex = FLASH_FIRST_BLACKBOOK_SECTOR;
      }
      
      if(!flashSectors[virtualSectorIndex].inUse && flashSectors[virtualSectorIndex].writePage != FLASH_PAGES_PER_SECTOR && flashSectors[virtualSectorIndex].writePage < leastPages) {
        leastPages = flashSectors[virtualSectorIndex].writePage;
        largestSector = &flashSectors[virtualSectorIndex];
      }
    }
    
    return largestSector;
  }
  
  
  /**
   * @return the total nodes in the given sector
   */
  command uint8_t SectorMap.getNodesInSector(flashsector *focusedSector) {
    return focusedSector->totalNodes;
  }
  
  /**
   * Get the flashsector at the specified address in flash.
   * @return the flashsector that exists at the given address
   *     NULL if the flashAddress is out of bounds.
   */
  command flashsector *SectorMap.getSectorAtAddress(uint32_t flashAddress) {
    return &flashSectors[flashAddress / FLASH_SECTOR_LENGTH];
  }
  
  /**
   * Get the sector at a specified volume index
   */
  command flashsector *SectorMap.getSectorAtVolume(uint8_t volume) {
    return &flashSectors[volume];
  }
  
  /**
   * @return TRUE if the sector can be erased
   */
  command bool SectorMap.canErase(uint8_t volume) {
    return flashSectors[volume].totalNodes == 0 && call SectorMap.getSectorWriteAddress(&flashSectors[volume]) != call SectorMap.getSectorBaseAddress(&flashSectors[volume]);
  }
  
  
  /**
   * Document the existence of a flashnode in a sector on flash.
   * @param focusedNode - the flashnode to document
   */
  command void SectorMap.documentNode(flashnode *focusedNode) {
    flashsector *mySector;
    uint32_t finalNodeAddress;

    mySector = call SectorMap.getSectorAtAddress(focusedNode->flashAddress);

    if(call SectorMap.getSectorWriteAddress(mySector) <= focusedNode->flashAddress) {      
      // Note the address check above - if this flashnode was already registered,
      // then totalUnfinalizedNodes can't be incremented twice.
      // Unfinalized 
      if(focusedNode->state != NODE_DELETED) {
        mySector->totalNodes++;
      }
    }
    
    if((call NodeMap.getFileFromNode(focusedNode))->firstNode == focusedNode) {
      finalNodeAddress = focusedNode->flashAddress + call Util.getNextPageAddress(focusedNode->reserveLength + sizeof(nodemeta) + sizeof(filemeta) - 1);
    } else {
      finalNodeAddress = focusedNode->flashAddress + call Util.getNextPageAddress(focusedNode->reserveLength + sizeof(nodemeta) - 1);
    }
    
    if(call SectorMap.getSectorWriteAddress(mySector) < finalNodeAddress) {
      mySector->writePage = call Util.convertBytesToPages(finalNodeAddress - call SectorMap.getSectorBaseAddress(mySector) - 1);
    }
  }
  
  
  /**
   * Remove a valid flashnode from its sector. 
   * This helps the garbage collector know which sectors to erase.
   */
  command void SectorMap.removeNode(flashnode *focusedNode) { 
    if(call SectorMap.getSectorWriteAddress(call SectorMap.getSectorAtAddress(focusedNode->flashAddress)) > focusedNode->flashAddress) {      
      (call SectorMap.getSectorAtAddress(focusedNode->flashAddress))->totalNodes--;
    }
  }
  
  /**
   * @return TRUE if the given flashnode is within the bounds of the given sector
   */
  command bool SectorMap.isInSector(flashsector *focusedSector, flashnode *focusedNode) {
    return (call SectorMap.getSectorBaseAddress(focusedSector) <= focusedNode->flashAddress)
        && focusedNode->flashAddress < (call SectorMap.getSectorBaseAddress(focusedSector) + FLASH_SECTOR_LENGTH);
  }
  
  /**
   * Retreive the earliest available write address in a given sector.
   * @return the write address of the sector relative to 0x0
   */
  command uint32_t SectorMap.getSectorWriteAddress(flashsector *focusedSector) {
    return call Util.convertPagesToBytes(focusedSector->writePage) + call SectorMap.getSectorBaseAddress(focusedSector);
  }
  
  /**
   * Retrieve the base address of the flashsector relative to 0x0.
   * @return the relative address of the flashsector from 0x0
   */
  command uint32_t SectorMap.getSectorBaseAddress(flashsector *focusedSector) {
    return focusedSector->index * FLASH_SECTOR_LENGTH;
  }
  
  /**
   * Obtain the remaining free bytes in a specified
   * flashsector
   * @param focusedSector - the flashsector to find the free bytes in
   * @return the number of free page bytes in the flashsector
   */
  command uint32_t SectorMap.bytesRemaining(flashsector *focusedSector) {
    if(focusedSector->writePage < FLASH_PAGES_PER_SECTOR) {
      return FLASH_SECTOR_LENGTH - call Util.convertPagesToBytes(focusedSector->writePage);
      
    } else {
      return 0;
    }
  }

  /**
   * Obtain the total amount of free space on the flash.
   * @return the total amount of free space on the flash
   */
  command uint32_t SectorMap.getFreeSpace() {
    uint8_t sectorIndex;
    uint32_t totalSpace;
    
    sectorIndex = 0;
    totalSpace = 0;

    // This performs a size estimate of the biggest single file we can create on flash.
    for(sectorIndex = FLASH_FIRST_BLACKBOOK_SECTOR; sectorIndex <= FLASH_LAST_BLACKBOOK_SECTOR; sectorIndex++) {
      if(!flashSectors[sectorIndex].inUse && flashSectors[sectorIndex].writePage < FLASH_PAGES_PER_SECTOR) {
        totalSpace += call SectorMap.bytesRemaining(&flashSectors[sectorIndex]);
        totalSpace -= sizeof(nodemeta);
      }
    }
    
    if(totalSpace > 0) {
      totalSpace -= sizeof(filemeta);
    }
    
    return totalSpace;
  }

  /**
   * The sector was erased by the garbage collector
   * @param sectorIndex - the sector erased
   */
  command void SectorMap.eraseComplete(uint8_t sectorIndex) {
    flashSectors[sectorIndex].writePage = 0;
    flashSectors[sectorIndex].totalNodes = 0;
    flashSectors[sectorIndex].inUse = FALSE;
  } 
  
  /** 
   * Reserve a sector for writing
   * @param *focusedSector pointer to the sector we want to reserve
   */
  command void SectorMap.reserveSector(flashsector *focusedSector) {
    focusedSector->inUse = TRUE;
  }
  
  /**
   * Free a sector that was reserved for writing
   * @param *focusedSector pointer to the sector we want to free
   */
  command void SectorMap.freeSector(flashsector *focusedSector) {
    focusedSector->inUse = FALSE;
  }
}

