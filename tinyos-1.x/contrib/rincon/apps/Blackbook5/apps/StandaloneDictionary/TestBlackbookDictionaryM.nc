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
 * Test Blackbook
 * @author David Moss - dmm@rincon.com
 */
 
module TestBlackbookDictionaryM {
  uses {
    interface BBoot;
    interface BFileDelete;
    interface BFileDir;
    interface BDictionary;
    interface BClean;
  }
}

implementation {

  
  /***************** BBoot Events ****************/
  /**
   * The file system finished booting
   * @param totalNodes - the total number of nodes found on flash
   * @param result - SUCCESS if the file system is ready for use.
   */
  event void BBoot.booted(uint16_t totalNodes, uint8_t totalFiles, result_t result) {
  }
  
  /***************** BClean Events ****************/
  
  /**
   * The Garbage Collector is erasing a sector - this may take awhile
   */
  event void BClean.erasing() {
  }
  
  /**
   * Garbage Collection is complete
   * @return SUCCESS if any sectors were erased.
   */
  event void BClean.gcDone(result_t result) {
  }
  
  
  /***************** BFileDelete Events ****************/
  /**
   * A file was deleted
   * @param result - SUCCESS if the file was deleted from flash
   */
  event void BFileDelete.deleted(result_t result) {

  }
  
  
  /***************** BFileDir Events ****************/
  /**
   * The corruption check on a file is complete
   * @param fileName - the name of the file that was checked
   * @param isCorrupt - TRUE if the file's actual data does not match its CRC
   * @param result - SUCCESS if this information is valid.
   */
  event void BFileDir.corruptionCheckDone(char *fileName, bool isCorrupt, result_t result) {

  }

  /**
   * The check to see if a file exists is complete
   * @param fileName - the name of the file
   * @param doesExist - TRUE if the file exists
   * @param result - SUCCESS if this information is valid
   */
  event void BFileDir.existsCheckDone(char *fileName, bool doesExist, result_t result) {

  }
  
  
  /**
   * This is the next file in the file system after the given
   * present file.
   * @param fileName - name of the next file
   * @param result - SUCCESS if this is actually the next file, 
   *     FAIL if the given present file is not valid or there is no
   *     next file.
   */  
  event void BFileDir.nextFile(char *fileName, result_t result) {

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
  
  
  /**
   * @param isDictionary - TRUE if the file is a dictionary
   * @param result - SUCCESS if the reading is valid
   */
  event void BDictionary.fileIsDictionary(bool isDictionary, result_t result) {
  }

  event void BDictionary.totalKeys(uint16_t totalKeys) {
  }
  
}


