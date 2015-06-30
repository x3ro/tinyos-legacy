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
 * Blackbook File Write Allocator
 * This component allows you to open a file with the given name and minimum
 * size, and the given type for writing.  If the file already exists,
 * it will be opened and if needed, more space will be allocated to the file
 * to meet the new minimum space requirements.  If the file doesn't exist,
 * it will be allocated in both the NodeMap and on flash and created.
 * In the end, if enough space exists and the file is created successfully,
 * the flashnode that can be written to in the file will be passed back.
 * When whatever component fills that flashnode completely and wants to keep
 * writing, it will need to load up the next flashnode in the file if it exists.
 * @author David Moss - dmm@rincon.com
 */
 
module WriteAllocM {
  provides {
    interface WriteAlloc;
  }
  
  uses {
    interface SectorMap;
    interface NodeMap;
    interface NodeBooter;
    interface NodeShop;
    interface State;
    interface BClean;
    interface Util;
  }
}

implementation {

  /** The file we're trying to open for writing */
  file *currentFile;
  
  /** The flashnode we're working on */
  flashnode *currentNode;
  
  /** The current sector we're looking at */
  flashsector *currentSector;
  
  /** Filename buffer */
  filename currentFilename;
  
  /** The minimum size to create the file */
  uint32_t minSize;
  
  /** The total size allocated to the file */
  uint32_t totalSize;
  
  /** Result to finish with */
  result_t finishResult;
  
  /** TRUE if this open write file is to be deleted if the mote reboots */
  bool constructing;
  
  /** TRUE if we are to only allocate one flashnode for the file */
  bool onlyOneNode;
  
  /** The element number to set for the next allocated flashnode */
  uint8_t nextElement;
  
  /** TRUE if BClean was called during the current allocation attempt */
  bool cleaned;
  
  enum {
    S_IDLE = 0,
    S_OPEN,
  };

  /***************** Prototypes ****************/
  /** Set the 'finishResult' variable and call finish to signal completion */
  task void finish();
  
  /** Allocate space on flash for the currentNode */
  task void allocate();
  
  
  /** Allocate and test a single sector to the currentNode */
  result_t allocateOneSector();
  
  /** Function that deconstructs the file, sets the finishResult to fail, and completes */
  void fail();
  
  /** Deconstruct the current file */
  void closeCurrentFile();
 
  /** Find and unfinalize (if necessary) the first writable flashnode of a file */
  void getWritableNode(); 
  
  
  /***************** WriteAlloc Commands ****************/
  /**
   * Open a file for writing
   * Create a file with the given name and the specified minimum length
   * @return SUCCESS if the file will be opened for writing.
   */
  command result_t WriteAlloc.openForWriting(char *fileName, uint32_t minimumSize, bool forceConstruction, bool oneNode) {
    flashnode *lastNode;
    if(!call State.requestState(S_OPEN)) {
      return FAIL;
    }

    cleaned = FALSE;
    minSize = minimumSize;
    totalSize = 0;
    constructing = forceConstruction;
    onlyOneNode = oneNode;
    nextElement = 0;
       
    call Util.filenameCpy(&currentFilename, fileName);
    currentFile = call NodeMap.getFile(&currentFilename);
    
    if(currentFile == NULL || forceConstruction) {
      // The file does not exist and needs to be created
      if((currentFile = call NodeBooter.requestAddFile()) == NULL) {
        call State.toIdle();
        return FAIL;
      }
      
      if((currentNode = call NodeBooter.requestAddNode()) == NULL) {
        call State.toIdle();
        return FAIL;
      }
      
      currentFile->state = FILE_TEMPORARY;
      currentFile->filenameCrc = call Util.filenameCrc(&currentFilename);
      currentFile->firstNode = currentNode;

      currentNode->filenameCrc = currentFile->filenameCrc;
      currentNode->state = NODE_TEMPORARY;
      
      post allocate();
      return SUCCESS;
      
    } else {
      // The file already exists.

      if(currentFile->state != FILE_IDLE) {
        call State.toIdle();
        return FAIL;
      }

      currentNode = currentFile->firstNode;

      // Traverse through each existing flashnode of the file.
      do {
        if(oneNode) {
          // This is a dictionary file, add up its reserveLength
          // because the dataLength isn't set when Checkpoint opens this up
          // during boot
          totalSize += currentNode->reserveLength;  
        } else {
          totalSize += currentNode->dataLength;
          minSize -= currentNode->dataLength;
        }
        
        lastNode = currentNode;
        nextElement++;
      } while((currentNode = currentNode->nextNode) != NULL);
      
      // 'lastNode' now contains the last flashnode of the file.
      // 'currentNode' now contains NULL
      
      if((totalSize < minSize || lastNode->state == NODE_LOCKED) && !oneNode) {
        
        // Allocate more nodes to this file.
        if((currentNode = call NodeBooter.requestAddNode()) == NULL) {
          // Can't - we're out of nodes in our NodeMap.
          closeCurrentFile();
          return FAIL;
          
        } else {
          lastNode->nextNode = currentNode;
          currentNode->filenameCrc = currentFile->filenameCrc;
          currentNode->state = NODE_TEMPORARY;
          post allocate();
          return SUCCESS;
        }
        
      } else {
        // Enough reserve space exists already, hand it over.
        getWritableNode();
        return SUCCESS;
        
      }
    } 
    
    return SUCCESS;
  }
  
  /***************** NodeShop Events ****************/
  /** 
   * The node's metadata was written to flash
   * @param focusedNode - the flashnode that metadata was written for
   * @param result - SUCCESS if it was written
   */
  event void NodeShop.metaWritten(flashnode *focusedNode, result_t result) {
    if(call State.getState() == S_OPEN) {
      finishResult = SUCCESS;
      post finish();
    }
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
  }
 
  /**
   * A crc was calculated from flashnode data on flash
   * @param dataCrc - the crc of the data read from the flashnode on flash.
   * @param result - SUCCESS if the crc is valid
   */
  event void NodeShop.crcCalculated(uint16_t dataCrc, result_t result) {
  }
  
  
  /***************** BClean Tasks ****************/ 
  /**
   * Garbage Collection is complete
   * TODO This works fine, but notice how the code is
   *  similar to other areas of code in this file.
   *  To polish it off, maybe think about combining all this
   *  code into one function.
   * @return SUCCESS if any sectors were erased.
   */
  event void BClean.gcDone(result_t result) {
    flashnode *lastGoodNode;
    if(call State.getState() == S_OPEN) {
      if(!result) {
        fail();
        return;
      }
      
      cleaned = TRUE;
      
      // 1. Erase all the current temporary nodes
      //    and find the last non-temporary flashnode of the file
      currentNode = currentFile->firstNode;
      lastGoodNode = NULL;
      totalSize = 0;
      nextElement = 0;
      
      do {
        if(currentNode->state == NODE_TEMPORARY) {
          call SectorMap.freeSector(call SectorMap.getSectorAtAddress(currentNode->flashAddress));
          currentNode->state = NODE_EMPTY;
          
        } else {
          if(onlyOneNode) {
            // This is a dictionary file, add up its reserveLength
            // because the dataLength isn't set when Checkpoint opens this up
            // during boot
            totalSize += currentNode->reserveLength;  
          
          } else {
            totalSize += currentNode->dataLength;
            minSize -= currentNode->dataLength;
          }
          
          nextElement++;
          lastGoodNode = currentNode;
        }
      } while((currentNode = currentNode->nextNode) != NULL);
    
      
      // 2. Allocate a flashnode to the file
      if((currentNode = call NodeBooter.requestAddNode()) == NULL) {
        fail();
        return;
      }
      
      // 3. Sew it into our linked list
      if(lastGoodNode == NULL) {
        currentFile->firstNode = currentNode;
      } else {
        lastGoodNode->nextNode = currentNode;
      }
      
      // 4. Setup parameters and re-attempt allocation
      currentNode->filenameCrc = currentFile->filenameCrc;
      currentNode->state = NODE_TEMPORARY;
      
      post allocate();
    }
  }
  
  event void BClean.erasing() {
  }
  
  /***************** Tasks ****************/
  /**
   * A flashnode has already been reserved in the NodeMap,
   * this task will allocate space on flash for the node.
   */
  task void allocate() {
    if(!allocateOneSector()) {
      if(!cleaned) {
        call BClean.gc();
      } else {
        fail();
      }
    }
  }
  
  /**
   * Finish with the result stored in 'finishResult'
   */
  task void finish() {
    call State.toIdle(); 
    
    if(onlyOneNode) {
      // Dictionary nodes only use one node, and their dataLength is always full.
      currentNode->dataLength = currentNode->reserveLength;
    }
    
    totalSize += currentNode->reserveLength;

    // The totalSize here is actually the append address in the file,
    // if we're finishing successfully.
    signal WriteAlloc.openedForWriting(currentFile, currentNode, totalSize, finishResult);
  }

  
  /***************** Functions ****************/
  /**
   * This function will allocate one sector for the currentNode
   * and determine if we need to allocate more sectors
   * for binary files.  When enough space is allocated, it finishes
   * up and returns the first writable node.  If it can't find enough
   * space, it returns FAIL, which will either run the garbage collector
   * or stop the allocation process.
   */
  result_t allocateOneSector() {
    flashnode *lastNode;
    uint8_t metaSize = sizeof(nodemeta);
    
    
    if((currentSector = call SectorMap.nextLargestIdleSector()) == NULL) {
      // No free sectors
      return FAIL;
      
    } else {
      call SectorMap.reserveSector(currentSector);
      currentNode->flashAddress = call SectorMap.getSectorWriteAddress(currentSector);
      currentNode->dataLength = 0;
      currentNode->dataCrc = 0;
      currentNode->fileElement = nextElement;
      nextElement++;
      
      if(currentFile->firstNode == currentNode) {
        metaSize += sizeof(filemeta);
      }
      
      currentNode->reserveLength = call SectorMap.bytesRemaining(currentSector);
      
      if(call Util.convertBytesToPages(currentNode->reserveLength) > call Util.convertBytesToPages(minSize + metaSize - totalSize)) {
        // Too much space was allocated from the sector, back it off
        currentNode->reserveLength = call Util.convertPagesToBytes(call Util.convertBytesToPages(minSize + metaSize - totalSize));
      }

      currentNode->reserveLength -= metaSize;
      totalSize += currentNode->reserveLength;
      
      if(totalSize < minSize) {
        // Need to allocate more space
        lastNode = currentNode;
        if(onlyOneNode || (currentNode = call NodeBooter.requestAddNode()) == NULL) {
          // We're out of nodes in our NodeMap, or we're trying to
          // create a dictionary file that requires a single node.
          fail();
      
        } else {
          lastNode->nextNode = currentNode;
          currentNode->filenameCrc = currentFile->filenameCrc;
          currentNode->state = NODE_TEMPORARY;
          post allocate();
          return SUCCESS;
          
        }
      
      } else {
        // Enough space is allocated - unfinalize the first temporary node
        getWritableNode();
      }
        
      return SUCCESS;
    }
  }
  
  /**
   * Find the first writable flashnode of the file. If it needs
   * to be unfinalized, unfinalize it.  Finish up by
   * signaling completion with the first writable unfinalized node.
   * The app will write to the flashnode after the node's dataLength
   * location.
   */
  void getWritableNode() {
    totalSize = 0;  // here, totalSize is used in the signal to reflect the append address 
    currentNode = currentFile->firstNode;
    currentFile->state = FILE_WRITING;
    
    do {
      totalSize += currentNode->dataLength;
      
      // Traverse through each existing flashnode of the file.
      // Find the first writable node.
      // Checkpoint files, on boot, will still be in state NODE_BOOTING,
      // So change them over.
      if(currentNode->state == NODE_VALID || currentNode->state == NODE_BOOTING) {
        currentNode->state = NODE_VALID;
        finishResult = SUCCESS;
        post finish();
        return;
        
      } else if(currentNode->state == NODE_TEMPORARY) {
        if(constructing) {
          currentNode->state = NODE_CONSTRUCTING;
        }
        
        call NodeShop.writeNodemeta(currentFile, currentNode, &currentFilename);
        return;
        
      }
    } while((currentNode = currentNode->nextNode) != NULL);
    
    fail();  // Something bad happened. We should have succeeded.
  }
  
  
  /**
   * This operation failed.
   */
  void fail() {
    closeCurrentFile();
    finishResult = FAIL;
    post finish();
  }
  
  /**
   * Deallocate and close all nodes for the current
   * binary file - this happens before any interaction
   * outside of WriteAlloc so no changes need to be
   * made to flash.
   */
  void closeCurrentFile() {
    if(currentFile->state == FILE_TEMPORARY) {
      currentFile->state = FILE_EMPTY;
      
    } else if(currentFile->state == FILE_WRITING) {
      currentFile->state = FILE_IDLE;
    }
    
    currentNode = currentFile->firstNode;
    
    do {
      if(currentNode->state == NODE_TEMPORARY) {
        call SectorMap.freeSector(call SectorMap.getSectorAtAddress(currentNode->flashAddress));
        currentNode->state = NODE_EMPTY;
      }
    } while((currentNode = currentNode->nextNode) != NULL);
  }
}

