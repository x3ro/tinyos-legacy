// $Id: Delta.h,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#ifndef H_Delta_h
#define H_Delta_h

#include "MultiHop.h"

#define DELTA_QUEUE_SIZE MHOP_DEFAULT_QUEUE_SIZE - (MHOP_DEFAULT_QUEUE_SIZE >> 2)

enum {
  DELTA_TIME = 1024 * 5,
};

enum {
  AM_DELTAMSG = 33
};

typedef struct DeltaMsg {
  uint32_t seqno;
  uint16_t reading;
  uint16_t parent;
  uint8_t neighborsize;
  uint8_t retransmissions;
  uint16_t neighbors[MHOP_PARENT_SIZE];
  uint16_t quality[MHOP_PARENT_SIZE];
} DeltaMsg;

#endif//H_Delta_h

