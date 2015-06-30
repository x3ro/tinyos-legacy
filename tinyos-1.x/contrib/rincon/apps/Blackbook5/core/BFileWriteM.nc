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
 * Blackbook BFileWrite Configuration
 * Open, Write, Save, Close Blackbook files.
 * Use unique("BFileWrite") when connecting to a parameterized
 * interface.
 *
 * @author David Moss - dmm@rincon.com
 * @author Mark Kranz
 */
 
includes Blackbook;

module BFileWriteM {
  provides {
    interface StdControl;
    interface BFileWrite[uint8_t id];
  }
  
  uses {
    interface State as BlackbookState;
    interface WriteAlloc;
    interface NodeMap;
    interface Fileio; 
    interface Checkpoint;
    interface Util;
  }
}

implementation {

  /** Each client's file writing information */
  file *writers[uniqueCount("BFileWrite")];
  
  /** The current client we're working with */
  uint8_t currentClient;
  
  /** Current flashnode we're closing or checkpointing */
  flashnode *currentNode;
  
  
  /** Command States */
  enum {
    S_IDLE = 0,
    S_COMMAND_OPEN,
    S_COMMAND_CLOSE,
    S_COMMAND_SAVE,
    S_COMMAND_APPEND,
    
  };
  
  
  /***************** Prototypes ****************/
  
  /** Checkpoint the current client's open file */
  task void checkpointNode();
  
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    int i;
    for(i = 0; i < uniqueCount("BFileWrite"); i++) {
      writers[i] = NULL;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** BFileWrite Commands ****************/
  /**
   * Open a file for writing. 
   * @param fileName - name of the file to write to
   * @param minimumSize The minimum requested amount of total data space
   *            to reserve in the file.  The physical amount of flash 
   *            consumed by the file may be more.
   */
  command result_t BFileWrite.open[uint8_t id](char *fileName, uint32_t minimumSize) {
    if(!call BlackbookState.requestState(S_WRITE_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;
    
    if(writers[currentClient] == NULL) {
      if(call WriteAlloc.openForWriting(fileName, minimumSize, FALSE, FALSE)) {
        return SUCCESS;
      }
    
    } else {
      // File already open
      call BlackbookState.toIdle();
      signal BFileWrite.opened[currentClient](call NodeMap.getReserveLength(writers[currentClient]), SUCCESS);
      return SUCCESS;
    }
    
    call BlackbookState.toIdle();
    return FAIL;
  }

  /**
   * @return TRUE if the given parameterized interface has a file open
   */
  command bool BFileWrite.isOpen[uint8_t id]() {
    return (writers[id] != NULL);
  }
  
  
  /**
   * Close any currently opened write file.
   */
  command result_t BFileWrite.close[uint8_t id]() {
    if(!call BlackbookState.requestState(S_WRITE_CLOSE_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;

    if(writers[currentClient] == NULL) {
      call BlackbookState.toIdle();
      signal BFileWrite.closed[currentClient](SUCCESS);
      return SUCCESS;
    }
    
    currentNode = writers[currentClient]->firstNode;
    post checkpointNode();
    return SUCCESS;
  }

  /**
   * Save the current state of the file, guaranteeing the next time
   * we experience a catastrophic failure, we will at least be able to
   * recover data from the open write file up to the point
   * where save was called.
   *
   * If data is simply being logged for a long time, use save() 
   * periodically but probably more infrequently.
   *
   * @return SUCCESS if the currently open file will be saved.
   */
  command result_t BFileWrite.save[uint8_t id]() {
    if(!call BlackbookState.requestState(S_WRITE_SAVE_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;
    
    if(writers[currentClient] == NULL) {
      call BlackbookState.toIdle();
      return FAIL;
    }
    
    currentNode = writers[currentClient]->firstNode;
    post checkpointNode();
    return SUCCESS;
  }

  /**
   * Append the specified amount of data from a given buffer
   * to the open write file.  
   *
   * @param buf - the buffer of data to append
   * @param amount - the amount of data in the buffer to write.
   * @return SUCCESS if the data will be written, FAIL if there
   *     is no open file to write to.
   */ 
  command result_t BFileWrite.append[uint8_t id](void *data, uint16_t amount) {
    if(!call BlackbookState.requestState(S_WRITE_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;
    
    if(writers[currentClient] != NULL) {
      if(call Fileio.writeData(writers[currentClient], call NodeMap.getDataLength(writers[currentClient]), data, amount)) {
        return SUCCESS;
      }
    }
    
    call BlackbookState.toIdle();
    return FAIL;
  }

  /**
   * Obtain the remaining bytes available to be written in this file
   * @return the remaining length of the file.
   */
  command uint32_t BFileWrite.getRemaining[uint8_t id]() {
    flashnode *focusedNode;
    uint32_t remaining = 0;
    
    if(writers[id] != NULL) {
      for(focusedNode = writers[id]->firstNode; focusedNode != NULL ; focusedNode = focusedNode->nextNode) {
        if(focusedNode->state != NODE_LOCKED) {
          remaining += focusedNode->reserveLength - focusedNode->dataLength;
        }
      }
    }
    
    return remaining;
  }


  /***************** WriteAlloc Events ****************/
  /**
   * The write open process completed
   * @param openFile - the file that was opened for writing 
   * @param writeNode - the flashnode to write to
   * @param result - SUCCESS if the file was correctly opened
   */
  event void WriteAlloc.openedForWriting(file *openFile, flashnode *writeNode, uint32_t totalSize, result_t result) {
    if(call BlackbookState.getState() == S_WRITE_BUSY) {
      if(result) {
        writers[currentClient] = openFile;
      }
      

      call BlackbookState.toIdle();
      signal BFileWrite.opened[currentClient](totalSize, SUCCESS);
    }
  }
  
  
  /***************** Fileio Events ****************/
  /**
   * Data was appended to the flashnode in the flash.
   * @param writeBuffer - pointer to the buffer containing the data written
   * @param amountWritten - the amount of data appended to the node.
   * @param result - SUCCESS if the data was successfully written
   */
  event void Fileio.writeDone(void *writeBuffer, uint32_t amountWritten, result_t result) {
    if(call BlackbookState.getState() == S_WRITE_BUSY) {
      call BlackbookState.toIdle();
      signal BFileWrite.appended[currentClient](writeBuffer, amountWritten, result);
    }
  }
  
  /**
   * Data was read from the file
   * @param *readBuffer - pointer to the location where the data was stored
   * @param amountRead - the amount of data actually read
   * @param result - SUCCESS if the data was successfully read
   */
  event void Fileio.readDone(void *readBuffer, uint32_t amountRead, result_t result) {
  }
  
  /**
   * Data was flushed to flash
   * @param result - SUCCESS if the data was flushed
   */
  event void Fileio.flushDone(result_t result) {
  }
  
  /***************** Checkpoint Events ****************/
  /**
   * The given flashnode was updated in the Checkpoint
   * @param focusedNode - the flashnode that was updated
   * @param result - SUCCESS if everything's ok
   */
  event void Checkpoint.updated(flashnode *focusedNode, result_t result) {
    flashnode *previousNode;
    if(call BlackbookState.getState() == S_WRITE_SAVE_BUSY) {
      currentNode = currentNode->nextNode;
      if(currentNode != NULL) {
        if(currentNode->state != NODE_TEMPORARY) {
          post checkpointNode();
          return;
        }
      }
      
      call BlackbookState.toIdle();
      signal BFileWrite.saved[currentClient](result);
     
    } else if(call BlackbookState.getState() == S_WRITE_CLOSE_BUSY) {
      currentNode = currentNode->nextNode;
      if(currentNode != NULL) {
        if(currentNode->state != NODE_TEMPORARY) {
          post checkpointNode();
          return;
        }
      }
      
      currentNode = writers[currentClient]->firstNode;
      for(previousNode = currentNode; currentNode != NULL; currentNode = currentNode->nextNode) {
        if(currentNode->state == NODE_TEMPORARY) {
          previousNode->nextNode = NULL;
          currentNode->state = NODE_EMPTY;
        
        } else if(currentNode->state == NODE_VALID) {
          // Prevent this flashnode from ever being written to again
          currentNode->state = NODE_LOCKED;
        }
      }
      
      writers[currentClient]->state = FILE_IDLE;
      writers[currentClient] = NULL;
      call BlackbookState.toIdle();
      signal BFileWrite.closed[currentClient](SUCCESS);
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
   * Checkpoint the open flashnode from the current client
   */
  task void checkpointNode() {
    if(!call Checkpoint.update(currentNode)) {
      post checkpointNode();
    }
  }
  
  
  /***************** Functions ****************/
  
  /***************** Defaults ****************/  
  default event void BFileWrite.opened[uint8_t id](uint32_t len, result_t result) {
  }

  default event void BFileWrite.closed[uint8_t id](result_t result) {
  }

  default event void BFileWrite.saved[uint8_t id](result_t result) {
  }

  default event void BFileWrite.appended[uint8_t id](void *data, uint16_t amountWritten, result_t result) {
  }
}

