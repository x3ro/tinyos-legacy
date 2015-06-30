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
 * Blackbook Checkpoint Module
 * Saves the state of open binary nodes to a Checkpoint
 * dicationary file on flash for catastrophic failure recovery.
 *
 * Use unique("Checkpoint") when connecting to a parameterized interface
 *
 * @author David Moss - dmm@rincon.com
 */
 
includes BDictionary;
 
module CheckpointM {
  provides {
    interface Checkpoint;
    interface StdControl;
  }
  
  uses {
    interface NodeMap;
    interface NodeShop; 
    interface BDictionary;
    interface InternalDictionary;
    interface State;
    interface Util;
  }
}

implementation {
  
  /** TRUE if we currently have a checkpoint file open for interaction */
  bool checkpointFileOpened;
  
  /** The current checkpoint information being read or written to flash */
  checkpoint currentCheckpoint;
  
  /** Buffer to store a dictionary magic header */
  uint16_t dictionaryHeaderBuffer;

  /** Current flashnode to repair */  
  flashnode *currentNode;
 
  /** Checkpoint States */
  enum {
    S_IDLE = 0,
    S_OPEN,
    S_UPDATE,
    S_RECOVER,
  };
  
  /***************** Prototypes ****************/
  
  /***************** StdControl ****************/
  command result_t StdControl.init() {
    checkpointFileOpened = FALSE;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /***************** Checkpoint Commands ****************/
  /**
   * After boot is complete, open the checkpoint file
   * in the BDictionary
   * @return SUCCESS if the checkpoint file will be 
   *     created and/or opened.
   */
  command result_t Checkpoint.openCheckpoint() {
    if(!checkpointFileOpened) {
      if(!call State.requestState(S_OPEN)) {
        return FAIL;
      }
      
      if(!call BDictionary.open("chkpoint.bb_", call Util.convertPagesToBytes(CHECKPOINT_DEDICATED_PAGES))) {
        call State.toIdle();
        return FAIL;
      }
      
    } else {
      call State.toIdle();
      signal Checkpoint.checkpointOpened(SUCCESS);
    }

    return SUCCESS;
  }
  
  /**
   * Update a node.
   * @param focusedNode - the flashnode to save or delete
   * @return SUCCESS if the information will be updated
   */
  command result_t Checkpoint.update(flashnode *focusedNode) {
    if(!call State.requestState(S_UPDATE)) {
      return FAIL;
    }
    
    currentNode = focusedNode;
    
    if(currentNode == NULL) {
      call State.toIdle();
      return FAIL;
    }
    
    if(currentNode->state == NODE_VALID) {
      // This flashnode needs to be saved.
      currentCheckpoint.filenameCrc = currentNode->filenameCrc;
      currentCheckpoint.dataCrc = currentNode->dataCrc;
      currentCheckpoint.dataLength = currentNode->dataLength;
      
      if(currentNode->nextNode->state == NODE_VALID) {
        currentNode->state = NODE_LOCKED;
      }
      
      if(!call BDictionary.insert(currentNode->flashAddress, &currentCheckpoint, sizeof(checkpoint))) {
        call State.toIdle();
        return FAIL;
      }
      
    } else if(currentNode->state == NODE_DELETED) {
      // This flashnode should be removed from the Checkpoint.
      if(!call BDictionary.remove(currentNode->flashAddress)) {
        call State.toIdle();
        return FAIL;
      }
            
    } else {
      // Nothing to do. Signal and complete.
      call State.toIdle();
      signal Checkpoint.updated(currentNode, SUCCESS);
    }
    
    return SUCCESS;
  }
  
  /**
   * Recover a node's dataLength and dataCrc
   * from the Checkpoint.
   *
   * If the flashnode cannot be recovered, it is deleted.
   *
   * @param focusedNode - the flashnode to recover, with client set to its element number
   * @return SUCCESS if recovery will proceed
   */
  command result_t Checkpoint.recover(flashnode *focusedNode) {
    if(!call State.requestState(S_RECOVER)) {
      return FAIL;
    }
    
    currentNode = focusedNode;
    call BDictionary.retrieve(currentNode->flashAddress, &currentCheckpoint, sizeof(currentCheckpoint));
    return SUCCESS;
  }
  
  /***************** BDictionary Events ****************/
  
  /**
   * A Dictionary file was opened successfully.
   * @param totalSize - the total amount of flash space dedicated to storing
   *     key-value pairs in the file
   * @param remainingBytes - the remaining amount of space left to write to
   * @param result - SUCCESS if the file was successfully opened.
   */
  event void BDictionary.opened(uint32_t totalSize, uint32_t remainingBytes, result_t result) {
    checkpointFileOpened = TRUE;
    call State.toIdle();
    signal Checkpoint.checkpointOpened(result);
  }
  
  /** 
   * The opened Dictionary file is now closed
   * @param result - SUCCSESS if there are no open files
   */
  event void BDictionary.closed(result_t result) {
    checkpointFileOpened = FALSE;
  }
  
  /**
   * A key-value pair was inserted into the currently opened Dictionary file.
   * @param key - the key used to insert the value
   * @param value - pointer to the buffer containing the value.
   * @param valueSize - the amount of bytes copied from the buffer into flash
   * @param result - SUCCESS if the key was written successfully.
   */
  event void BDictionary.inserted(uint32_t key, void *value, uint16_t valueSize, result_t result) {
    call State.toIdle();
    signal Checkpoint.updated(currentNode, result);
  }
  
  /**
   * A value was retrieved from the given key.
   * @param key - the key used to find the value
   * @param valueHolder - pointer to the buffer where the value was stored
   * @param valueSize - the actual size of the value.
   * @param result - SUCCESS if the value was pulled out and is uncorrupted
   */
  event void BDictionary.retrieved(uint32_t key, void *valueHolder, uint16_t valueSize, result_t result) {
    if(result) {
      if(currentNode->filenameCrc == currentCheckpoint.filenameCrc) {
        currentNode->state = NODE_LOCKED;
        currentNode->dataLength = currentCheckpoint.dataLength;
        currentNode->dataCrc = currentCheckpoint.dataCrc;
        call State.toIdle();
        signal Checkpoint.recovered(currentNode, SUCCESS);
        return;
      }
    }
      
    // Recovery failed
    if(currentNode->fileElement == 0) {
      if(call InternalDictionary.isFileDictionary(call NodeMap.getFileFromNode(currentNode))) {
        return;
      }
    }
    
    call NodeShop.deleteNode(currentNode); 
    
  }
  
  /**
   * A key-value pair was removed
   * @param key - the key that should no longer exist
   * @param result - SUCCESS if the key was really removed
   */
  event void BDictionary.removed(uint32_t key, result_t result) {
    if(call State.getState() == S_UPDATE) {
      call State.toIdle();
      signal Checkpoint.updated(currentNode, result);
      
    } else if(call State.getState() == S_RECOVER) {
      call State.toIdle();
      signal Checkpoint.recovered(currentNode, result);
    }
  }
  
  /**
   * The next key in the open Dictionary file
   * @param key - the next key
   * @param result - SUCCESS if this information is valid
   */
  event void BDictionary.nextKey(uint32_t nextKey, result_t result) {
  }
  
  event void BDictionary.fileIsDictionary(bool isDictionary, result_t result) {
    if(call State.getState() == S_RECOVER) {
      if(result && isDictionary) {
        currentNode->dataLength = currentNode->reserveLength;
        currentNode->state = NODE_VALID;
        call State.toIdle();
        signal Checkpoint.recovered(currentNode, result);
      
      } else {
        call NodeShop.deleteNode(currentNode);
      }
    }
  }
  
  event void BDictionary.totalKeys(uint16_t totalKeys) {
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
    file *focusedFile;
    
    if(call State.getState() == S_RECOVER) {
      if((focusedFile = call NodeMap.getFileFromNode(focusedNode)) != NULL) {
        if(focusedFile->firstNode == focusedNode) {
          focusedFile->state = FILE_EMPTY;
        }
      }
      focusedNode->state = NODE_EMPTY;
      call BDictionary.remove(currentNode->flashAddress);
      return; 
    }
  }
 
  /**
   * A crc was calculated from flashnode data on flash
   * @param dataCrc - the crc of the data read from the flashnode on flash.
   * @param result - SUCCESS if the crc is valid
   */
  event void NodeShop.crcCalculated(uint16_t dataCrc, result_t result) {
  }
  

}


