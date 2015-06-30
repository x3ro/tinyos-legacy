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
 * This module provides the ability to read and write to files
 * on flash. Although random read/write access is technically possible,
 * it assumes serial write access to prevent the creation of dangling node.
 * Random read access isn't a problem though.
 *
 * Pass in a file and an address you want to read/write from that file,
 * and this module will put together the nodes that are required to
 * access that information.
 *
 * @author David Moss (dmm@rincon.com)
 */
 
includes Blackbook;

module FileioM {
  provides {
    interface Fileio;
  }
  
  uses {
    interface FlashBridge;
    interface GenericCrc;
    interface NodeMap;
    interface NodeShop;
    interface State;
  }
}

implementation {

  /** Offset to read/write in the flashnode */
  uint16_t offset;
  
  /** The flashnode to interact with */
  flashnode *currentNode;
  
  /** The current file we're interacting with */
  file *currentFile;
  
  /** Pointer to the buffer to read or store data */
  void *currentBuffer;
  
  /** The total amount of data to read or write */ 
  uint32_t currentTotal;
  
  /** The total amount of bytes read or written */
  uint32_t totalComplete;
  
  /** The amount of data that we are currently reading or writting */
  uint16_t currentAmount;
  
  /** The actual address we're interacting with on flash */
  uint32_t actualAddress;  
  
  enum  {
    S_IDLE = 0,
    S_READING,
    S_WRITING,
    S_FLUSHING,
  };
  
  /***************** Prototypes ****************/
  task void transaction();
  task void writeNextNode();
  task void write();
  task void read();
  
  
  void ioInit(file *ioFile, uint32_t fileAddress);
  void finish(result_t result);
  bool isWriting();
  void writeCurrentNodeMeta();
  
  /***************** Fileio Commands ****************/
  /**
   * Write data to the flashnode belonging to the given file
   * at the given address in the file
   * @param currentFile - the file to write to
   * @param fileAddress - the address to write to in the file
   * @param *data - the data to write
   * @param total - the total amount of data to write
   * @return SUCCESS if the data will be written
   */
  command result_t Fileio.writeData(file *ioFile, uint32_t fileAddress, void *data, uint32_t total) {
    if(!call State.requestState(S_WRITING)) {
      return FAIL;
    }
    
    currentBuffer = data;
    currentTotal = total;
    ioInit(ioFile, fileAddress);
    return SUCCESS;
  }
  
  /**
   * Read data from the flashnode belonging to the given file
   * at the given address in the file
   * @param currentFile - the file to read from
   * @param fileAddress - the address to read from in the file
   * @param *data - pointer to the buffer to store the data in
   * @param total - the total amount of data to read
   */
  command result_t Fileio.readData(file *ioFile, uint32_t fileAddress, void *data, uint32_t total) {
    if(!call State.requestState(S_READING)) {
      return FAIL;
    }
    
    currentBuffer = data;
    currentTotal = total;
    ioInit(ioFile, fileAddress);
    return SUCCESS;
  }

  /**
   * Flush any written data to flash 
   * @return SUCCESS if the data is flushed, and an event will be signaled.
   */
  command result_t Fileio.flushData() {
    if(!call State.requestState(S_FLUSHING)) {
      return FAIL;
    }
    
    return call FlashBridge.flush();
  }
    

  /***************** FlashBridge Events ****************/
  /**
   * Read is complete
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  event void FlashBridge.readDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    totalComplete += len;
    offset += len;
    post transaction();
  }
  
  /**
   * Write is complete
   * @param addr - the address to write to
   * @param *buf - the buffer to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  event void FlashBridge.writeDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    currentNode->dataLength += len;
    totalComplete += len;
    offset += len;
    post transaction();
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
    if(call State.getState() == S_FLUSHING) {
      call State.toIdle();
      signal Fileio.flushDone(result);
    }
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

  /**
   * Signaled when the flash is ready to be used
   * @param result - SUCCESS if we can use the flash.
   */
  event void FlashBridge.ready(result_t result) {
  }
  
  
  /***************** NodeShop Events ****************/
  /** 
   * The node's metadata was written to flash
   * @param focusedNode - the flashnode that metadata was written for
   * @param result - SUCCESS if it was written
   */
  event void NodeShop.metaWritten(flashnode *focusedNode, result_t result) {
    if(isWriting()) {
      post transaction();
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

  
  /***************** Tasks ****************/
  /**
   * Calculate and perform the transaction
   */
  task void transaction() {
    uint16_t nodeLength;
    
    if(totalComplete < currentTotal) {
      // More data to go
      if(isWriting()) {
        nodeLength = currentNode->reserveLength;
      } else {
        nodeLength = currentNode->dataLength;
      }
      
      currentAmount = currentTotal - totalComplete;
      if(nodeLength - offset < currentAmount) {
        currentAmount = nodeLength - offset;
      }
      
      if(currentAmount == 0) {
        // We're at the end of this node
        if(currentNode->nextNode != NULL) {
          offset = 0;
          
          if(isWriting()) {
            post writeNextNode();
            return;
            
          } else {
            if((currentNode = currentNode->nextNode) == NULL) {
              finish(SUCCESS);
            
            } else {
              post transaction();
            }
            
            return;
          }
          
        } else {
          // EOF
          finish(SUCCESS);
          return;
        }
      }
      
      
      actualAddress = currentNode->flashAddress + sizeof(nodemeta) + offset;
      if(currentFile->firstNode == currentNode) {
        actualAddress += sizeof(filemeta);
      }
      
      if(isWriting()) {
        post write();
        
      } else { 
        post read();
      }
        
    } else {
      // Transaction complete
      finish(SUCCESS);
    }
  }
  
  
  /**
   * After one flashnode is completely written,
   * the flashnode must be finalized to the Checkpoint
   * and the next flashnode metadata must be written
   * and obtained before proceeding.
   * Check that the next flashnode exists before entering
   * this function
   */
  task void writeNextNode() {
    bool constructing = currentNode->state == NODE_CONSTRUCTING;
    // 1. Lock this flashnode in RAM
    // 2. Make the current flashnode the next node... then,
    // 3. Write the current node's metadata in NodeShop
    // 4. Continue transaction.
    
    
    // A flashnode that is constructing virtually gets a special
    // magic number that will delete the flashnode if the 
    // mote reboots before we're completely done with the
    // update.
    currentNode = currentNode->nextNode;

    if(constructing) {
      currentNode->state = NODE_CONSTRUCTING;
    }
    
    writeCurrentNodeMeta();
  }
  
  
  /**
   * Perform the read from flash 
   */
  task void read() {
    if(!call FlashBridge.read(actualAddress, currentBuffer + totalComplete, currentAmount)) {
      post read();
    }
  }
  
  
  /** 
   * Perform the write to flash 
   */
  task void write() {
    currentNode->dataCrc = call GenericCrc.crc16(currentNode->dataCrc, currentBuffer + totalComplete, currentAmount);
    if(!call FlashBridge.write(actualAddress, currentBuffer + totalComplete, currentAmount)) {
      post write();
    }
  }
  
  
  
  
  /***************** Functions ****************/
  /**
   * Initialize the transaction
   */
  void ioInit(file *ioFile, uint32_t fileAddress) {
    currentFile = ioFile;
    totalComplete = 0;
    
    if((currentNode = call NodeMap.getAddressInFile(ioFile, fileAddress, &offset)) == NULL) {
      finish(SUCCESS);
    }

    // Any information written to the end of a file must be appended!
    // Because if the next address to write to actually belongs to
    // the next flashnode in the file, that flashnode is checked to see if its
    // metadata is actually written to flash.  This won't check
    // to see if any previous nodes before it have their metadatas
    // written.  It's ok to write to an address previous to the
    // point where we last appended.
    if(isWriting() && currentNode->state == NODE_TEMPORARY) {
      writeCurrentNodeMeta();
      
    } else {
      post transaction();
    }
  }
  
  /**
   * Finish the transaction 
   */
  void finish(result_t result) {
    if(isWriting()) {
      call State.toIdle();
      signal Fileio.writeDone(currentBuffer, totalComplete, result);
      
    } else {
      call State.toIdle();
      signal Fileio.readDone(currentBuffer, totalComplete, result);
    }
  }
  
  /**
   * @return TRUE if this component is writing to flash
   */
  bool isWriting() {
    return call State.getState() == S_WRITING;
  }
  
  /**
   * Write the nodemeta for the currentNode to flash
   */
  void writeCurrentNodeMeta() {
    // We'll never have to write the filename out here.
    call NodeShop.writeNodemeta(currentFile, currentNode, NULL);
  }
}

