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
 * Blackbook NodeShop Configuration
 *
 * NodeShop writes metadata for nodes and files to flash.
 *
 * @author David Moss (dmm@rincon.com)
 */
 
includes Blackbook;

module NodeShopM {
  provides {
    interface NodeShop;
  }
  
  uses {
    interface NodeMap;
    interface Util;
    interface State;
    interface SectorMap;
    interface FlashBridge;
  }
}

implementation {

  /** Pointer to the current flashnode */
  flashnode *currentNode;
  
  /** Pointer to the current file */
  file *currentFile;
  
  /** Filename pointer */
  filename *currentFilename;
  
  /** Node meta to write to flash */
  nodemeta currentNodeMeta;
  
  
  enum { 
    S_IDLE = 0,
    S_WRITE_NODEMETA,
    S_WRITE_FILEMETA,
    S_NODEMETA_DELETE,
    S_GET_FILENAME,
    S_CRC,
  };
  
  
  /***************** Prototypes ****************/
  /** Delete the current flashnode */
  task void deleteMyNode();
  
  /** Write the nodemeta for the current flashnode to flash */
  task void writeNodemeta();
  
  /** Write the filemeta for the current flashnode to flash */
  task void writeFilemeta();
    
  /** Flush all changes to flash */
  task void flush();
  
  /** Get the CRC of the data in the current flashnode */
  task void getMyNodeCrc();
  
  /** Signal completion for the current state */ 
  task void signalDone(); 
  
  /** Read the filename of a file from flash */
  task void readFilename();
 
  /***************** NodeShop Commands ****************/
  /**
   * Write the nodemeta to flash for the given node
   * @param focusedFile - the file
   * @param focusedNode - the flashnode to write the nodemeta for
   * @param name - pointer to the filename
   */
  command result_t NodeShop.writeNodemeta(file *focusedFile, flashnode *focusedNode, filename *name) {
    if(!call State.requestState(S_WRITE_NODEMETA)) {
      return FAIL;
    }
  
    currentNode = focusedNode;
    currentFile = focusedFile;
    currentFilename = name;
    
    currentNodeMeta.filenameCrc = currentNode->filenameCrc;
    currentNodeMeta.reserveLength = currentNode->reserveLength;
    currentNodeMeta.fileElement = currentNode->fileElement;
    
    if(focusedNode->state == NODE_CONSTRUCTING) {
      currentNodeMeta.magicNumber = META_CONSTRUCTING;
    } else {
      currentNodeMeta.magicNumber = META_VALID;
    }
    
    call SectorMap.freeSector(call SectorMap.getSectorAtAddress(currentNode->flashAddress));
    
    post writeNodemeta();
    
    return SUCCESS;
  }

  /**
   * Delete a flashnode on flash. This will not erase the
   * data from flash, but it will simply mark the magic
   * number of the flashnode to make it invalid.
   * 
   * After the command is called and executed, a metaDeleted
   * event will be signaled.
   *
   * @return SUCCESS if the magic number will be marked
   */
  command result_t NodeShop.deleteNode(flashnode *focusedNode) { 
    if(!call State.requestState(S_NODEMETA_DELETE)) {
      return FAIL;
    }

    currentNode = focusedNode;

    post deleteMyNode();
    return SUCCESS;
  }
  
  /**
   * Get the CRC of a flashnode on flash.
   *
   * After the command is called and executed, a crcCalculated
   * event will be signaled.
   *
   * @param focusedNode - the flashnode to read and calculate a CRC for
   * @param focusedFile - the file belonging to the node
   * @return SUCCESS if the CRC will be calculated.
   */
  command result_t NodeShop.getCrc(flashnode *focusedNode, file *focusedFile) {
    if(!call State.requestState(S_CRC)) {
      return FAIL;
    }
    
    currentNode = focusedNode;
    currentFile = focusedFile;
    
    post getMyNodeCrc();
    return SUCCESS;
  }

  /**
   * Get the filename for a file
   * @param focusedFile - the file to obtain the filename for
   * @param *name - pointer to store the filename
   */
  command result_t NodeShop.getFilename(file *focusedFile, filename *name) {
    if(!call State.requestState(S_GET_FILENAME)) {
      return FAIL;
    }
    
    currentFile = focusedFile;
    currentFilename = name;
    
    post readFilename();
    return SUCCESS;
  }
  
  /***************** FlashBridge Events ****************/
  /**
   * Write is complete
   * @param addr - the address to write to
   * @param *buf - the buffer to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  event void FlashBridge.writeDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    if(call State.getState() == S_WRITE_NODEMETA) {

      if(currentFile != NULL) {
        if(currentFile->firstNode == currentNode) {
          post writeFilemeta();
          return; 
        }
      }
      
      if(currentNode->state != NODE_CONSTRUCTING) {
        currentNode->state = NODE_VALID;
      }
      call SectorMap.documentNode(currentNode);
      
    } else if(call State.getState() == S_WRITE_FILEMETA) {      
      if(currentNode->state != NODE_CONSTRUCTING) {
        currentNode->state = NODE_VALID;
      }
      call SectorMap.documentNode(currentNode);

    } else if(call State.getState() == S_NODEMETA_DELETE) {
      call SectorMap.removeNode(currentNode);
      currentNode->state = NODE_DELETED;

    }
    
    post flush();
    return;
  }
  
  /**
   * Flush is complete
   * @param result - SUCCESS if the flash was flushed
   */
  event void FlashBridge.flushDone(result_t result) {
    post signalDone();
  }
  
  /**
   * CRC-16 is computed
   * @param crc - the computed CRC.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  event void FlashBridge.crcDone(uint16_t calculatedCrc, uint32_t addr, uint32_t len, result_t result) {
    call State.toIdle();
    signal NodeShop.crcCalculated(calculatedCrc, result);
  }
  
  /**
   * Read is complete
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  event void FlashBridge.readDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    post signalDone();
  }
  
  
  /**
   * Erase is complete
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  event void FlashBridge.eraseDone(uint16_t sector, result_t result) {
  }
  
  
  /**
   * Signaled when the flash is ready to be used
   * @param result - SUCCESS if we can use the flash.
   */
  event void FlashBridge.ready(result_t result) {
  }
  


  /***************** Tasks ****************/
  /**
   * Write the magic number to flash to invalidate "currentNode"
   */
  task void deleteMyNode() {
    currentNodeMeta.magicNumber = META_INVALID;
    
    // Here we only want to write the new magicNumber to flash
    // Very nodemeta dependant.
    if(!call FlashBridge.write(currentNode->flashAddress, &currentNodeMeta.magicNumber, sizeof(currentNodeMeta.magicNumber))) {
      post deleteMyNode();
    }
  }
  
  /**
   * Write the nodemeta to flash
   */
  task void writeNodemeta() {
    if(!call FlashBridge.write(currentNode->flashAddress, &currentNodeMeta, sizeof(nodemeta))) {
      post writeNodemeta();
    }
  }

  /**
   * Write the filemeta to "currentNode"
   */
  task void writeFilemeta() {
    call State.forceState(S_WRITE_FILEMETA);
    if(!call FlashBridge.write(currentNode->flashAddress + sizeof(nodemeta), currentFilename, sizeof(filemeta))) {
      post writeFilemeta();
    }
  }
  
  /**
   * Get the CRC of all the data in the current node
   * It is assumed that currentNodeMeta.fileElement 
   * contains the element number of the current node.
   */
  task void getMyNodeCrc() {
    uint32_t dataStartAddress = currentNode->flashAddress + sizeof(nodemeta);
    if(currentFile->firstNode == currentNode) {
      dataStartAddress += sizeof(filemeta);
    }
    
    if(!call FlashBridge.crc(dataStartAddress, currentNode->dataLength)) {
      post getMyNodeCrc();
    }
  }
  
  /**
   * Read the currentFile's filename from flash
   */
  task void readFilename() {
    if(!call FlashBridge.read(currentFile->firstNode->flashAddress + sizeof(nodemeta), currentFilename, sizeof(filename))) {
      post readFilename();
    }
  }
  
  /** 
   * Flush changes to flash 
   */
  task void flush() {
    if(!call FlashBridge.flush()) {
      post flush();
    }
  }
  
  
  /** 
   * Signal task completion after
   * everything is set and finished and checkpointed.
   */
  task void signalDone() {
    uint8_t state = call State.getState();
    call State.toIdle();
    
    switch(state) {
      case S_WRITE_NODEMETA:
      case S_WRITE_FILEMETA:
        signal NodeShop.metaWritten(currentNode, SUCCESS);
        break;
        
      case S_NODEMETA_DELETE:
        signal NodeShop.metaDeleted(currentNode, SUCCESS);
        break;

      case S_GET_FILENAME:
        signal NodeShop.filenameRetrieved(currentFile, currentFilename, SUCCESS);
        break;
        
      default:
    }
  }
}

