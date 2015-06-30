// $Id: Straw.h,v 1.3 2006/12/01 00:11:33 binetude Exp $

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
  AM_STRAWCMDMSG = 246,
  AM_STRAWREPLYMSG = 247,
  AM_STRAWUARTMSG = 248,
};
enum {
  STRAW_IDLE_STATE = 0,

  STRAW_SUB_IDLE = 0,
  STRAW_SUB_FIRST = 1,
  STRAW_SUB_PROC = 2,
  STRAW_SUB_FNSHD = 3,

  STRAW_BFFR_EMPTY = 0,
  STRAW_BFFR_READING = 1,
  STRAW_BFFR_READDONE = 2,
  STRAW_BFFR_SENDING = 3,
};
enum {
  STRAW_TYPE_SHIFT = 10,
};
enum {
  STRAW_NETWORK_INFO = 1,
  STRAW_TRANSFER_DATA = 6,
  STRAW_RANDOM_READ = 7,
  STRAW_ERR_CHK = 9,

  DIVERGE_HEADER_LENGTH = 2,
  STRAWCMDMSG_LENGTH = TOSH_DATA_LENGTH - DIVERGE_HEADER_LENGTH,
  
  STRAWCMDMSG_HEADER_LENGTH = 2,
  STRAWCMDMSG_ARG_LENGTH = STRAWCMDMSG_LENGTH - STRAWCMDMSG_HEADER_LENGTH,
  MAX_RANDOM_READ_SEQNO_SIZE = STRAWCMDMSG_ARG_LENGTH / 2,
};
enum {
  STRAW_NETWORK_INFO_REPLY = 1,
  STRAW_DATA_REPLY = 8,
  STRAW_ERR_CHK_REPLY = 9,

  CONVERGE_HEADER_LENGTH = 7,
  STRAWREPLYMSG_LENGTH = TOSH_DATA_LENGTH - CONVERGE_HEADER_LENGTH,
  
  STRAWREPLYMSG_HEADER_LENGTH = 0,
  STRAWREPLYMSG_ARG_LENGTH = STRAWREPLYMSG_LENGTH - STRAWREPLYMSG_HEADER_LENGTH,
  MAX_DATA_REPLY_DATA_SIZE = STRAWREPLYMSG_ARG_LENGTH - 2,
};



typedef struct {
  uint16_t type;
} CmnDummy;

typedef struct {
  uint16_t type;
  uint8_t toUART;
} NetworkInfo;

typedef struct {
  uint16_t type;
  uint32_t start;
  uint32_t size;
  
  uint16_t uartOnlyDelay;
  uint16_t uartDelay;
  uint16_t radioDelay;
  uint8_t toUART;
  uint8_t portId;
} TransferData;

typedef struct {
  uint16_t seqNo[MAX_RANDOM_READ_SEQNO_SIZE];
} RandomRead;

typedef struct {
  uint16_t type;
  uint8_t toUART;
} ErrChk;

typedef struct StrawCmdMsg {
  uint16_t dest;
  union {
    CmnDummy cd;
    NetworkInfo ni;
    TransferData td;
    RandomRead rr;
    ErrChk ec;
  } arg;
} StrawCmdMsg;



typedef struct {
  uint16_t type;
} CmnDummyReply;

typedef struct {
  uint16_t type;
  uint16_t uartOnlyDelay;
  uint16_t uartDelay;
  uint16_t radioDelay;

  uint16_t parent;
  uint8_t depth;
  uint8_t occupancy;
  uint8_t quality;
} NetworkInfoReply;

typedef struct {
  uint16_t seqNo;
  uint8_t data[MAX_DATA_REPLY_DATA_SIZE];
} DataReply;

typedef struct {
  uint16_t type;
  uint16_t checksum;
  uint16_t bffrChk;
} ErrChkReply;

typedef struct StrawReplyMsg {
  union {
    CmnDummyReply cdr;
    NetworkInfoReply nir;
    DataReply dr;
    ErrChkReply ecr;
  } arg;
} StrawReplyMsg;

typedef struct StrawUARTMsg {
  StrawReplyMsg dummy;
}  StrawUARTMsg;

