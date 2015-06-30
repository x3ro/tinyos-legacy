/**
 * Copyright (c) 2006 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

#ifndef __MSG_H__
#define __MSG_H__

#include "McTorrent.h"

enum {
  AM_ADVMSG            = 161,
  AM_REQMSG            = 162,
  AM_DATAMSG           = 163,
  AM_CHNMSG            = 164
};

/* Fields should be aligned at 16-bit boundary 
 * for msp430 on telosb is a 16-bit controller.
 * Otherwise, the compiler would complain for 
 * "Internal error: unsupported relocation error".
 */

typedef struct AdvMsg {
  uint16_t        srcAddr;
  uint16_t        objId;
  uint16_t        crcData;  // CRC of the whole object.
  uint8_t         numPages;
  uint8_t         numPktsLastPage;
  uint8_t         numPagesComplete; 
  uint8_t         dataChannel;  
} __attribute__((packed)) AdvMsg;

typedef struct ReqMsg {
  uint16_t  srcAddr;  
  uint16_t  destAddr;
  uint16_t  delay;  // Offset from receiving ADV, in milliseconds.
  uint16_t  objId;
  uint8_t   pageId;
  uint8_t   requestedPkts[PAGE_BITVEC_SIZE];
  uint8_t   dataChannel; 
} __attribute__((packed)) ReqMsg;

typedef struct ChnMsg {
  uint16_t  srcAddr;
  uint16_t  objId;
  uint8_t   pageId;
  uint8_t   pktsToSend[PAGE_BITVEC_SIZE];
  uint8_t   dataChannel;
  uint8_t   moreChnMsg;  // How many more CHN messages to be sent
} __attribute__((packed)) ChnMsg;

typedef struct DataMsg {
  uint16_t  srcAddr;
  uint16_t  objId;
  uint8_t   pageId;
  uint8_t   pktId;
  uint8_t   data[BYTES_PER_PKT];  // would not fit in telosb if DataMsg is 29 bytes totally.
} __attribute__((packed)) DataMsg;


#endif
