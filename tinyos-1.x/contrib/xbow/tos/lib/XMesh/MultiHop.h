// $Id: MultiHop.h,v 1.2 2005/01/14 01:25:22 jdprabhu Exp $

/*
 * Copyright (c) 2005 Crossbow Technology, Inc.
 *
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute, this software and
 * documentation is granted, provided the following conditions are met:
 * 
 * 1. The above copyright notice and these conditions, along with the
 * following disclaimers, appear in all copies of the software.
 * 
 * 2. When the use, copying, modification or distribution is for COMMERCIAL
 * purposes (i.e., any use other than academic research), then the software
 * (including all modifications of the software) may be used ONLY with
 * hardware manufactured by and purchased from Crossbow Technology, unless
 * you obtain separate written permission from, and pay appropriate fees
 * to, Crossbow. For example, no right to copy and use the software on
 * non-Crossbow hardware, if the use is commercial in nature, is permitted
 * under this license. 
 *
 * 3. When the use, copying, modification or distribution is for
 * NON-COMMERCIAL PURPOSES (i.e., academic research use only), the software
 * may be used, whether or not with Crossbow hardware, without any fee to
 * Crossbow. 
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE
 * TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
 * EVEN IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM
 * ALL WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY
 * LICENSOR HAS ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS. 
 * 
 */

#ifndef _TOS_MULTIHOP_H
#define _TOS_MULTIHOP_H

#include "AM.h"
enum {
  AM_MULTIHOPMSG = 250,
  AM_DEBUGPACKET = 3 
};

/* Fields of neighbor table */
typedef struct TOS_MHopNeighbor {
  uint16_t addr;                     // state provided by nbr
  uint16_t recv_count;               // since last goodness update
  uint16_t fail_count;               // since last goodness, adjusted by TOs
  int16_t last_seqno;
  uint8_t goodness;
  uint8_t hopcount;
  uint8_t timeouts;		     // since last recv
} TOS_MHopNeighbor;
  
typedef struct MultihopMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  uint8_t data[(TOSH_DATA_LENGTH - 7)]; 
} __attribute__ ((packed)) TOS_MHopMsg;

typedef struct DBGEstEntry {
  uint16_t id;
  uint8_t hopcount;
  uint8_t sendEst;
} __attribute__ ((packed)) DBGEstEntry;


typedef struct DebugPacket {
  uint8_t estEntries;
  DBGEstEntry estList[5];
} __attribute__ ((packed)) DebugPacket;


#endif /* _TOS_MULTIHOP_H */
