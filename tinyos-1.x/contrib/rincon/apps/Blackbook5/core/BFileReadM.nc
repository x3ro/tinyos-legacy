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
 * Blackbook BFileRead Configuration
 * Open, Read, Close Blackbook files.
 * Use unique("BFileRead") when connecting to a parameterized
 * interface.
 * @author David Moss - dmm@rincon.com
 */

includes Blackbook;

module BFileReadM {
  provides {
    interface BFileRead[uint8_t id];
    interface StdControl;
  }
  
  uses {
    interface State as BlackbookState;
    interface Fileio;
    interface NodeMap;
    interface Util;
  }
}

implementation {

  /**Each client's current read information */
  struct filereader {

    /** The current file open for writing, NULL if no file is open */
    file *openFile;
    
    /** The position to read from in the current open flashnode */
    uint32_t readAddress;
  
  } readers[uniqueCount("BFileRead")];


  /** The current client we're working with */
  uint8_t currentClient;
  
  /***************** Prototypes ****************/  

  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    int i;
    for(i = 0; i < uniqueCount("BFileRead"); i++) {
      readers[i].openFile = NULL;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** BFileRead Commands ****************/
  /**
   * Open a file for reading
   * @param fileName - name of the file to open
   * @return SUCCESS if the attempt to open for reading proceeds
   */ 
  command result_t BFileRead.open[uint8_t id](char *fileName) {
    filename currentFilename;
    
    if(!call BlackbookState.requestState(S_READ_BUSY)) {
      return FAIL;
    }

    currentClient = id;
    call Util.filenameCpy(&currentFilename, fileName);
    
    if(readers[currentClient].openFile == NULL) {
      if((readers[currentClient].openFile = call NodeMap.getFile(&currentFilename)) != NULL) {
        if(readers[currentClient].openFile->state == FILE_IDLE) {
          // We set it to READING only to prevent this file from being deleted.
          readers[currentClient].openFile->state = FILE_READING;
        }
        readers[currentClient].readAddress = 0;
        call BlackbookState.toIdle();    
        signal BFileRead.opened[currentClient](call NodeMap.getDataLength(readers[currentClient].openFile), SUCCESS);
        return SUCCESS;
      }
      
    } else {
      // File already open
      call BlackbookState.toIdle();
      signal BFileRead.opened[currentClient](call NodeMap.getDataLength(readers[currentClient].openFile), SUCCESS);
      return SUCCESS;
    }
    
    call BlackbookState.toIdle();
    return FAIL;
  }
  
  /**
   * @return TRUE if the given parameterized interface has a file open
   */
  command bool BFileRead.isOpen[uint8_t id]() {
    return (readers[id].openFile != NULL);
  }

  /**
   * Close any currently opened file
   */
  command result_t BFileRead.close[uint8_t id]() {
    currentClient = id;
    if(readers[currentClient].openFile != NULL) {
      // Set the file to IDLE only if it was IDLE to begin with.
      if(readers[currentClient].openFile->state == FILE_READING) {
        readers[currentClient].openFile->state = FILE_IDLE;
      }
    }
    
    readers[currentClient].openFile = NULL;
    signal BFileRead.closed[id](SUCCESS);
    return SUCCESS;
  }

  /**
   * Read a specified amount of data from the open
   * file into the given buffer
   * @param *dataBuffer - the buffer to read data into
   * @param amount - the amount of data to read
   * @return SUCCESS if the command goes through
   */
  command result_t BFileRead.read[uint8_t id](void *dataBuffer, uint16_t amount) {
    if(!call BlackbookState.requestState(S_READ_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;

    if((readers[currentClient].openFile == NULL) 
        || !call Fileio.readData(readers[currentClient].openFile, readers[currentClient].readAddress, dataBuffer, amount)) {
      call BlackbookState.toIdle();
      return FAIL;
    }
    
    return SUCCESS;
  }

  /**
   * Seek a given address to read from in the file.
   *
   * @param fileAddress - the address to seek
   * @return SUCCESS if the read pointer is adjusted,
   *         FAIL if the read pointer didn't change
   */
  command result_t BFileRead.seek[uint8_t id](uint32_t fileAddress) {
    readers[id].readAddress = fileAddress;
    return SUCCESS;
  }

  /**
   * Skip the specified number of bytes in the file
   * @param skipLength - number of bytes to skip
   * @return SUCCESS if the internal read pointer was adjusted
   */
  command result_t BFileRead.skip[uint8_t id](uint16_t skipLength) {
    readers[id].readAddress += skipLength;
    return SUCCESS;
  }

  /**
   * Get the remaining bytes available to read from this file.
   * This is the total size of the file minus your current position.
   * @return the number of remaining bytes in this file 
   */
  command uint32_t BFileRead.getRemaining[uint8_t id]() {
    if(readers[id].openFile == NULL) {
      return 0;
    } 
    
    return (call NodeMap.getDataLength(readers[id].openFile)) - readers[id].readAddress;
  }

  /***************** Fileio Events ****************/
  /**
   * Data was read from the file
   * @param *readBuffer - pointer to the location where the data was stored
   * @param amountRead - the amount of data actually read
   * @param result - SUCCESS if the data was successfully read
   */
  event void Fileio.readDone(void *readBuffer, uint32_t amountRead, result_t result) {
    if(call BlackbookState.getState() == S_READ_BUSY) {
      readers[currentClient].readAddress += amountRead;
      call BlackbookState.toIdle();
      signal BFileRead.readDone[currentClient](readBuffer, amountRead, result);
    }
  }
  
  /**
   * Data was appended to the flashnode in the flash.
   * @param writeBuffer - pointer to the buffer containing the data written
   * @param amountWritten - the amount of data appended to the node.
   * @param result - SUCCESS if the data was successfully written
   */
  event void Fileio.writeDone(void *writeBuffer, uint32_t amountWritten, result_t result) {
  }

  /**
   * Data was flushed to flash
   * @param result - SUCCESS if the data was flushed
   */
  event void Fileio.flushDone(result_t result) {
  }
    
  /***************** Defaults ****************/
  default event void BFileRead.opened[uint8_t id](uint32_t amount, result_t result) {
  }

  default event void BFileRead.closed[uint8_t id](result_t result) {
  }

  default event void BFileRead.readDone[uint8_t id](void *buf, uint16_t amount, result_t result) {
  }
  
}



