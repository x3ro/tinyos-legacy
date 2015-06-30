// $Id: MultiHop.h,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

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


#ifndef _TOS_MULTIHOP_H
#define _TOS_MULTIHOP_H

#include "AM.h"

// size of the forwarding queue
#ifndef MHOP_DEFAULT_QUEUE_SIZE
#define MHOP_DEFAULT_QUEUE_SIZE	2
#endif

// number of milliseconds to delay after receiving a packet
#ifndef MHOP_INIT_DELAY
#define MHOP_INIT_DELAY 1
#endif

// number of milliseconds to delay
#ifndef MHOP_RETRY_DELAY
#define MHOP_RETRY_DELAY 1024
#endif

// number of retries
#ifndef MHOP_RETRY_MSG
#define MHOP_RETRY_MSG 5
#endif

// route updates should be sent every 'n' binary seconds
#ifndef MHOP_DEFAULT_BEACON_PERIOD
#define MHOP_DEFAULT_BEACON_PERIOD 30
#endif

// Number of missed route beacons before discardingroute updates should be sent every 'n' binary seconds
#ifndef MHOP_DEFAULT_BEACON_TIMEOUT
#define MHOP_DEFAULT_BEACON_TIMEOUT 8
#endif 

#ifndef MHOP_DEFAULT_PARENT_SIZE
#define MHOP_DEFAULT_PARENT_SIZE 3
#endif

#ifndef MHOP_BASE_STATION_ADDR
#define MHOP_BASE_STATION_ADDR 0
#endif

enum MultiHopConsts {
  MHOP_QUEUE_SIZE = MHOP_DEFAULT_QUEUE_SIZE,
  MHOP_BEACON_PERIOD = MHOP_DEFAULT_BEACON_PERIOD,
  MHOP_BEACON_TIMEOUT = MHOP_DEFAULT_BEACON_TIMEOUT,
  MHOP_PARENT_SIZE = MHOP_DEFAULT_PARENT_SIZE,
};

enum {
  AM_BEACONMSG = 7,
  AM_MULTIHOPMSG = 8,
  AM_DEBUGPACKET = 9,
};

typedef struct MultihopMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  int16_t originseqno;
  uint8_t ttl;
  uint8_t id;
  uint8_t data[(TOSH_DATA_LENGTH - 10)];
} TOS_MHopMsg;

typedef struct BeaconMsg {
  uint16_t parent;
  uint16_t cost;
  uint16_t hopcount;
  uint32_t timestamp;
} BeaconMsg;

typedef struct ParentEntry {
  uint16_t addr;
  uint16_t cost;
  uint16_t estimate;
  uint8_t  hopcount;
  uint8_t lastheard;
} ParentEntry;

#endif /* _TOS_MULTIHOP_H */

