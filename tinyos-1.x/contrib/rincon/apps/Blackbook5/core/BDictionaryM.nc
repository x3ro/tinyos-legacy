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
 * Blackbook BDictionary Module
 * Allows an application to store and retrieve key-value pairs on flash.
 *
 * This component uses 4 layers of states:
 *   1. At the top layer, this can connect to components outside 
 *      of Blackbook, so it uses the BlackbookState to make sure
 *      operations are done atomically inside of Blackbook.
 *      
 *   2. On the second layer, we keep track of which command is
 *      being performed.  This is CommandState.
 *
 *   2. On the third layer, the DictionaryState takes care of
 *      maintaining individual operations to achieve the goal
 *      the second layer's state reflects.  It is used mainly
 *      for file writing and manipulating purposes with flash.
 *
 *   3. On the bottom layer, a SearchState takes care of performing
 *      key searches on flash.  This functionality can technically be
 *      placed in a separate interface, but keeping it altogether
 *      inside this component is a bit easier.  The state of the
 *      SearchState will tell the searching loop when to stop.
 *
 * @author David Moss - dmm@rincon.com
 * @author Mark Kranz
 */
    
includes Blackbook;
includes BDictionary;

module BDictionaryM {
  provides {
    interface StdControl;
    interface BDictionary[uint8_t id];
    interface InternalDictionary[uint8_t id];
  }
  
  uses {
    interface State as BlackbookState;
    interface State as CommandState;
    interface State as DictionaryState;
    interface State as SearchState;
    interface WriteAlloc;
    interface NodeMap;
    interface NodeShop;
    interface GenericCrc;
    interface Fileio;
    interface Util;
  }
}

