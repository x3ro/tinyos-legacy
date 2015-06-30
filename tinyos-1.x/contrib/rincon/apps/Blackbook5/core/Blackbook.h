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

#ifndef blackbook
#define blackbook

/**
 * Blackbook Definitions v.3
 * @author David Moss (dmm@rincon.com)
 */

#include "BlackbookConst.h"

/** 
 * This is a complete name of a file that we can pass around Blackbook
 * and not worry about whether or not enough bytes were allocated for
 * the filename.
 */
typedef struct filename {

  /** The name of a file */
  char getName[FILENAME_LENGTH];

} filename;


/** 
 * This is the nodemeta information kept at the start of each 
 * flashnode on flash
 */
typedef struct nodemeta {

  /** Magic number to detect valid metadata. This is after dataCrc for finalizing */
  uint16_t magicNumber;
  
  /** Length of the space reserved for this flashnode on flash */
  uint32_t reserveLength;
  
  /** The CRC of the filename this flashnode is associated with */
  uint16_t filenameCrc;
  
  /** The element of the file this flashnode represents, 0 for the first flashnode */
  uint16_t fileElement;

} nodemeta;


/** 
 * This is the filemeta information located directly after nodemeta
 * information for the first flashnode of a file on flash
 */
typedef struct filemeta {

  /** Name of the file */
  struct filename name;
  
} filemeta;


/** 
 * This is the flashnode information kept in memory for each node
 */
typedef struct flashnode {
  /** The address of this flashnode on flash */
  uint32_t flashAddress;
  
  /** The next flashnode in the file after this one */
  struct flashnode *nextNode;
  
  /** The total length of valid data written to this flashnode */
  uint16_t dataLength;

  /** The total length of space reserved for this flashnode */
  uint32_t reserveLength;
  
  /** The current CRC of the flashnode */
  uint16_t dataCrc;

  /** The CRC of the filename from the file this flashnode is associated with */
  uint16_t filenameCrc;
  
  /** The state of the flashnode */
  uint8_t state;

  /** The index this flashnode belongs to in its entire file */
  uint8_t fileElement;

} flashnode;


/** 
 * This is the information kept for each file in RAM memory 
 */
typedef struct file {

  /** The first flashnode of this file */
  flashnode *firstNode;
  
  /** The calculated crc of the file, so we don't have to calculate it every time */
  uint16_t filenameCrc;
  
  /** The state of this file */
  uint8_t state;
  
} file;


/**
 * This is the sector information kept
 * in RAM for every sector on flash.
 */
typedef struct flashsector {
  
  /** Next page number available for writing */
  uint16_t writePage;
  
  /** Total amount of valid nodes on this sector */
  uint8_t totalNodes;
  
  /** This sector's volume ID, and start address from calculation */
  uint8_t index;
  
  /** FALSE if this sector has no open write files */
  bool inUse;
  
} flashsector;



/**
 * This is the checkpoint struct that is inserted
 * into a key-value pair in the Checkpoint file
 */
typedef struct checkpoint {

  /** Node's filename CRC for verification */
  uint16_t filenameCrc;
  
  /** The CRC of the data contained up to the dataLength of the flashnode */
  uint16_t dataCrc;

  /** Length of the node's data */ 
  uint16_t dataLength;
  
  /** TRUE if this flashnode is still available for writing */
  bool writable;
  
} checkpoint;


/** Possible flashnode States */
enum {
  /** The flashnode can be used by anything */
  NODE_EMPTY,
  
  /** This is a special constructing flashnode that is to be deleted if the mote is rebooted */
  NODE_CONSTRUCTING,
  
  /** The flashnode is valid and can be written to */
  NODE_VALID,

  /** This flashnode is valid and cannot be written to */
  NODE_LOCKED,
  
  /** This flashnode exists virtually, but no info has been written to flash */
  NODE_TEMPORARY,
  
  /** This flashnode was found on flash, but is not valid */
  NODE_DELETED,
  
  /** This flashnode is valid and booting */
  NODE_BOOTING,
};

/** Possible flashnode States */
enum {
  /** This file index is empty and can be used by anybody */
  FILE_EMPTY,
  
  /** This file exists virtually, but no info has been written to flash */
  FILE_TEMPORARY,
  
  /** This file is valid but not being used */
  FILE_IDLE,
  
  /** The nodes in this file is open for reading */
  FILE_READING,
  
  /** The nodes in this file are open for writing */
  FILE_WRITING,

};


/** Magic Words */
enum {
  /** No flashnode exists at this point in the flash */
  META_EMPTY = 0xFFFF,             // binary 1111

  /** This flashnode is being constructed. If this is found on boot, delete the flashnode */
  META_CONSTRUCTING = 0x7777,      // binary 0111
  
  /** This flashnode is finalized on flash and all information is local */
  META_VALID = 0x3333,             // binary 0011
  
  /** This flashnode is deleted, mark up the SectorMap and move on */
  META_INVALID = 0x1111,           // binary 0001
  
  /** This is the type of data you'll find when a dataCrc is unfinalized */
  UNFINALIZED_CRC = 0xFFFF,
  
  /** This is the type of data you'll find when a dataLength is unfinalized */
  UNFINALIZED_DATA = 0xFFFF,
};

/** Global state machine for blackbook */
enum {
  S_BLACKBOOK_IDLE = 0,
  
  /** The file system is booting */
  S_BOOT_BUSY,
  
  /** The file system is recovering nodes */
  S_BOOT_RECOVERING_BUSY,
  
  /** The dictionary is in use */
  S_DICTIONARY_BUSY,
  
  /** Write: The general file writer is in use */
  S_WRITE_BUSY,
  
  /** Write: The file writer is saving */
  S_WRITE_SAVE_BUSY,
  
  /** Write: The file writer is closing */
  S_WRITE_CLOSE_BUSY,
  
  /** The file reader is in use */
  S_READ_BUSY,
  
  /** The file dir is in use */
  S_DIR_BUSY,
  
  /** The file delete is in use */
  S_DELETE_BUSY,
  
  
  BLACKBOOK_STATE = unique("State"),
};


enum {
  INTERNAL_DICTIONARY = unique("BDictionary"),
};

#endif



