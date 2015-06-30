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
 * Blackbook Dictionary Boot Module
 *
 *  1. Start at the first valid sector of flash and 
 *     read nodes, documenting, deleting, etc.
 *
 *  2. Repeat step 1 for every sector.
 *
 *  3. After all nodes on all sectors have been accounted for,
 *     link the files and nodes together in the NodeBooter.
 * 
 *  4. Boot complete.
 *
 * @author David Moss - dmm@rincon.com
 */
 
module BBootDictionaryM {
  provides {
    interface BBoot;
  }
  uses {
    interface GenericCrc; 
    interface FlashBridge;
    interface SectorMap;
    interface NodeBooter;
    interface NodeShop;
    interface NodeMap;
    interface State as CommandState;
    interface State as BlackbookState;
    interface Util;
  }
}

implementation {

  /** The current address we're scanning */
  uint32_t currentAddress;
  
  /** The current nodemeta being read from flash */
  nodemeta currentNodeMeta;
  
  /** The currently allocated flashnode from the NodeBooter */
  flashnode *currentNode;
  
  /** The currently allocated file from the NodeBooter */
  file *currentFile;
  
  /** The current sector index we're working with */
  uint8_t currentIndex;

  /** The current filename readd from flash */
  filename currentFilename;
  
  
  /** Command States */
  enum {
    S_IDLE_TWO = 0,
    S_READ_NODEMETA,
    S_READ_FILEMETA,
  };
  
  /***************** Prototypes ****************/
  /** Parse the newly read flashnode */
  task void parseCurrentNode();
  
  /** Allocate a new flashnode and read it in from the address "currentAddress" */
  task void getNewNode();
  
  /** Allocate a new file and read it in from the address "currentAddress" */
  task void getNewFile();
  
  /** Read the nodemeta for the flashnode at the address "currentAddress" */
  task void readNodeMeta();
  
  /** Read the filemeta for the flashnode at the address "currentAddress" */
  task void readFileMeta();
 
  /** Continue parsing through the flash */
  task void continueParsing();



  /***************** BBoot Commands ****************/
  /**
   * @return TRUE if the file system has booted
   */
  command bool BBoot.isBooted() {
    return call BlackbookState.getState() != S_BOOT_BUSY;
  }
  
  /***************** FlashBridge Events ****************/
  /**
   * Signaled when the flash is ready to be used
   * @param result - SUCCESS if we can use the flash.
   */
  event void FlashBridge.ready(result_t result) {
    if(!result) {
      return;
    }
    
    call BlackbookState.forceState(S_BOOT_BUSY);
    currentIndex = FLASH_FIRST_BLACKBOOK_SECTOR;
    post continueParsing();
  }
  
  /**
   * Read is complete
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  event void FlashBridge.readDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    if(call CommandState.getState() == S_READ_NODEMETA) {
      if(!result) {
        post readNodeMeta();
        return;
      }

      if(currentNodeMeta.magicNumber != META_INVALID && currentNodeMeta.fileElement == 0) {
        post getNewFile();
        return;
        
      } else {
        post parseCurrentNode(); 
      }
      
    } else if(call CommandState.getState() == S_READ_FILEMETA) {
      if(!result) {
        post readFileMeta();
        return;
      }
      
      currentFile->filenameCrc = call GenericCrc.crc16(0, &currentFilename, sizeof(filename));
      currentFile->firstNode = currentNode;
      
      post parseCurrentNode();
    }
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
   * Erase is complete
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  event void FlashBridge.eraseDone(uint16_t sector, result_t result) {
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

  
  /***************** NodeShop Events ****************/
  /** 
   * The node's metadata was written to flash
   * @param focusedNode - the flashnode that metadata was written for
   * @param result - SUCCESS if it was written
   */
  event void NodeShop.metaWritten(flashnode *focusedNode, result_t result) {
  }
  
  /**
   * The filename was retrieved from flash
   * @param focusedFile - the file that we obtained the filename for
   * @param *name - pointer to where the filename was stored
   * @param result - SUCCESS if the filename was retrieved
   */
  event void NodeShop.filenameRetrieved(file *focusedFile, filename *name, result_t result) {
  }
  
  /**
   * A flashnode was deleted from flash by marking its magic number
   * invalid in the metadata.
   * @param focusedNode - the flashnode that was deleted.
   * @param result - SUCCESS if the flashnode was deleted successfully.
   */
  event void NodeShop.metaDeleted(flashnode *focusedNode, result_t result) {
    currentNode->state = NODE_EMPTY;
    if(currentFile != NULL) {
      currentFile->state = FILE_EMPTY;   
    }
    post continueParsing();
  }
 
  /**
   * A crc was calculated from flashnode data on flash
   * @param dataCrc - the crc of the data read from the flashnode on flash.
   * @param result - SUCCESS if the crc is valid
   */
  event void NodeShop.crcCalculated(uint16_t dataCrc, result_t result) {
  }
  
  /***************** Tasks ****************/
  /**
   * Parse the current flashnode and nodemeta
   */
  task void parseCurrentNode() {
    currentNode->fileElement = currentNodeMeta.fileElement;
    currentNode->filenameCrc = currentNodeMeta.filenameCrc;
    currentNode->reserveLength = currentNodeMeta.reserveLength;

    // Dictionary files use all their reserved length:
    currentNode->dataLength = currentNodeMeta.reserveLength;
    
    if(currentNodeMeta.magicNumber == META_EMPTY) {
      // Advance to the next sector.
      currentNode->state = NODE_EMPTY;
      if(currentFile != NULL) {
        currentFile->state = FILE_EMPTY;
      }
      
      currentIndex++;
      post continueParsing();
      return;
      
    } else if(currentNodeMeta.magicNumber == META_CONSTRUCTING) {
      // This flashnode must be deleted.
      currentNode->state = NODE_IDLE;
      call SectorMap.documentNode(currentNode);
      call NodeShop.deleteNode(currentNode);
      return;
        
    } else if(currentNodeMeta.magicNumber == META_VALID) {
      currentNode->state = NODE_IDLE;
      if(currentFile != NULL) {
        currentFile->state = FILE_IDLE;
      }
      
      if(call NodeMap.hasDuplicate(currentNode)) {
        call NodeShop.deleteNode(currentNode);
        return; 
      } else {
        call SectorMap.documentNode(currentNode);
      }
      
    } else if(currentNodeMeta.magicNumber == META_INVALID) {
      currentNode->state = NODE_DELETED;
      if(currentFile != NULL) {
        currentFile->state = FILE_EMPTY;
      }
      call SectorMap.documentNode(currentNode);
      currentNode->state = NODE_EMPTY;
      
    } else {
      // Garbage found. Document, delete, and advance to the next page.
      currentNode->state = NODE_DELETED;
      currentNode->flashAddress = currentAddress;
      currentNode->reserveLength = 1;
      currentNode->dataLength = 1;
      call SectorMap.documentNode(currentNode);
      currentNode->state = NODE_EMPTY;
      if(currentFile != NULL) {
        currentFile->state = FILE_EMPTY;
      }
    }
    
    post continueParsing();
  }
  
  
  /**
   * Controls the state of the boot loop
   * and verifies the currentAddress is within range
   */
  task void continueParsing() {
    if(currentIndex <= FLASH_LAST_BLACKBOOK_SECTOR) {
      // Ensure the current address is not at the next sector's base address
      if((currentAddress = call SectorMap.getSectorWriteAddress(call SectorMap.getSectorAtVolume(currentIndex))) 
          < call Util.getNextSectorAddress(call SectorMap.getSectorBaseAddress(call SectorMap.getSectorAtVolume(currentIndex)))) {
        post getNewNode();
      
      } else {
        // Reached the end of the sector
        currentIndex++;
        post continueParsing();
      }
      
    } else {
      // Done loading nodes. Link, and finish booting.  Dictionary-only functionality
      // requires no checkpoint
      call NodeBooter.link();
      call CommandState.toIdle();
      call BlackbookState.toIdle();
      signal BBoot.booted(call NodeMap.getTotalNodes(), call NodeMap.getTotalFiles(), SUCCESS);
    }
  }
  
  /**
   * Allocate a new flashnode and read it in from the address "currentAddress"
   */
  task void getNewNode() {
    currentFile = NULL;
    if((currentNode = call NodeBooter.requestAddNode()) == NULL) {
      // There aren't enough nodes in our NodeMap. Do not change
      //  the BlackbookState to prevent the file system from being
      //  further corrupted.
      signal BBoot.booted(call NodeMap.getTotalNodes(), call NodeMap.getTotalFiles(), FAIL);
      return;
    }
   
    post readNodeMeta();
  }

  
  /**
   * Allocate a new file and read it in from the address "currentAddress"
   */
  task void getNewFile() {
    if((currentFile = call NodeBooter.requestAddFile()) == NULL) {
      // Massive error: There aren't enough nodes in our NodeMap
      //  to supply the amount of nodes on flash. Do not change
      //  the BlackbookState to prevent the file system from being
      //  corrupted.
      signal BBoot.booted(call NodeMap.getTotalNodes(), call NodeMap.getTotalFiles(), FAIL);
      return;
    }
    
    currentFile->firstNode = currentNode;
    post readFileMeta(); 
  }
  
  /**
   * Read the nodemeta from the flashnode at the flash address "currentAddress"
   */
  task void readNodeMeta() {
    call CommandState.forceState(S_READ_NODEMETA);
    currentNode->flashAddress = currentAddress;
    if(!call FlashBridge.read(currentAddress, &currentNodeMeta, sizeof(currentNodeMeta))) {
      post readNodeMeta();
    }
  }
  
  /** 
   * Read the filemeta for the flashnode at the flash address "currentAddress"
   * into the currentFile
   */
  task void readFileMeta() {
    call CommandState.forceState(S_READ_FILEMETA);
    if(!call FlashBridge.read(currentAddress + sizeof(nodemeta), &currentFilename, sizeof(filemeta))) {
      post readFileMeta();
    }
  }
}



