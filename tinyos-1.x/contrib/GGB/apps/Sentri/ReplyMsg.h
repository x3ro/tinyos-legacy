// $Id: ReplyMsg.h,v 1.1 2006/12/01 00:09:07 binetude Exp $

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
  AM_REPLYMSG = 9,
  AM_UARTMSG = 10,
};
enum {
  PING_NODE_REPLY = 3,
  FIND_NODE_REPLY = 4,

  READ_PROFILE1_REPLY = 16,
  READ_PROFILE2_REPLY = 17,

  TIMESYNC_INFO_REPLY = 21,
  NETWORK_INFO_REPLY = 22,

  FOR_DEBUG_REPLY = 31,

  ERROR_REPLY = 36,
};
enum {
  CONVERGENCE_HEADER_LENGTH = 7,
  REPLYMSG_LENGTH = TOSH_DATA_LENGTH - CONVERGENCE_HEADER_LENGTH,

  REPLYMSG_HEADER_LENGTH = 3,
  REPLYMSG_ARG_LENGTH = REPLYMSG_LENGTH - REPLYMSG_HEADER_LENGTH,

  MAX_READ_PROFILE2_REPLY_NAME = REPLYMSG_ARG_LENGTH - 1,
  MAX_FOR_DEBUG_REPLY_DATA = (REPLYMSG_ARG_LENGTH - 1) / 2,
};



typedef struct {
  uint16_t seqNo;
  uint32_t nSamples;
  uint32_t intrv;
  uint8_t chnlSelect;
  uint16_t samplesToAvg;
  uint32_t startTime;
  uint8_t integrity;
} __attribute__ ((packed)) readProfile1Reply;

typedef struct {
  uint8_t lenOfNm;
  uint8_t nm[MAX_READ_PROFILE2_REPLY_NAME];
} __attribute__ ((packed)) readProfile2Reply;


typedef struct {
  uint32_t sysTime;
  uint32_t localTime;
  uint32_t globalTime;
} __attribute__ ((packed)) timesyncInfoReply;

typedef struct {
  uint16_t parent;
  uint16_t treeParent;
  uint8_t depth;
  uint8_t treeDepth;
  uint8_t occupancy;
  uint8_t quality;
  uint8_t fixedRoute;
} __attribute__ ((packed)) networkInfoReply;


typedef struct {
  uint8_t type;
  uint16_t data[MAX_FOR_DEBUG_REPLY_DATA];
} __attribute__ ((packed)) forDebugReply;



typedef struct ReplyMsg {
  uint16_t src;
  uint8_t type;
  union {
 
    readProfile1Reply rp1r;
    readProfile2Reply rp2r;

    timesyncInfoReply tir;
    networkInfoReply nir;
 
    forDebugReply fdr;

    uint8_t untyped[0];
  } args;
} __attribute__ ((packed)) ReplyMsg;

typedef struct UARTMsg {
  ReplyMsg dummy;
} __attribute__ ((packed)) UARTMsg;

