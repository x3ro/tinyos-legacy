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

typedef struct ViewerMsg {
  uint32_t addr;
  uint16_t len;
  uint8_t cmd;
  uint8_t id; 
  uint8_t data[TOSH_DATA_LENGTH - 8];
} ViewerMsg;


enum {
  AM_VIEWERMSG = 0xA1,
};

enum {
  CMD_READ = 0,
  CMD_WRITE = 1, 
  CMD_ERASE = 2,
  CMD_MOUNT = 3,
  CMD_FLUSH = 4,
  CMD_PING = 5,
  CMD_CRC = 6,
  
  REPLY_READ = 10,
  REPLY_WRITE = 11,
  REPLY_ERASE = 12,
  REPLY_FLUSH = 14,
  REPLY_PING = 15,
  REPLY_CRC = 16,
  
  REPLY_READ_CALL_FAILED = 20,
  REPLY_WRITE_CALL_FAILED = 21,
  REPLY_ERASE_CALL_FAILED = 22,
  REPLY_FLUSH_CALL_FAILED = 24,
  REPLY_CRC_CALL_FAILED = 26,
  
  REPLY_READ_FAILED = 30,
  REPLY_WRITE_FAILED = 31,
  REPLY_ERASE_FAILED = 32,
  REPLY_FLUSH_FAILED = 34,
  REPLY_CRC_FAILED = 36,
  
  REPLY_INVALID_COMMAND = 50,
};



