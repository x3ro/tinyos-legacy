/*									
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
 */


#ifndef _MUTATIONROUTE_H_
#define _MUTATIONROUTE_H_

#include <AM.h>

enum { RESERVE, ROUTER, RECRUIT, SHORTCUT, CERTIFIED };

enum { IDLE, RREQ };

#ifndef __EROUTE_H_
typedef enum  {
  MA_PURSUER1 = 2,
  MA_PURSUER2 = 3,
  MA_PURSUER3 = 4, 
  MA_PURSUER4 = 5,
  MA_VIZ      = 5,
  MA_ALL = 16
} __attribute__((packed)) EREndpoint;
#endif

typedef struct {
  uint16_t id;
  uint16_t parent;
  uint16_t child;
  uint8_t cost;
  uint16_t seqNo;
  uint8_t sendFailCount;
  uint8_t onShortcutBlacklist;
  uint8_t onRecruitBlacklist;
  uint8_t timeout;
} __attribute__((packed)) Mutation;


typedef struct {
  uint16_t id;
  EREndpoint dest;
  uint16_t child;
  uint8_t cost;
  uint16_t seqNo;
  uint16_t macSeqNo;
  uint8_t data[TOSH_DATA_LENGTH - (sizeof(EREndpoint) + (sizeof(uint16_t) * 4) + sizeof(uint8_t))];
} __attribute__((packed)) MRMsg;


typedef struct {
  uint16_t id;
  EREndpoint dest;
  uint8_t cost;
  uint16_t seqNo;
  uint16_t macSeqNo;
} __attribute__((packed)) RREQMsg;

typedef struct {
  uint16_t id;
  EREndpoint dest;
  uint16_t seqNo;
  uint16_t macSeqNo;
} __attribute__((packed)) RREPMsg;

enum {
  MAX_MY_FAILCOUNT = 10,
  MAX_FAILCOUNT = 6,
  MAX_RECRUIT_FAILCOUNT = 10,
  MAX_SHORTCUT_FAILCOUNT = 10,
  NODE_TIMEOUT = 15000,
  HOOD_TIMEOUT = 3000,
  ROUTE_TIMEOUT = 60000
};

enum { MUTATION_ROUTE = 127, MUTATION_RREQ = 128, MUTATION_RREP = 129 };

enum { MR_NUM_NEIGHBORS = 15};

uint16_t ROUTE_SEQ_NUMBER = 0; // pc hack
uint16_t RREQ_SEQ_NUMBER = 0; // pc hack

#endif
