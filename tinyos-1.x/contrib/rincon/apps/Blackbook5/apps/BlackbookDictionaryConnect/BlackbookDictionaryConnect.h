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


#include "AM.h"

typedef struct BlackbookConnectMsg {
  uint32_t length;
  uint8_t cmd;
  uint8_t result;
  uint8_t data[TOSH_DATA_LENGTH - 6];
} BlackbookConnectMsg;

typedef struct BlackbookNodeMsg {
  struct flashnode focusedNode;
} BlackbookNodeMsg;

typedef struct BlackbookFileMsg {
  struct file focusedFile;
} BlackbookFileMsg;

typedef struct BlackbookSectorMsg {
  struct flashsector focusedSector;
} BlackbookSectorMsg;

enum {
  AM_BLACKBOOKCONNECTMSG = 0xBB,
  AM_BLACKBOOKNODEMSG = 0xBC,
  AM_BLACKBOOKFILEMSG = 0xBD,
  AM_BLACKBOOKSECTORMSG = 0xBE,
};



enum {
  CMD_BFILEWRITE_OPEN = 0,
  CMD_BFILEWRITE_CLOSE = 1,
  CMD_BFILEWRITE_APPEND = 2,
  CMD_BFILEWRITE_SAVE = 3,
  CMD_BFILEWRITE_REMAINING = 4,
  
  CMD_BFILEREAD_OPEN = 10,
  CMD_BFILEREAD_CLOSE = 11,
  CMD_BFILEREAD_READ = 12,
  CMD_BFILEREAD_SEEK = 13,
  CMD_BFILEREAD_SKIP = 14,
  CMD_BFILEREAD_REMAINING = 15,
  
  CMD_BFILEDELETE_DELETE = 20,
  
  CMD_BFILEDIR_TOTALFILES = 30,
  CMD_BFILEDIR_TOTALNODES = 31,
  CMD_BFILEDIR_EXISTS = 32,
  CMD_BFILEDIR_READNEXT = 33,
  CMD_BFILEDIR_RESERVEDLENGTH = 34,
  CMD_BFILEDIR_DATALENGTH = 35,
  CMD_BFILEDIR_CHECKCORRUPTION = 36,
  CMD_BFILEDIR_READFIRST = 37,
  CMD_BFILEDIR_GETFREESPACE = 38,
 
  CMD_BDICTIONARY_OPEN = 40,
  CMD_BDICTIONARY_CLOSE = 41,
  CMD_BDICTIONARY_INSERT = 42,
  CMD_BDICTIONARY_RETRIEVE = 43,
  CMD_BDICTIONARY_REMOVE = 44, 
  CMD_BDICTIONARY_NEXTKEY = 45,
  CMD_BDICTIONARY_FIRSTKEY = 46,
  CMD_BDICTIONARY_ISDICTIONARY = 47,
  
  ERROR_BFILEWRITE_OPEN = 100,
  ERROR_BFILEWRITE_CLOSE = 101,
  ERROR_BFILEWRITE_APPEND = 102,
  ERROR_BFILEWRITE_SAVE = 103,
  ERROR_BFILEWRITE_REMAINING = 104,
  
  ERROR_BFILEREAD_OPEN = 110,
  ERROR_BFILEREAD_CLOSE = 111,
  ERROR_BFILEREAD_READ = 112,
  ERROR_BFILEREAD_SEEK = 113,
  ERROR_BFILEREAD_SKIP = 114,
  ERROR_BFILEREAD_REMAINING = 115,
  
  ERROR_BFILEDELETE_DELETE = 120,
  
  ERROR_BFILEDIR_TOTALFILES = 130,
  ERROR_BFILEDIR_TOTALNODES = 131,
  ERROR_BFILEDIR_EXISTS = 132,
  ERROR_BFILEDIR_READNEXT = 133,
  ERROR_BFILEDIR_RESERVEDLENGTH = 134,
  ERROR_BFILEDIR_DATALENGTH = 135,
  ERROR_BFILEDIR_CHECKCORRUPTION = 136,
  ERROR_BFILEDIR_READFIRST = 137,
  ERROR_BFILEDIR_GETFREESPACE = 138,
    
  ERROR_BDICTIONARY_OPEN = 140,
  ERROR_BDICTIONARY_CLOSE = 141,
  ERROR_BDICTIONARY_INSERT = 142,
  ERROR_BDICTIONARY_RETRIEVE = 143,
  ERROR_BDICTIONARY_REMOVE = 144,
  ERROR_BDICTIONARY_NEXTKEY = 145,
  ERROR_BDICTIONARY_FIRSTKEY = 146,
  ERROR_BDICTIONARY_ISDICTIONARY = 147,
  
  REPLY_BFILEWRITE_OPEN = 200,
  REPLY_BFILEWRITE_CLOSE = 201,
  REPLY_BFILEWRITE_APPEND = 202,
  REPLY_BFILEWRITE_SAVE = 203,
  REPLY_BFILEWRITE_REMAINING = 204,
  
  REPLY_BFILEREAD_OPEN = 210,
  REPLY_BFILEREAD_CLOSE = 211,
  REPLY_BFILEREAD_READ = 212,
  REPLY_BFILEREAD_SEEK = 213,
  REPLY_BFILEREAD_SKIP = 214,
  REPLY_BFILEREAD_REMAINING = 215,
  
  REPLY_BFILEDELETE_DELETE = 220,
  
  REPLY_BFILEDIR_TOTALFILES = 230,
  REPLY_BFILEDIR_TOTALNODES = 231,
  REPLY_BFILEDIR_EXISTS = 232,
  REPLY_BFILEDIR_READNEXT = 233,
  REPLY_BFILEDIR_RESERVEDLENGTH = 234,
  REPLY_BFILEDIR_DATALENGTH = 235,
  REPLY_BFILEDIR_CHECKCORRUPTION = 236,
  REPLY_BFILEDIR_GETFREESPACE = 238,
  
  REPLY_BDICTIONARY_OPEN = 240,
  REPLY_BDICTIONARY_CLOSE = 241,
  REPLY_BDICTIONARY_INSERT = 242,
  REPLY_BDICTIONARY_RETRIEVE = 243,
  REPLY_BDICTIONARY_REMOVE = 244,
  REPLY_BDICTIONARY_NEXTKEY = 245,
  REPLY_BDICTIONARY_FIRSTKEY = 246,
  REPLY_BDICTIONARY_ISDICTIONARY = 247,
  
  REPLY_BOOT = 250,
  REPLY_BCLEAN_ERASING = 251,
  REPLY_BCLEAN_DONE = 252,
};

