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
 * Blackbook Delete Configuration
 * Invalidate a file on flash
 * 
 * @author David Moss - dmm@rincon.com
 */
 
includes Blackbook;

module BFileDeleteM {
  provides {
    interface BFileDelete[uint8_t id];
  }
 
  uses {
    interface State as BlackbookState;
    interface NodeShop;
    interface NodeMap;
    interface Checkpoint;
    interface Util;
  }  
}

implementation {
  
  /** The current client we're connected with */
  uint8_t currentClient;
  
  /** The current file we're working with */
  file *currentFile;
  
  /** The current flashnode we're focused on */
  flashnode *currentNode;
  
  /** The flashnode previous to the current flashnode we're focused on */
  flashnode *previousNode;
  
  /***************** Prototypes ****************/
  /** Finalize the current flashnode if it needs to be */
  task void finalize();
  
  
  /***************** BFileDelete Commands ****************/
  /**
   * Delete a file - from the last flashnode to the first node,
   * to prevent the creation of dangling nodes.
   *
   *  1. Locate the last existing flashnode of the file.
   *  2. Delete it, remove its checkpoint.
   *  3. Repeat steps 1 and 2 until all nodes are invalidated.
   *  4. Remove all recognition of the file from memory.
   *
   * @param fileName - the name of the file to delete
   * @return SUCCESS if Blackbook will attempt to delete the file.
   */ 
  command result_t BFileDelete.delete[uint8_t id](char *fileName) {
    filename currentFilename;
    if(!call BlackbookState.requestState(S_DELETE_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;
    
    call Util.filenameCpy(&currentFilename, fileName);
    if(((currentFile = call NodeMap.getFile(&currentFilename)) == NULL) || currentFile->state != FILE_IDLE) {
      call BlackbookState.toIdle();
      return FAIL;
    }

    currentNode = currentFile->firstNode;
    previousNode = currentNode;
    post finalize();
    return SUCCESS;
  }
  
  /***************** NodeShop ****************/
  /**
   * A flashnode was deleted from flash by marking its magic number
   * invalid in the metadata.
   * @param focusedNode - the flashnode that was deleted.
   * @param result - SUCCESS if the flashnode was deleted successfully.
   */
  event void NodeShop.metaDeleted(flashnode *focusedNode, result_t result) {
    if(call BlackbookState.getState() == S_DELETE_BUSY) {
      currentNode->state = NODE_EMPTY;
      previousNode->nextNode = NULL;
    
      if(currentFile->firstNode->state == NODE_EMPTY) {
        currentFile->firstNode = NULL;
        currentFile->state = FILE_EMPTY;
        call BlackbookState.toIdle();
        signal BFileDelete.deleted[currentClient](SUCCESS);
        
      } else {
        currentNode = currentFile->firstNode;
        previousNode = currentFile->firstNode;
        post finalize();
      }
    }
  }
 
  /**
   * A crc was calculated from flashnode data on flash
   * @param dataCrc - the crc of the data read from the flashnode on flash.
   * @param result - SUCCESS if the crc is valid
   */
  event void NodeShop.crcCalculated(uint16_t dataCrc, result_t result) {
  }
  
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
  
  
  
  /***************** Checkpoint Events *****************/
  /**
   * The given flashnode was updated in the Checkpoint
   * @param focusedNode - the flashnode that was updated
   * @param result - SUCCESS if everything's ok
   */
  event void Checkpoint.updated(flashnode *focusedNode, result_t result) {
    if(call BlackbookState.getState() == S_DELETE_BUSY) {
      call NodeShop.deleteNode(currentNode);
    }
  }
  
  /**
   * The checkpoint file was opened.
   * @param result - SUCCESS if it was opened successfully
   */
  event void Checkpoint.checkpointOpened(result_t result) {
  }
  
  /** 
   * A flashnode was recovered.
   * @param result - SUCCESS if it was handled correctly.
   */
  event void Checkpoint.recovered(flashnode *focusedNode, result_t result) { 
  }
  
  
  /***************** Tasks ****************/
  /**
   * Finalize the current node
   */
  task void finalize() {
    if((currentNode->nextNode == NULL) || currentNode->nextNode->state == NODE_DELETED) {
      // Working from the last flashnode in the file to the first node:
      // 1. Remove the checkpoint. This way, if we reboot in the middle,
      //    the flashnode will get erased anyway.
      // 2. Invalidate the nodemeta through NodeShop.
      
      currentNode->state = NODE_DELETED;
      call Checkpoint.update(currentNode);
      
    } else {
      // Run to the last flashnode of the file
      previousNode = currentNode;
      currentNode = currentNode->nextNode;
      post finalize();
    }
  }
  
  
  /***************** Functions ****************/

  /***************** Defaults ****************/
  default event void BFileDelete.deleted[uint8_t id](result_t result) {
  }
   
}



