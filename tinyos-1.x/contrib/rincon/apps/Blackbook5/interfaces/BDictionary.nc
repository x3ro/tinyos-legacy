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
 * Blackbook BDictionary Interface
 */

includes Blackbook;

interface BDictionary {

  /**
   * Open a Dictionary file.  If the file does not exist on flash, the
   * minimumSize will be used to set the length of the file.
   * @param name - name of the Dictionary file to open
   * @param minimumSize - the minimum reserved size for the file on flash
   * @return SUCCESS if the file will be opened
   */
  command result_t open(char *fileName, uint32_t minimumSize);
  
  /**
   * @return TRUE if the given parameterized interface has a file open
   */
  command bool isOpen();
  
  /**
   * Close any opened Dictionary files
   * @return SUCCESS if the open Dictionary file was closed.
   */
  command result_t close();
  
  /**
   * Because Dictionary files are special, and NodeMap does not give an
   * accurate reflection of what's going on with Dictionary file sizes,
   * this command will return the size of the Dictionary file up to the
   * point where valid data ends.
   * @return the size of the valid data in the open dictionary file
   */
  command uint32_t getFileLength();
  
  /**
   * @return SUCCESS if the event totalKeys will be signaled
   */
  command result_t getTotalKeys();
  
  /**
   * Insert a key-value pair into the opened Dictionary file.
   * This will invalidate any old key-value pairs using the
   * associated key.
   * @param key - the key to use
   * @param value - pointer to a buffer containing the value to insert.
   * @param valueSize - the amount of bytes to copy from the buffer
   * @return SUCCESS if the key-value pair will be inserted
   */
  command result_t insert(uint32_t key, void *value, uint16_t valueSize);
  
  /**
   * Retrieve a key from the opened Dictionary file.
   * @param key - the key to find
   * @param valueHolder - pointer to the memory location to store the value
   * @param maxValueSize - used to prevent buffer overflows incase the
   *     recorded size of the value does not match the space allocated to
   *     the valueHolder
   * @return SUCCESS if the key will be retrieved.
   */
  command result_t retrieve(uint32_t key, void *valueHolder, uint16_t maxValueSize);
  
  /**
   * Remove a key from the opened dictionary file
   * @param key - the key for the key-value pair to remove
   * @return SUCCESS if the attempt to remove the key will proceed
   */
  command result_t remove(uint32_t key);
    
  /**
   * This command will signal event nextKey
   * when the first key is found.
   * @return SUCCESS if the command will be processed.
   */
  command result_t getFirstKey();
  
  /**
   * Get the last key inserted into the file.
   * @return the last key, or 0xFFFFFFFF (-1) if it doesn't exist
   */
  command uint32_t getLastKey();
  
  /**
   * Get the next recorded key in the file.
   * @return SUCCESS if the command will be processed
   */
  command result_t getNextKey(uint32_t presentKey);
  
  /**
   * Find out if a given file is a dictionary file
   * @param fileName - the name of the file
   * @return SUCCESS if the command will go through
   */
  command result_t isFileDictionary(char *fileName);
  
  
  
  /**
   * A Dictionary file was opened successfully.
   * @param totalSize - the total amount of flash space dedicated to storing
   *     key-value pairs in the file
   * @param remainingBytes - the remaining amount of space left to write to
   * @param result - SUCCESS if the file was successfully opened.
   */
  event void opened(uint32_t totalSize, uint32_t remainingBytes, result_t result);
  
  /** 
   * The opened Dictionary file is now closed
   * @param result - SUCCSESS if there are no open files
   */
  event void closed(result_t result);
  
  /**
   * A key-value pair was inserted into the currently opened Dictionary file.
   * @param key - the key used to insert the value
   * @param value - pointer to the buffer containing the value.
   * @param valueSize - the amount of bytes copied from the buffer into flash
   * @param result - SUCCESS if the key was written successfully.
   */
  event void inserted(uint32_t key, void *value, uint16_t valueSize, result_t result);
  
  /**
   * A value was retrieved from the given key.
   * @param key - the key used to find the value
   * @param valueHolder - pointer to the buffer where the value was stored
   * @param valueSize - the actual size of the value.
   * @param result - SUCCESS if the value was pulled out and is uncorrupted
   */
  event void retrieved(uint32_t key, void *valueHolder, uint16_t valueSize, result_t result);
  
  /**
   * A key-value pair was removed
   * @param key - the key that should no longer exist
   * @param result - SUCCESS if the key was really removed
   */
  event void removed(uint32_t key, result_t result);
  
  /**
   * The next key in the open Dictionary file
   * @param nextKey - the next key
   * @param result - SUCCESS if this is the really the next key,
   *     FAIL if the presentKey was invalid or there is no next key.
   */
  event void nextKey(uint32_t nextKey, result_t result);

  /**
   * @param isDictionary - TRUE if the file is a dictionary
   * @param result - SUCCESS if the reading is valid
   */
  event void fileIsDictionary(bool isDictionary, result_t result);
  
  /**
   * @param totalKeys the total keys in the open dictionary file
   */
  event void totalKeys(uint16_t totalKeys);
}


