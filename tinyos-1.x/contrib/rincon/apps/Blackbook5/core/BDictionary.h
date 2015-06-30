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
 * Keeping the most recently used keys from a file in memory 
 * decreases search time at the expense of RAM.
 */
typedef struct keycache {

  /** The key */
  uint32_t key;
  
  /** 
   * The data offset in the file to reach the beginning of the key
   * 0xFFFF means this entire cache key is invalid 
   */
  uint32_t keyOffset;
  
} keycache;


/**
 * Each client can have an open dictionary
 * simultaneously.  This structure keeps
 * track of the client's dictionary information
 * and state 
 */
typedef struct clientDictionary {

  /** Pointer to the node containing this client's dictionary */
  file *dictionaryFile;
  
  /** The data offset to the location of the next key write address */
  uint32_t writeOffset;

  /** The latest written keys in the file */
  keycache recent[MAX_KEY_CACHE];

  /** The name of the client's dictionary file to store in RAM */
  filename fname;
  
} clientDictionary;
  

/**
 * This is a key-value pair to be inserted into
 * a Dictionary file.  The value can be any size,
 * and the address of the valueStart variable
 * is where to start writing the data
 */
typedef struct keymeta {
  
  /** The magic number for a valid key-value pair entry */
  uint16_t magicNumber;
  
  /** The key */
  uint32_t key;
  
  /** The CRC of the value */
  uint16_t valueCrc;
    
  /** The length of the value */
  uint16_t valueLength;

} keymeta;



/**
 * Dictionary Magic Words
 */
enum {
  KEY_EMPTY = 0xFFFF,      // binary 1111
  KEY_VALID = 0xAAAA,      // binary 1010
  KEY_INVALID = 0x8888,    // binary 1000
  
  ENTRY_INVALID = 0xFFFFFFFF,
  
  DICTIONARY_HEADER = 0xD1C7,
};








