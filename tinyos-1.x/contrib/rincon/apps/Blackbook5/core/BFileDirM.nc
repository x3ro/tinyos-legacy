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
 * Blackbook File Dir Configuration
 * Allows the application to find out information about the
 * file system and flash usage.
 * @author David Moss - dmm@rincon.com
 */

includes Blackbook;

module BFileDirM {
  provides { 
    interface BFileDir[uint8_t id];
  }
  
  uses {
    interface State as BlackbookState;
    interface NodeMap;
    interface SectorMap;
    interface NodeShop;
    interface BDictionary;
    interface InternalDictionary;
    interface Util;
  }
}

implementation {

  /** The current flashnode to verify the CRC for */
  flashnode *crcNode;
  
  /** The current file to verify the CRC for */
  file *crcFile;
  
  /** The current client we're working with */
  uint8_t currentClient;
  
  /** Storage for a filename */  
  filename filenameBuffer;

  /***************** Prototypes ****************/
  /** Get the CRC of the current crcNode */
  task void getCrc();
  
  
  /***************** BFileDir Commands ****************/
  /**
   * @return the total number of files in the file system
   */
  command uint8_t BFileDir.getTotalFiles[uint8_t id]() {
    return call NodeMap.getTotalFiles();
  }
  
  /**
   * @return the total number of nodes in the file system
   */
  command uint16_t BFileDir.getTotalNodes[uint8_t id]() {
    return call NodeMap.getTotalNodes();
  }

  /**
   * @return the approximate free space on the flash 
   */
  command uint32_t BFileDir.getFreeSpace[uint8_t id]() {
    return call SectorMap.getFreeSpace();
  }
  
  /**
   * Returns TRUE if the file exists, FALSE if it doesn't
   */
  command result_t BFileDir.checkExists[uint8_t id](char *fileName) {
    file *currentFile;
    
    call Util.filenameCpy(&filenameBuffer, fileName);
    currentFile = call NodeMap.getFile(&filenameBuffer);
    
    signal BFileDir.existsCheckDone[id]((char *) &filenameBuffer, currentFile != NULL, SUCCESS);
    return SUCCESS;
  }

  /**
   * An optional way to read the first filename of
   * the system. This is exactly the same as calling
   * BFileDir.readNext(NULL).
   */ 
  command result_t BFileDir.readFirst[uint8_t id]() {
    return call BFileDir.readNext[id](NULL);
  }
 
  /**
   * Read the next file in the file system, based on the
   * current filename.  If you want to find the first
   * file in the file system, pass in NULL.
   *
   * If the next file exists, it will be returned in the
   * nextFile event with result SUCCESS
   *
   * If there is no next file, the nextFile event will
   * signal with the filename passed in and FAIL.
   *
   * If the present filename passed in doesn't exist,
   * then this command returns FAIL and no signal is given.
   *
   * @param presentFilename - the name of the current file,
   *     of which you want to find the next valid file after.
   */
  command result_t BFileDir.readNext[uint8_t id](char *presentFilename) {
    int i;
    uint16_t targetCrc;

    if(!call BlackbookState.requestState(S_DIR_BUSY)) {
      return FAIL;
    }

    currentClient = id;
 
    if(presentFilename != NULL) {
      call Util.filenameCpy(&filenameBuffer, presentFilename);
      targetCrc = call Util.filenameCrc(&filenameBuffer);
      
      for(i = 0; i < call NodeMap.getMaxFiles(); i++) {
        if((call NodeMap.getFileAtIndex(i))->filenameCrc == targetCrc) {
          // The index of the present filename was found
          for(i += 1; i < call NodeMap.getMaxFiles(); i++) {
            if((call NodeMap.getFileAtIndex(i))->state != FILE_EMPTY) {
              // This is the next file after the index of the present file
              call NodeShop.getFilename(call NodeMap.getFileAtIndex(i), &filenameBuffer);
              return SUCCESS;
            }
          }
        
          // There is no next file
          call BlackbookState.toIdle();
          signal BFileDir.nextFile[id](presentFilename, FAIL);
          return SUCCESS;
        }
      }
    
      // The present filename does not exist
      call BlackbookState.toIdle();
      return FAIL;
      
    } else {
      for(i = 0 ; i < call NodeMap.getMaxFiles(); i++) {
        if((call NodeMap.getFileAtIndex(i))->state != FILE_EMPTY) {
          // This is the first file
          call NodeShop.getFilename(call NodeMap.getFileAtIndex(i), &filenameBuffer);
          return SUCCESS;
        }
      }
      
      // There are no files on this file system
      call BlackbookState.toIdle();
      signal BFileDir.nextFile[id](presentFilename, FAIL);
      return SUCCESS;
    }
  }

  /**
   * Get the total reserved bytes of an existing file
   * @param fileName - the name of the file to pull the reservedLength from.
   * @return the reservedLength of the file, 0 if it doesn't exist
   */
  command uint32_t BFileDir.getReservedLength[uint8_t id](char *fileName) {
    filename currentFilename;
    file *currentFile;
    
    call Util.filenameCpy(&currentFilename, fileName);
    if((currentFile = call NodeMap.getFile(&currentFilename)) == NULL) {
      return 0;
    }
    
    return call NodeMap.getReserveLength(currentFile);
  }
  
  /**
   * Get the total amount of data written to the file with
   * the given fileName.
   * @param fileName - name of the file to pull the dataLength from.
   * @return the dataLength of the file, 0 if it doesn't exist
   */
  command uint32_t BFileDir.getDataLength[uint8_t id](char *fileName) {
    filename currentFilename;
    file *currentFile;
    
    call Util.filenameCpy(&currentFilename, fileName);
    if((currentFile = call NodeMap.getFile(&currentFilename)) == NULL) {
      return 0;
    }
    
    return call NodeMap.getDataLength(currentFile);
  }
 
  /**
   * Find if a file is corrupt. This will read each node
   * from the file and verify it against its dataCrc.
   * If the calculated data CRC from a flashnode does
   * not match the node's recorded CRC, the file is corrupt.
   * @return SUCCESS if the corrupt check will proceed.
   */
  command result_t BFileDir.checkCorruption[uint8_t id](char *fileName) {
    filename currentFilename;
    
    if(!call BlackbookState.requestState(S_DIR_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;
    
    call Util.filenameCpy(&currentFilename, fileName);
    if((crcFile = call NodeMap.getFile(&currentFilename)) == NULL) {
      call BlackbookState.toIdle();
      return FAIL;
    }
    
    
    crcNode = crcFile->firstNode;
    call InternalDictionary.isFileDictionary(crcFile);
    return SUCCESS;
  }


  /***************** BDictionary Events ****************/
  
  /**
   * @param isDictionary - TRUE if the file is a dictionary
   * @param result - SUCCESS if the reading is valid
   */
  event void BDictionary.fileIsDictionary(bool isDictionary, result_t result) {
    if(call BlackbookState.getState() == S_DIR_BUSY) {
      if(result && isDictionary) {
        // This is a dictionary file - it is not corrupted
        call BlackbookState.toIdle();
        signal BFileDir.corruptionCheckDone[currentClient]((char *) (&filenameBuffer), FALSE, SUCCESS);
        
      } else {
        // This is not a dictionary file - verify it
        post getCrc();
      }   
    }
  }
  
  /**
   * A Dictionary file was opened successfully.
   * @param totalSize - the total amount of flash space dedicated to storing
   *     key-value pairs in the file
   * @param remainingBytes - the remaining amount of space left to write to
   * @param result - SUCCESS if the file was successfully opened.
   */
  event void BDictionary.opened(uint32_t totalSize, uint32_t remainingBytes, result_t result) {
  }
  
  /** 
   * The opened Dictionary file is now closed
   * @param result - SUCCSESS if there are no open files
   */
  event void BDictionary.closed(result_t result) {
  }
  
  /**
   * A key-value pair was inserted into the currently opened Dictionary file.
   * @param key - the key used to insert the value
   * @param value - pointer to the buffer containing the value.
   * @param valueSize - the amount of bytes copied from the buffer into flash
   * @param result - SUCCESS if the key was written successfully.
   */
  event void BDictionary.inserted(uint32_t key, void *value, uint16_t valueSize, result_t result) {
  }
  
  /**
   * A value was retrieved from the given key.
   * @param key - the key used to find the value
   * @param valueHolder - pointer to the buffer where the value was stored
   * @param valueSize - the actual size of the value.
   * @param result - SUCCESS if the value was pulled out and is uncorrupted
   */
  event void BDictionary.retrieved(uint32_t key, void *valueHolder, uint16_t valueSize, result_t result) {
  }
  
  /**
   * A key-value pair was removed
   * @param key - the key that should no longer exist
   * @param result - SUCCESS if the key was really removed
   */
  event void BDictionary.removed(uint32_t key, result_t result) {
  }
  
  /**
   * The next key in the open Dictionary file
   * @param nextKey - the next key
   * @param result - SUCCESS if this is the really the next key,
   *     FAIL if the presentKey was invalid or there is no next key.
   */
  event void BDictionary.nextKey(uint32_t nextKey, result_t result) {
  }

  event void BDictionary.totalKeys(uint16_t totalKeys) {
  }
  
  
  /***************** NodeShop Events ****************/ 
  /**
   * A crc was calculated from flashnode data on flash
   * @param dataCrc - the crc of the data read from the flashnode on flash.
   * @param result - SUCCESS if the crc is valid
   */
  event void NodeShop.crcCalculated(uint16_t dataCrc, result_t result) {
    if(dataCrc == crcNode->dataCrc) {
      if((crcNode = crcNode->nextNode) != NULL) {
        // More nodes in this file to verify
        post getCrc();
        
      } else {
        // No more nodes to verify, all are ok.
        call BlackbookState.toIdle();
        signal BFileDir.corruptionCheckDone[currentClient]((char *) (&filenameBuffer), FALSE, SUCCESS);
      }
         
    } else {
      // This flashnode is corrupted, so the whole file is corrupt.
      call BlackbookState.toIdle();
      signal BFileDir.corruptionCheckDone[currentClient]((char *) (&filenameBuffer), TRUE, SUCCESS);
    }
  }
  
  /**
   * The filename was retrieved from flash
   * @param focusedFile - the file that we obtained the filename for
   * @param *name - pointer to where the filename was stored
   * @param result - SUCCESS if the filename was retrieved
   */
  event void NodeShop.filenameRetrieved(file *focusedFile, filename *name, result_t result) {
    call BlackbookState.toIdle();
    signal BFileDir.nextFile[currentClient]((char *) name->getName, result);
  }
  
  /** 
   * The node's metadata was written to flash
   * @param focusedNode - the flashnode that metadata was written for
   * @param result - SUCCESS if it was written
   */
  event void NodeShop.metaWritten(flashnode *focusedNode, result_t result) {
  }
  
  /**
   * A flashnode was deleted from flash by marking its magic number
   * invalid in the metadata.
   * @param focusedNode - the flashnode that was deleted.
   * @param result - SUCCESS if the flashnode was deleted successfully.
   */
  event void NodeShop.metaDeleted(flashnode *focusedNode, result_t result) {
  }
  
  /***************** Tasks ****************/
  /**
   * Get the CRC of the data in the current crcNode
   */
  task void getCrc() {
    if(!call NodeShop.getCrc(crcNode, crcFile)) {
      post getCrc();
    }
  }
  
  
  /***************** Defaults ****************/

  default event void BFileDir.corruptionCheckDone[uint8_t id](char *fileName, bool isCorrupt, result_t result) {
  }

  default event void BFileDir.existsCheckDone[uint8_t id](char *fileName, bool doesExist, result_t result) {
  }
    
  default event void BFileDir.nextFile[uint8_t id](char *fileName, result_t result) {
  }
  
}




