/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

// @author Cory Sharp, Moteiv Corporation <info@moteiv.com>

#ifndef H_Spram_h
#define H_Spram_h

enum {
  AM_SPRAMDATAMSG = 33,
  AM_SPRAMREQUESTMSG = 34,
};

enum {
  SPRAM_BYTES_PER_MSG = 32,
  SPRAM_FLAG_NO_VERSION = 0x01,
  SPRAM_FLAG_COMPLETE_VERSION = 0x02,
};

typedef struct SpramDataMsg {
  uint16_t addrSender;
  uint16_t bytesBegin;
  uint16_t bytesTotal;
  uint16_t versionToken;
  uint8_t version;
  uint8_t flags;
  int8_t bytes[0];
} SpramDataMsg_t;

typedef struct SpramRequestMsg {
  uint16_t addrRequester;
  uint16_t bytesBegin;
  uint16_t bytesEnd;
  uint16_t bytesTotal;
  uint16_t versionToken;
  uint8_t version;
  uint8_t flags;
} SpramRequestMsg_t;

#endif//H_Spram_h
