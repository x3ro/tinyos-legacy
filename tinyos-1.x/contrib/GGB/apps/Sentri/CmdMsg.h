// $Id: CmdMsg.h,v 1.1 2006/12/01 00:09:07 binetude Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

#include "AM.h"

enum {
  AM_CMDMSG = 8,
};
enum {
  LED_ON = 1,
  LED_OFF = 2,

  PING_NODE = 3,
  FIND_NODE = 4,

  RESET = 11,
  ERASE_FLASH = 12,
  START_SENSING = 13,

  READ_PROFILE1 = 16,
  READ_PROFILE2 = 17,

  TIMESYNC_INFO = 21,
  NETWORK_INFO = 22,

  FIX_ROUTE = 26,
  RELEASE_ROUTE = 27,
  TIMESYNC_ON = 28,
  TIMESYNC_OFF = 29,

  FOR_DEBUG = 31,
};
enum {
  DIVERGENCE_HEADER_LENGTH = 2,
  CMDMSG_LENGTH = TOSH_DATA_LENGTH - DIVERGENCE_HEADER_LENGTH,
  
  CMDMSG_HEADER_LENGTH = 5,
  CMDMSG_ARG_LENGTH = CMDMSG_LENGTH - CMDMSG_HEADER_LENGTH,

  MAX_FIND_NODE_NODES = (CMDMSG_ARG_LENGTH - 1) / 2,
  MAX_START_SENSING_NAME = CMDMSG_ARG_LENGTH - 16,
  MAX_FOR_DEBUG_DATA = (CMDMSG_ARG_LENGTH - 2) / 2,
};



typedef struct {
//  PING_NODE, READ_PROFILE1, READ_PROFILE2, TIMESYNC_INFO, NETWORK_INFO  //
  bool toUART;
} __attribute__ ((packed)) elementaryShared;

typedef struct {
  uint8_t noOfNode;
  uint16_t nodes[MAX_FIND_NODE_NODES];
} __attribute__ ((packed)) findNode;

typedef struct {
  uint32_t nSamples;
  uint32_t intrv;
  uint8_t chnlSelect;
  uint16_t samplesToAvg;
  uint32_t startTime;
  uint8_t lenOfNm;
  uint8_t nm[MAX_START_SENSING_NAME];
} __attribute__ ((packed)) startSensing;

typedef struct {
  uint8_t type;
  uint16_t data[MAX_FOR_DEBUG_DATA];
  bool toUART;
} __attribute__ ((packed)) forDebug;



typedef struct CmdMsg {
  uint16_t dest;
  uint16_t seqNo;
  uint8_t type;
  union {
  
    elementaryShared es;

    findNode fn;

    startSensing ss;

    forDebug fd;
    
    uint8_t untyped[0];
  } args;
} __attribute__ ((packed)) CmdMsg;