implementation {
  
  /** A buffer for the key metadata to read from flash */
  keymeta keyBuffer;
  
  /** Information about each client's dictionary */
  static clientDictionary clients[uniqueCount("BDictionary")];
  
  /** The client that made the last request */
  uint8_t currentClient;
  
  /** The current file we're working with */
  file *currentFile;
  
  /** The current key we're interacting with */
  uint32_t currentKey;
  
  /** The current value's size */
  uint16_t currentValueSize;
  
  /** The current value's crc */
  uint16_t currentValueCrc;
  
  /** A pointer to the current lookup value buffer */
  void *currentValuePtr;
  
  /** The offset in the file for our current search */
  uint32_t currentSearchOffset;
  
  /** Marker to locate a key offset to delete after a new key is inserted */
  uint32_t marker;
  
  /** The oldest valid index in the currentClient's cache used in searching for the current key */
  uint8_t oldestValidCacheIndex;
  
  /** The offset in the file for our current search */
  uint32_t currentSearchOffset;
  
  /** The magic number header at the top of each dictionary file */
  uint16_t dictionaryHeader;
  
  /** Magic number to hold the value while it's being written from a task in IO */
  uint16_t magicNumber;
  
  /** Copy: Current file to copy to */
  file *currentFile;
  
  /** Copy: Current offset to write to */
  uint32_t currentWriteOffset;
  
  /** Copy: The total amount of data copied for the current value */
  uint16_t totalAmountCopied;
  
  /** Copy: The amount of data to currently copy from the current value */
  uint8_t currentCopyAmount;
  
  /** Copy: The buffer to copy values from one file to another */
  uint8_t valueBuffer[VALUE_COPY_BUFFER_LENGTH];
  
  /** getTotalKeys: The total valid keys in this open dictionary file */
  uint16_t totalKeys;
  
  /**
   * CommandState states
   * This is what the overall goal is to accomplish at the moment
   */
  enum {
    S_IDLE_COMMAND = 0,
    
    /** Open command received */
    S_COMMAND_OPEN,
    
    /** Close command received */
    S_COMMAND_CLOSE,
    
    /** Insert command received */
    S_COMMAND_INSERT,
    
    /** Retrieve command received */
    S_COMMAND_RETRIEVE,
    
    /** Remove command received */
    S_COMMAND_REMOVE,
    
    /** NextKey command received */
    S_COMMAND_NEXTKEY,
    
    /** getTotalKey command received */
    S_COMMAND_TOTALKEYS,
    
  };
    
    
  /** 
   * DictionaryState states
   * This is what the individual tasks are doing at the moment
   */
  enum {
    S_IDLE_DICTIONARY = 0,
    
    
    /** Insert: Insert the new keymeta */
    S_INSERT_KEY,
    
    /** Insert: Insert the new value */
    S_INSERT_VALUE,
    
    /** Insert: Deleted the old existing key */
    S_INSERT_CLEANUP,
    
    /** Insert: Copy a valid key from the original file to a new file */
    S_INSERT_KEYCOPY,
    
    /** Insert: Copy a valid value from the original file to a new file */
    S_INSERT_VALUECOPY,
    
    /** Insert: Change the client's file from the old to the new */
    S_INSERT_CHANGEFILES,
    
    /** Remove: Remove the given key */
    S_REMOVE_KEY,

    /** Retrieve: Retrieve a value from flash */
    S_RETRIEVE_VALUE,
   
    /** Open: Search for a duplicate entry for the last key */
    S_INIT_DUPLICATE, 

    /** Dictionary Check: Find if a file is a dictionary file */
    S_CHECK_DICTIONARY,
        
  };
  
  /**
   * SearchState states
   * This is what type of information the component
   * is searching for in the currentClient's file.
   */
  enum {
    S_IDLE_SEARCH = 0,
    
    /** Stop when the search finds a valid key */
    S_FIND_VALIDKEY,
    
    /** Stop when the search finds a key matching the currentKey */
    S_FIND_CURRENTKEY,
    
    /** Stop when an invalid key is encountered */
    S_FIND_INVALIDKEY,
    
    /** Do not stop until all keys are recorded for initialization */
    S_INIT_ALLKEYS,
    
  };
  
  /***************** Prototypes ****************/
  /** Traverse a newly opened file and pull out cache information */
  task void keySearchLoop();

  /** Append a new key entry at the writeOffset of the currentClient's file */
  task void appendNewKey();
  
  /** Search for the first key in the current client's open file */
  task void getFirstKey();
  
  /** Search for the next key in the current client's open file based on the current */
  task void getNextKey();
  
  /** Read a value from the original file to copy into the new file */
  task void readCopyValue();

  
  /** If the currentClient is not the Checkpoint, reset BlackbookState.toIdle */
  void resetStates();
  
  /** Close out any open file in the currentClient */
  void closeCurrentClient();
  
  /** Insert a keycache entry into the given client's cache */
  void insertCacheKey(uint8_t client, uint32_t key, uint16_t keyOffset, uint16_t valueCrc, uint16_t valueLength);
  
  /** Remove and fill in the given cache cacheIndex from the given client's cache */
  void removeCacheKey(uint8_t client, uint8_t cacheIndex);
  
  /** Remove all entries from the given client's cache */
  void clearCache(uint8_t client);
  
  /** Search the cache for a given key */
  keycache *searchCache(uint32_t searchKey, uint8_t startingIndex, uint8_t *indexHolder);
  
  /** Write a magic number to the given offset */  
  void writeMagicNumber(uint32_t offset, uint16_t magic);
 
  /** Adjust the currentSearchOffset and keep searching for a valid key */
  void continueSearch();
  
  /** Stop the current search on flash with the given result */
  void stopSearch(result_t result);
  

  /** Search for the currentKey in the currentClient's file on flash */
  void searchForCurrentKey();
  
  /** Search for a valid key in the currentClient's file on flash */
  void searchForValidKey();
  
  /** Search for an invalid key in the currentClient's file on flash */
  void searchForInvalidKey();
  
  /** Search and initialize the currentClient by traversing through all keys */
  void searchForAllKeys();
  
  /** Process the newly read keymeta based on the current states */
  void processKeyBuffer();
  
  
  /** Search is over for a key matching the currentKey */
  void currentKeyFound(uint32_t offset, result_t result);
  
  /** Search is over for a valid key */
  void validKeyFound(uint32_t offset, result_t result);
  
  /** Search is over for an invalid key */
  void invalidKeyFound(uint32_t offset, result_t result);
  
  /** All keys have been traversed in the current file for initialization */
  void allKeysFound(uint32_t finalOffset);
  
  
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    int i;
    for(i = 0; i < uniqueCount("BDictionary"); i++) {
      clearCache(i);
      clients[i].dictionaryFile = NULL;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
 
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /***************** BDictionary Commands ****************/
  /**
   * Open a BDictionary file.  If the file does not exist on flash, the
   * minimumSize will be used to set the length of the file.
   * @param fileName - name of the BDictionary file to open
   * @param minimumSize - the minimum reserved size for the file on flash.
   * @return SUCCESS if the file will be opened
   */
  command result_t BDictionary.open[uint8_t id](char *fileName, uint32_t minimumSize) {
    if(id != INTERNAL_DICTIONARY) {
      if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
        return FAIL;
      }
    }
    
    
    call CommandState.forceState(S_COMMAND_OPEN);
    
    currentClient = id;
    
    if(clients[currentClient].dictionaryFile != NULL) {
      // File already open
      resetStates();
      signal BDictionary.opened[currentClient](call NodeMap.getReserveLength(clients[currentClient].dictionaryFile), call NodeMap.getReserveLength(clients[currentClient].dictionaryFile) - clients[currentClient].writeOffset, SUCCESS);
      return SUCCESS;
    }
    
    call Util.filenameCpy(&clients[currentClient].fname, fileName);
    return call WriteAlloc.openForWriting(fileName, minimumSize, FALSE, TRUE);
  }
  
  /**
   * @return TRUE if the given parameterized interface has a file open
   */
  command bool BDictionary.isOpen[uint8_t id]() {
    return (clients[id].dictionaryFile != NULL);
  }
  
  /**
   * Because Dictionary files are special, and NodeMap does not give an
   * accurate reflection of what's going on with Dictionary file sizes,
   * this command will return the size of the Dictionary file up to the
   * point where valid data ends.
   * @return the size of the valid data in the open dictionary file
   */
  command uint32_t BDictionary.getFileLength[uint8_t id]() {
    if(clients[id].dictionaryFile != NULL) {
      return clients[id].writeOffset;
    }
    
    return 0;
  }
  
  
  /**
   * @return the total valid keys in the open dictionary file
   */
  command result_t BDictionary.getTotalKeys[uint8_t id]() {
    if(id != INTERNAL_DICTIONARY) {
      if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
        return FAIL;
      }
    }
    
    call CommandState.forceState(S_COMMAND_TOTALKEYS);
    currentClient = id;
    totalKeys = 0;
  
    if(clients[currentClient].dictionaryFile != NULL) {
      searchForValidKey();
      return SUCCESS;
    }
    
    resetStates();
    return FAIL;
  }
  
  /**
   * Close any opened BDictionary files
   * @return SUCCESS if the open BDictionary file was closed.
   */
  command result_t BDictionary.close[uint8_t id]() {
    currentClient = id;
    closeCurrentClient();
    signal BDictionary.closed[id](SUCCESS);
    return SUCCESS;
  }
  
  /**
   * Insert a key-value pair into the opened BDictionary file.
   * This will invalidate any old key-value pairs using the
   * associated key.
   *
   * The process of inserting a key can get tricky when space is running
   * low:
   *
   *   Check to see if the remaining write space in the
   *   client's open flashnode is less than the size of the key + value.
   *      
   *      If there isn't enough space:
   *        A. First evaluate the flashnode to see if we can solve the 
   *           problem by creating a new node.  If enough space would
   *           exist in the file by removing the invalid keys, then continue:
   *        B. Virtually delete the original file from flash, but keep its
   *           memory information local.
   *        C. WriteAlloc a new file with the original name and size
   *           (or potentially increase its size here).
   *        D. Insert all valid key-value pairs from the original
   *           flash space into to the new file.  Any previous valid
   *           key matching the new key to insert is replaced by the
   *           new key-value pair.
   *        E. Re-initialize the client's file into RAM.
   *
   *      If there is enough space:
   *        A. Locate any old valid key and invalidate it.
   *        B. Insert the new key-value pair at the end of the file.
   *
   *       
   * @param key - the key to use
   * @param value - pointer to a buffer containing the value to insert.
   * @param valueSize - the amount of bytes to copy from the buffer
   * @return SUCCESS if the key-value pair will be inserted
   */
  command result_t BDictionary.insert[uint8_t id](uint32_t key, void *value, uint16_t valueSize) {
    keycache *cacheEntry;
    uint8_t cacheIndex;
    
    if(id != INTERNAL_DICTIONARY) {
      if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
        return FAIL;
      }
    }
    
    call CommandState.forceState(S_COMMAND_INSERT);
    
    currentClient = id;
    currentKey = key;
    currentValuePtr = value;
    currentValueSize = valueSize;
    marker = ENTRY_INVALID;
      
    if(clients[currentClient].dictionaryFile == NULL) {
      // No open file
      resetStates();
      return FAIL;
    }
    
    if(call NodeMap.getReserveLength(clients[currentClient].dictionaryFile) - clients[currentClient].writeOffset < sizeof(keymeta) + currentValueSize) {
      // No more room in this file
      // We need to allocate a new file if there is at least one
      // invalid key in the current file.
      searchForInvalidKey();
    
    } else {
      if((cacheEntry = searchCache(currentKey, 0, &cacheIndex)) != NULL) {
        marker = cacheEntry->keyOffset;
        removeCacheKey(currentClient, cacheIndex);
        post appendNewKey();
        
      } else {
        searchForCurrentKey();
      }
    }
    
    return SUCCESS;
  }
  
  /**
   * Retrieve a key from the opened BDictionary file.
   *
   * Retrieving a key is done through this process:
   *  1. Look the key up in the cache. If it is found in the
   *     cache, read and retrieve the value from flash.
   *  2. If the key is not found in cache, read each key
   *     from the file starting at the beginning looking
   *     for a valid keymeta that matches the given key.
   *  3. If no key is found, then no key exists.
   * 
   * @param key - the key to find
   * @param valueHolder - pointer to the memory location to store the value
   * @param maxValueSize - used to prevent buffer overflows incase the
   *     recorded size of the value does not match the space allocated to
   *     the valueHolder
   * @return SUCCESS if the key will be retrieved.
   */
  command result_t BDictionary.retrieve[uint8_t id](uint32_t key, void *valueHolder, uint16_t maxValueSize) {
    keycache *cacheEntry;
    uint8_t cacheIndex;
    
    if(id != INTERNAL_DICTIONARY) {
      if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
        return FAIL;
      }
    }
    
    call CommandState.forceState(S_COMMAND_RETRIEVE);
    
    currentClient = id;
    currentKey = key;
    currentValuePtr = valueHolder;
    currentValueSize = maxValueSize;
    
    if(clients[currentClient].dictionaryFile == NULL) {
      // No open file
      resetStates();
      return FAIL;
    }
    
    if((cacheEntry = searchCache(currentKey, 0, &cacheIndex)) != NULL) {
      // Fast-forward our search offset to the location of the key
      // Then continue as if it were found on flash in the search loop.
      currentSearchOffset = cacheEntry->keyOffset;
      call SearchState.forceState(S_FIND_CURRENTKEY);
      post keySearchLoop();
      return SUCCESS;
    }

    if(clients[currentClient].recent[MAX_KEY_CACHE-1].keyOffset == ENTRY_INVALID) {
      // If the cache is not full, then we know
      // the key is not going to exist on flash. So don't bother.
      resetStates();
      signal BDictionary.retrieved[currentClient](currentKey, currentValuePtr, 0, FAIL);
      return SUCCESS;
    }
    
    // No key was found in cache and the cache is full, search the file.
    searchForCurrentKey();
    return SUCCESS;
  }
  
  /**
   * Get the last key inserted into the file.
   * @return the last key, or 0xFFFFFFFF (-1) if it doesn't exist
   */
  command uint32_t BDictionary.getLastKey[uint8_t id]() {
    currentClient = id;
    
    if(clients[currentClient].dictionaryFile != NULL && clients[currentClient].recent[0].keyOffset != ENTRY_INVALID) {
      return clients[currentClient].recent[0].key;
    }
    
    return -1;
  }
  
  /**
   * Remove a key from the opened dictionary file
   * @param key - the key for the key-value pair to remove
   * @return SUCCESS if the attempt to remove the key will proceed
   */
  command result_t BDictionary.remove[uint8_t id](uint32_t key) {
    keycache *cacheEntry;
    uint8_t cacheIndex;
    
    if(id != INTERNAL_DICTIONARY) {
      if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
        return FAIL;
      }
    }
    
    call CommandState.forceState(S_COMMAND_REMOVE);
    call DictionaryState.forceState(S_REMOVE_KEY);
    
    currentClient = id;
    currentKey = key;

    if(clients[currentClient].dictionaryFile == NULL) {
      // No open file
      resetStates();
      return FAIL;
    }
    
    // First try to find the key in cache:
    if((cacheEntry = searchCache(currentKey, 0, &cacheIndex)) != NULL) {
      marker = clients[currentClient].recent[cacheIndex].keyOffset;
      removeCacheKey(currentClient, cacheIndex);
      writeMagicNumber(marker, KEY_INVALID);
      return SUCCESS;
    }

    // The key was not found in cache. Attempt to find it on flash.
    searchForCurrentKey();
    return SUCCESS;
  }
  
  
  /**
   * This command will signal event nextKey
   * when the first key is found.
   * @return SUCCESS if the command will be processed.
   */
  command result_t BDictionary.getFirstKey[uint8_t id]() {
    if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
      return FAIL;
    }
    
    currentClient = id;
    
        
    if(clients[currentClient].dictionaryFile == NULL) {
      // No open file
      resetStates();
      return FAIL;
    }
    
    call CommandState.forceState(S_COMMAND_NEXTKEY);
    
    post getFirstKey();
    return SUCCESS;
  }
    
  
  /**
   * Get the next recorded key in the file, based on the current
   * key being passed in.  The current key will be located first,
   * and then the next valid key after it will be returned.
   *
   * When there are no more keys after the present key, or
   * the present key is not valid, the BDictionary will signal FAIL.
   *
   * This way, you can loop through the keys of the file at your 
   * leisure, starting at the beginning (and knowing it) or reaching
   * the end (and knowing it).
   *
   * @param presentKey - get the next valid key after this present key
   * @return SUCCESS if the command will be processed
   */
  command result_t BDictionary.getNextKey[uint8_t id](uint32_t presentKey) {
    if(id != INTERNAL_DICTIONARY) {
      if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
        return FAIL; 
      }
    }
    
    currentClient = id;
    currentKey = presentKey;
    
    if(clients[currentClient].dictionaryFile == NULL) {
      // No open file
      resetStates();
      return FAIL;
    }
    
    call CommandState.forceState(S_COMMAND_NEXTKEY);
    
    post getNextKey();
    return SUCCESS;
  }
  
  /**
   * Find out if a given file is a dictionary file
   * @param fileName - the name of the file
   * @return SUCCESS if the command will go through
   */
  command result_t BDictionary.isFileDictionary[uint8_t id](char *fileName) {
    filename focusedFilename;
    file *focusedFile;
    
    if(id != INTERNAL_DICTIONARY) {
      if(!call BlackbookState.requestState(S_DICTIONARY_BUSY)) {
        return FAIL;
      }
    }
    
    call Util.filenameCpy(&focusedFilename, fileName);
    
    if((focusedFile = call NodeMap.getFile(&focusedFilename)) != NULL) {
      if(!call InternalDictionary.isFileDictionary[id](focusedFile)) {
        resetStates();
        return FAIL;
      }
      
      return SUCCESS;
    }
    
    resetStates();
    return FAIL;
  }
  
  
  /***************** Internal Dictionary Commands ****************/
  /**
   * Internal method of checking to see whether a file is a dictionary file
   * @param focusedFile - the file to check
   * @return SUCCESS if the check will be made
   */
  command result_t InternalDictionary.isFileDictionary[uint8_t id](file *focusedFile) {
    currentClient = id;
    call DictionaryState.forceState(S_CHECK_DICTIONARY);
    dictionaryHeader = 0;
    if(call Fileio.readData(focusedFile, 0x0, &dictionaryHeader, sizeof(dictionaryHeader))) {
      return SUCCESS;
    }
    
    call DictionaryState.toIdle();
    return FAIL;
  }
  
  /***************** WriteAlloc Events ***************/
  /**
   * The write open process completed
   * @param openFile - the file that was opened for writing 
   * @param writeNode - the flashnode to write to
   * @param result - SUCCESS if the file was correctly opened
   */
  event void WriteAlloc.openedForWriting(file *openFile, flashnode *writeNode, uint32_t totalSize, result_t result) {
    if(call CommandState.getState() == S_COMMAND_OPEN) {
      if(result) {
        currentSearchOffset = sizeof(dictionaryHeader);
        writeNode->state = NODE_VALID;
        clients[currentClient].dictionaryFile = openFile;
        clients[currentClient].writeOffset = sizeof(dictionaryHeader);
        searchForAllKeys();
        return;

      } else {
        clients[currentClient].dictionaryFile = NULL;
        resetStates();
        signal BDictionary.opened[currentClient](0, 0, FAIL);
      }
      
    } else if(call CommandState.getState() == S_COMMAND_INSERT) {
      if(!result) {
        resetStates();
        signal BDictionary.inserted[currentClient](currentKey, currentValuePtr, currentValueSize, FAIL);
        return;
      }
      
      clearCache(currentClient);
      currentFile = openFile;
      currentSearchOffset = sizeof(dictionaryHeader);
      currentWriteOffset = 0;
      
      searchForValidKey();
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
    if(call DictionaryState.getState() == S_INSERT_KEY) {
      insertCacheKey(currentClient, keyBuffer.key, clients[currentClient].writeOffset, keyBuffer.valueCrc, keyBuffer.valueLength); 
      clients[currentClient].writeOffset += sizeof(keymeta);
      call DictionaryState.forceState(S_INSERT_VALUE);
      call Fileio.writeData(clients[currentClient].dictionaryFile, clients[currentClient].writeOffset, currentValuePtr, currentValueSize);
    
    } else if(call DictionaryState.getState() == S_INSERT_VALUE) {
      clients[currentClient].writeOffset += currentValueSize;
      
      if(marker != ENTRY_INVALID) {
        // There's an existing key that needs to be invalidated
        call DictionaryState.forceState(S_INSERT_CLEANUP);
        writeMagicNumber(marker, KEY_INVALID);

      } else {
        call Fileio.flushData();
      }
 
    } else if(call DictionaryState.getState() == S_INSERT_KEYCOPY) {
      // The valid key was copied from clients[currentClient].dictionaryFile->firstNode
      // to currentFile->firstNode at the currentWriteOffset.
      // Now copy the value over in pieces, however big it is.
      // The currentCopyAmount will hold the length of each piece
      // being copied, and the currentWriteOffset will contain
      // the offset in the new file to place the new chunk of data.
      insertCacheKey(currentClient, keyBuffer.key, currentWriteOffset, keyBuffer.valueCrc, keyBuffer.valueLength);
      currentWriteOffset += sizeof(keymeta);
      totalAmountCopied = 0;
      post readCopyValue();
         
    } else if(call DictionaryState.getState() == S_INSERT_VALUECOPY) {
      currentWriteOffset += currentCopyAmount;
      totalAmountCopied += currentCopyAmount;
      
      if(totalAmountCopied < keyBuffer.valueLength) {
        post readCopyValue();
        
      } else {
        call DictionaryState.toIdle();
        call SearchState.forceState(S_FIND_VALIDKEY);
        continueSearch();
      }
        
    } else if(call DictionaryState.getState() != S_IDLE_DICTIONARY) {
      call Fileio.flushData();
    
    }
  }
  
  /**
   * Data was read from the file
   * @param *readBuffer - pointer to the location where the data was stored
   * @param amountRead - the amount of data actually read
   * @param result - SUCCESS if the data was successfully read
   */
  event void Fileio.readDone(void *readBuffer, uint32_t amountRead, result_t result) {
    if(call DictionaryState.getState() == S_IDLE_DICTIONARY && call SearchState.getState() == S_IDLE_SEARCH) {
      // Not for me
      return;
    }
    
    if(call DictionaryState.getState() == S_RETRIEVE_VALUE) {
      result &= (call GenericCrc.crc16(0, currentValuePtr, amountRead) == currentValueCrc);
      resetStates();
      signal BDictionary.retrieved[currentClient](currentKey, currentValuePtr, amountRead, result);
      return;
      
    } else if(call DictionaryState.getState() == S_INSERT_VALUECOPY) {
      call Fileio.writeData(currentFile, currentWriteOffset, &valueBuffer, currentCopyAmount);
      return;
   
    } else if(call DictionaryState.getState() == S_CHECK_DICTIONARY) {
      resetStates();
      signal BDictionary.fileIsDictionary[currentClient](dictionaryHeader == DICTIONARY_HEADER, result);
      return;
    }
    
    
    if(keyBuffer.magicNumber == KEY_VALID) {
      if(call SearchState.getState() == S_INIT_ALLKEYS) {
        insertCacheKey(currentClient, keyBuffer.key, currentSearchOffset, keyBuffer.valueCrc, keyBuffer.valueLength);
        continueSearch();
      
      } else if(call SearchState.getState() == S_FIND_CURRENTKEY) {
        if(keyBuffer.key == currentKey) {
          call SearchState.toIdle();
          currentKeyFound(currentSearchOffset, SUCCESS);
         
        } else {
          if(oldestValidCacheIndex != 0xFF) {
            if(clients[currentClient].recent[oldestValidCacheIndex].key == keyBuffer.key) {
              // Reached the point on flash where the cache steps in.
              // There is no more left to search.
              stopSearch(FAIL);
              return;
            }
          }
          
          continueSearch();
        }
        
      } else if(call SearchState.getState() == S_FIND_VALIDKEY) {
        call SearchState.toIdle();
        validKeyFound(currentSearchOffset, SUCCESS);
      
      } else if(call SearchState.getState() == S_FIND_INVALIDKEY) {
        continueSearch();
        
      }
      
    } else if(keyBuffer.magicNumber == KEY_INVALID) {
      if(call SearchState.getState() == S_FIND_INVALIDKEY) {
        invalidKeyFound(currentSearchOffset, SUCCESS);
        return;
      }
      
      continueSearch();
      
    } else if(keyBuffer.magicNumber == KEY_EMPTY) {
      // Reached the end of the valid keys in the file
      stopSearch(FAIL);
      
    } else {
      // Unexpected magic number - something's probably corrupt.
      if(call CommandState.getState() == S_COMMAND_OPEN) {
        closeCurrentClient();
        resetStates();
        signal BDictionary.opened[currentClient](0, 0, FAIL);
        return;
      }
    } 
  }
  
  /**
   * Data was flushed to flash
   * @param result - SUCCESS if the data was flushed
   */
  event void Fileio.flushDone(result_t result) {
    uint8_t dictionaryState = call DictionaryState.getState();
    
    if(dictionaryState == S_IDLE_DICTIONARY) {
      // Not for me
      return;
    }
    
    resetStates();
    
    if(dictionaryState == S_INSERT_VALUE || dictionaryState == S_INSERT_CLEANUP) {
      signal BDictionary.inserted[currentClient](currentKey, currentValuePtr, currentValueSize, result);

    } else if(dictionaryState == S_REMOVE_KEY) {
      signal BDictionary.removed[currentClient](currentKey, result);
    
    } else if(dictionaryState == S_INIT_DUPLICATE) {
      signal BDictionary.opened[currentClient](call NodeMap.getReserveLength(clients[currentClient].dictionaryFile), call NodeMap.getReserveLength(clients[currentClient].dictionaryFile) - clients[currentClient].writeOffset, SUCCESS);
      
    }  
  }
  
  
  /***************** NodeShop Events ****************/
  /** 
   * The node's metadata was written to flash
   * @param focusedNode - the flashnode that metadata was written for
   * @param result - SUCCESS if it was written
   */
  event void NodeShop.metaWritten(flashnode *focusedNode, result_t result) {
    if(call DictionaryState.getState() == S_INSERT_CHANGEFILES) {
      // Done turning our constructing file into a valid file. Now delete
      // the original.
    
      // Note that if dictionary files ever are allowed to span more than one node,
      // we need to be deleting all the nodes in this file instead of one.
      call NodeShop.deleteNode(clients[currentClient].dictionaryFile->firstNode);
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
    if(call DictionaryState.getState() == S_INSERT_CHANGEFILES) {
      focusedNode->state = NODE_EMPTY;
      clients[currentClient].dictionaryFile->state = FILE_EMPTY;
      clients[currentClient].dictionaryFile = currentFile;
      clients[currentClient].writeOffset = currentWriteOffset;
      post appendNewKey();
    }
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
   * Read the next entry from flash
   */
  task void keySearchLoop() {
    call Fileio.readData(clients[currentClient].dictionaryFile, currentSearchOffset, &keyBuffer, sizeof(keymeta));
  }
  
  
  /** 
   * Used on key-value insertion
   * Create the keyBuffer to write from the current values and insert it
   */
  task void appendNewKey() {
    call DictionaryState.forceState(S_INSERT_KEY);
    keyBuffer.magicNumber = KEY_VALID;
    keyBuffer.key = currentKey;
    keyBuffer.valueCrc = call GenericCrc.crc16(0, currentValuePtr, currentValueSize);
    keyBuffer.valueLength = currentValueSize;
    call Fileio.writeData(clients[currentClient].dictionaryFile, clients[currentClient].writeOffset, &keyBuffer, sizeof(keymeta));
  }
  
  /**
   * Search the cache, if appropriate, for the first key.  If 
   * we can't search the cache for the first key then we'll search
   * the flash for the first valid key.
   */
  task void getFirstKey() {
    int i;
    // First try to find the first key in cache.
    // This requires, at the minimum, the last entry of 
    // cache to be empty in order to recognize the first key.
    if(clients[currentClient].recent[MAX_KEY_CACHE-1].keyOffset == ENTRY_INVALID) {
      for(i = MAX_KEY_CACHE-2; i+1 > 0; i--) {
        if(clients[currentClient].recent[i].keyOffset != ENTRY_INVALID) {
          // This is the first key in the file.
          resetStates();
          signal BDictionary.nextKey[currentClient](clients[currentClient].recent[i].key, SUCCESS);
          return;
        }
      }
    }
    
    // Or else, the first key must be found in flash.
    currentSearchOffset = sizeof(dictionaryHeader);
    searchForValidKey();
    return;
  }
  
  
  /** 
   * Get the next key in the current client's file based on the current key
   */
  task void getNextKey() {
    int i;
    // First search the cache.
    if(clients[currentClient].recent[0].keyOffset != ENTRY_INVALID && clients[currentClient].recent[0].key == currentKey) {
      // There is no next key.
      resetStates();
      signal BDictionary.nextKey[currentClient](currentKey, FAIL);
      return;
    }
    
    for(i = 1; i < MAX_KEY_CACHE; i++) {
      if(clients[currentClient].recent[i].keyOffset != ENTRY_INVALID && clients[currentClient].recent[i].key == currentKey) {
        resetStates();
        signal BDictionary.nextKey[currentClient](clients[currentClient].recent[i-1].key, SUCCESS);
        return;
      }
    }
    
    // The present key is not in cache, search the flash
    searchForCurrentKey();
  }
  
  /**
   * Performs the read portion of a minimum two-part operation
   * Copy a value from clients[currentClient].dictionaryFile->firstNode
   * where the key in the original file is at the offset currentSearchOffset
   * and the keymeta is already stored in keyBuffer,
   * and the currentCopyAmount will store the amount of the value
   * copied into the valueBuffer, and the currentWriteOffset
   * contains the location in the new file to write the chunk of
   * data to.  The totalCopyAmount will store the total amount
   * of value copied so far.
   */
  task void readCopyValue() {
    call DictionaryState.forceState(S_INSERT_VALUECOPY);
    currentCopyAmount = keyBuffer.valueLength - totalAmountCopied;
    if(currentCopyAmount > sizeof(valueBuffer)) {
      currentCopyAmount = sizeof(valueBuffer);
    }
    
    call Fileio.readData(clients[currentClient].dictionaryFile, currentSearchOffset + sizeof(keymeta) + totalAmountCopied, &valueBuffer, currentCopyAmount);
  }
  

  /***************** Functions ****************/  
  /**
   * Close out any open file in the currentClient.
   */
  void closeCurrentClient() {
    if(clients[currentClient].dictionaryFile == NULL) {
      // This client has no open dictionary.
      return;
    }
    
    clients[currentClient].dictionaryFile->state = FILE_IDLE;
    clients[currentClient].dictionaryFile->firstNode->state = NODE_VALID;    
    clients[currentClient].dictionaryFile = NULL;
    
    memset(&clients[currentClient].recent, 0xFF, sizeof(clients[currentClient].recent));
    return;
  }
  
  
  /**
   * Reset all states to idle 
   */
  void resetStates() {
    call DictionaryState.toIdle();
    call CommandState.toIdle();
    call SearchState.toIdle();
    if(currentClient != INTERNAL_DICTIONARY) {
      call BlackbookState.toIdle();
    }
  }
  
  /**
   * Insert a key into the given client's key cache
   * @param client - the client to insert the keycache entry into
   * @param key - the key to record
   * @param keyOffset - the key's offset in the client's file
   */
  void insertCacheKey(uint8_t client, uint32_t key, uint16_t keyOffset, uint16_t valueCrc, uint16_t valueLength) {
    int i;
    for(i = MAX_KEY_CACHE-1; i > 0; i--) {
      memcpy(&clients[client].recent[i], &clients[client].recent[i-1], sizeof(keycache));
    }
    clients[client].recent[0].key = key;
    clients[client].recent[0].keyOffset = keyOffset;
  }
  
  /**
   * Remove the given zero-indexed cache element
   * from the given client's cache. This shifts
   * all the elements in to fill in the removed
   * element's spot, ensuring we don't lose any
   * cache information from the end when inserting a new key.
   * @param client - the client to remove from
   * @param cacheIndex - the zero-indexed element to remove.
   */
  void removeCacheKey(uint8_t client, uint8_t cacheIndex) {
    for( ; cacheIndex + 1 < MAX_KEY_CACHE; cacheIndex++) {
      memcpy(&clients[client].recent[cacheIndex], &clients[client].recent[cacheIndex+1], sizeof(keycache));
    }
    clients[client].recent[MAX_KEY_CACHE-1].keyOffset = ENTRY_INVALID;
  }
  
  /** 
   * Remove all entries from the given client's cache 
   */
  void clearCache(uint8_t client) {
    memset(&clients[client].recent, 0xFF, sizeof(clients[client].recent));
  }
  
  /**
   * Search the cache for the given key
   * @param searchKey - the key to search for in the current client's cache
   * @param startingIndex - the index to start searching from, backwards
   * @param indexHolder - pointer to a uint8_t storage location for the index number
   * @return a pointer to the keycache if found, NULL if not
   */
  keycache *searchCache(uint32_t searchKey, uint8_t startingIndex, uint8_t *indexHolder) {
    uint8_t i; 
    for(i = startingIndex; i < MAX_KEY_CACHE; i++) {
      if(clients[currentClient].recent[i].keyOffset != ENTRY_INVALID && clients[currentClient].recent[i].key == searchKey) {
        *indexHolder = i;
        return &clients[currentClient].recent[i];
      }
    }
    return NULL;
  }
  
  /**
   * Write a magic number to flash
   * Your state will need to be set before entering to catch the Fileio.writeDone
   * event.
   * @param offset - the offset into the file to write the magic number
   * @param magic - the magic number to write.
   */
  void writeMagicNumber(uint32_t offset, uint16_t magic) {
    magicNumber = magic;
    call Fileio.writeData(clients[currentClient].dictionaryFile, offset, &magicNumber, sizeof(magic));
  }
  
  
  /**
   * Adjust the currentSearchOffset and continue the search
   * for a valid key in the currentClient's file.
   */
  void continueSearch() {
    currentSearchOffset += sizeof(keymeta) + keyBuffer.valueLength;
    if(currentSearchOffset + sizeof(keymeta) + 1 < call NodeMap.getReserveLength(clients[currentClient].dictionaryFile)) {
      post keySearchLoop();
      
    } else {
      // End of file. Stop the search.
      stopSearch(FAIL);
    }
  }
  
  /**
   * Stop the current search on flash with the given result.
   */
  void stopSearch(result_t result) {
    uint8_t searchState = call SearchState.getState();
    call SearchState.toIdle();
    
    if(searchState == S_FIND_VALIDKEY) {
      validKeyFound(currentSearchOffset, result);
      
    } else if(searchState == S_FIND_CURRENTKEY) {
      currentKeyFound(currentSearchOffset, result);
      
    } else if(searchState == S_FIND_INVALIDKEY) {
      invalidKeyFound(currentSearchOffset, result);
      
    } else if(searchState == S_INIT_ALLKEYS) {
      allKeysFound(currentSearchOffset);
    }
  }
  
  
  /**
   * Search for the currentKey in the currentClient's file on flash
   * This will execute currentKeyFound(..) when done
   */
  void searchForCurrentKey() {
    int i;
    currentSearchOffset = sizeof(dictionaryHeader);
    
    // Locate the oldest recent key entry in cache.
    // This does not search the cache!
    // This is used so we only read the file up to the point
    // of where the cache steps in.  We don't need to read
    // any values from flash after the oldest value in cache because
    // the current key won't be there, assuming we already checked the
    // cache for the key's existance.
    oldestValidCacheIndex = 0xFF;
    
    for(i = MAX_KEY_CACHE - 1; i > 0; i++) {
      if(clients[currentClient].recent[i].keyOffset != ENTRY_INVALID) {
        oldestValidCacheIndex = (uint8_t) i;
      }
    }
    
    call SearchState.forceState(S_FIND_CURRENTKEY);
    post keySearchLoop();
  }
  
  /** 
   * Search for a valid key in the currentClient's file on flash 
   * This will execute validKeyFound(..) when done
   * The search will begin in the file at the currentSearchOffset,
   * which should already be defined.  You can call this 
   * function over and over the continue the search after
   * the currentSearchOffset is updated manually, or you can
   * set the SearchState to S_FIND_VALIDKEY yourself and
   * then call continueSearch to automatically update the 
   * currentSearchOffset as long as the keyBuffer data
   * from the last search is not touched.
   */
  void searchForValidKey() {
    call SearchState.forceState(S_FIND_VALIDKEY);
    post keySearchLoop();
  }
  
  /** 
   * Search for an invalid key in the currentClient's file on flash
   * This will execute invalidKeyFound(..) when done.
   */
  void searchForInvalidKey() {
    currentSearchOffset = sizeof(dictionaryHeader);
    call SearchState.forceState(S_FIND_INVALIDKEY);
    post keySearchLoop();
  }
  
  /** 
   * Search and initialize the currentClient by traversing 
   * through all keys
   * This will execute allKeysFound(..) when done and setup
   * the currentClient's cache and information while traversing.
   */
  void searchForAllKeys() {
    currentSearchOffset = sizeof(dictionaryHeader);
    call SearchState.forceState(S_INIT_ALLKEYS);
    post keySearchLoop();
  }
 
  
  /**
   * A valid key on flash matching the currentKey
   * was found. Do what you want with it based on the current states.
   * @param offset - data offset in the currentClient's file to 
   *     the keymeta
   * @param result - SUCCESS if the key was really found.
   */
  void currentKeyFound(uint32_t offset, result_t result) {
    if(call CommandState.getState() == S_COMMAND_NEXTKEY) {
      if(result) {
        // Present key found, get the valid key after it:
        call SearchState.forceState(S_FIND_VALIDKEY);
        continueSearch();
        
      } else {
        // The present key was not found in the file.
        resetStates();
        signal BDictionary.nextKey[currentClient](currentKey, FAIL);
      }
      return;
    
    } else if(call CommandState.getState() == S_COMMAND_INSERT) {
      if(result) {
        // Key found, mark it for deletion after insertion is complete
        marker = offset;
      }
      
      post appendNewKey();
      return;
    
    } else if(call CommandState.getState() == S_COMMAND_OPEN) {
      if(result) {
        if(offset != marker) {
          // This is a duplicate entry. Delete the last entry, which is
          // located at the marker.
          writeMagicNumber(marker, KEY_INVALID);
          return;
        }   
      }
      
      // No duplicate keys found, signal file opened correctly
      call Fileio.flushData();
      
    } else if(call CommandState.getState() == S_COMMAND_REMOVE) {
      if(result) {
        writeMagicNumber(offset, KEY_INVALID);
        return;
      }
      
      // Key not found - consider it removed.
      call Fileio.flushData();
        
    } else if(call CommandState.getState() == S_COMMAND_RETRIEVE) {
      if(result && currentValueSize >= keyBuffer.valueLength) {
        call DictionaryState.forceState(S_RETRIEVE_VALUE);
        currentValueCrc = keyBuffer.valueCrc;
        call Fileio.readData(clients[currentClient].dictionaryFile, offset + sizeof(keymeta), currentValuePtr, keyBuffer.valueLength);
        return;
      }
      
      // No key found on flash to retrieve or read failed.
      resetStates();
      signal BDictionary.retrieved[currentClient](currentKey, currentValuePtr, 0, FAIL);
    }
  }
  
  /**
   * A valid key was found for the currentClient on flash
   * Do what you want with it based on the current states.
   * @param offset - data offset to the keymeta
   * @param result - SUCCESS if a valid key was found after
   *     the starting currentSearchOffset
   */
  void validKeyFound(uint32_t offset, result_t result) {
    if(call CommandState.getState() == S_COMMAND_NEXTKEY) {
      resetStates();
      signal BDictionary.nextKey[currentClient](keyBuffer.key, result); 
    
    } else if(call CommandState.getState() == S_COMMAND_TOTALKEYS) {
      if(result) {
        totalKeys++;
        call SearchState.forceState(S_FIND_VALIDKEY);
        continueSearch();
        
      } else {
        resetStates();
        signal BDictionary.totalKeys[currentClient](totalKeys);
      }
      
    } else if(call CommandState.getState() == S_COMMAND_INSERT) {
      if(result) {
        if(keyBuffer.key == currentKey) {
          // Do not copy over the key we're trying to replace
          call SearchState.forceState(S_FIND_VALIDKEY);
          continueSearch();
          return;  
        }
        
        call DictionaryState.forceState(S_INSERT_KEYCOPY);
        call Fileio.writeData(currentFile, currentWriteOffset, &keyBuffer, sizeof(keymeta));
      
      } else {
        // We're done finding valid keys in the old file.
        // 1. Change the state of our new file's flashnode to VALID
        // 2. Write the metadata to flash to reflect that flashnode is valid
        //    If a catastrophic failure occurs here, 2 valid files with
        //    the same name will be found on flash.  Either one can
        //    be deleted at boot.
        // 3. Delete the original node, and make its file EMPTY.
        // 4. Set the current client's dictionary file to the currentFile.
        
        currentFile->firstNode->state = NODE_VALID;
        call DictionaryState.forceState(S_INSERT_CHANGEFILES);
        call NodeShop.writeNodemeta(NULL, currentFile->firstNode, NULL);
      }
    }
  }
  
  /**
   * An invalid key was found in the currentClient's file on flash
   * Do what you want with it based on the current states
   * @param offset - data offset to the keymeta
   * @param result - SUCCESS if an invalid key was found.
   */
  void invalidKeyFound(uint32_t offset, result_t result) {
    if(result) {
      // An invalid key was found, so the valid keys from this
      // file can be moved to a new file.  Force a new dictionary
      // to be created and fill in its name on flash and in the NodeMap later.
      // This would be a good spot, or at least a good way to increase the 
      // size of the dictionary file, too.
      

      if(call WriteAlloc.openForWriting(clients[currentClient].fname.getName, clients[currentClient].dictionaryFile->firstNode->reserveLength, TRUE, TRUE)) {
        return;
      }
    }
      
    // No invalid key found, the associated file wasn't found, or write failed
    resetStates();
    signal BDictionary.inserted[currentClient](currentKey, currentValuePtr, currentValueSize, FAIL);
  }
  
  /**
   * All keys have been found in the currentClient's file.
   * This concludes opening a file.
   * @param finalOffset - the address we can write to next
   * @param result - SUCCESS if all keys were found
   */
  void allKeysFound(uint32_t finalOffset) {
    uint8_t cacheIndex;
 
    clients[currentClient].writeOffset = finalOffset;
          
    call DictionaryState.forceState(S_INIT_DUPLICATE);
    
    // Look for duplicates if there are at least 2 keys
    if(clients[currentClient].recent[1].keyOffset != ENTRY_INVALID) {
      // Search for a duplicate to the last entry in the file
      // If a duplicate is found, we'll erase the latest entry.
      currentKey = clients[currentClient].recent[0].key;
      marker = clients[currentClient].recent[0].keyOffset;
      
      if(searchCache(currentKey, 1, &cacheIndex) != NULL) {
        removeCacheKey(currentClient, 0);
        writeMagicNumber(marker, KEY_INVALID);
        return;
        
      } else if(clients[currentClient].recent[MAX_KEY_CACHE-1].keyOffset != ENTRY_INVALID) {
        searchForCurrentKey();
        return;
      }
    }

    if(clients[currentClient].recent[0].keyOffset == ENTRY_INVALID) {
      // There are no keys in this file,
      // Write the dictionary header
      // This is picked up by the call DictionaryState.getState() != IDLE in the writeDone event:
      dictionaryHeader = DICTIONARY_HEADER;
      call Fileio.writeData(clients[currentClient].dictionaryFile, 0x0, &dictionaryHeader, sizeof(dictionaryHeader));
      return;
    }
    
    // Done opening the file, signal opened
    call Fileio.flushData();
  }
  
  
  /***************** Defaults ****************/
  default event void BDictionary.opened[uint8_t id](uint32_t totalSize, uint32_t remainingBytes, result_t result) {
  }

  default event void BDictionary.closed[uint8_t id](result_t result) {
  }

  default event void BDictionary.inserted[uint8_t id](uint32_t key, void *value, uint16_t valueSize, result_t result) {
  }

  default event void BDictionary.retrieved[uint8_t id](uint32_t key, void *valueHolder, uint16_t valueSize, result_t result) {
  }

  default event void BDictionary.removed[uint8_t id](uint32_t key, result_t result) {
  }
  
  default event void BDictionary.nextKey[uint8_t id](uint32_t nextKey, result_t result) {
  }
  
  default event void BDictionary.fileIsDictionary[uint8_t id](bool isDictionary, result_t result) {
  }
  
  default event void BDictionary.totalKeys[uint8_t id](uint16_t keys) {
  }
  
}

