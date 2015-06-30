/* Copyright (c) 2007 Dartmouth SensorLab.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * paragraph and the author appear in all copies of this software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */

/* The funneling-MAC code.
 *
 * Authors: Gahng-Seop Ahn   <ahngang@ee.columbia.edu>,
 *          Emiliano Miluzzo <miluzzo@cs.dartmouth.edu>.
 */

#ifndef _TOS_FUNNELINGMAC_H
#define _TOS_FUNNELINGMAC_H

#include "AM.h"

enum {
  AM_BEACON = 31,
  AM_SCHEDULE = 32,
  AM_QUERY = 33,
  NO_NODES_LOSSTABLE = 15,
  NO_BRANCHES_SCH = 14
};
  
typedef struct FunnelingMACMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  uint8_t hoptraveled;              // funneling-MAC
  uint8_t control;                  // funneling-MAC: x x 0 0 0 0 0 1 -> missed schedule; x x 0 0 0 0 1 0 -> new schedule; x x 0 0 0 1 x x -> inside farea; x x 0 0 0 0 x x ->outside farea; x x 0 0 1 x x x -> request new registration; 1 0 0 0 0 0 x x ->pck contains meta-schedule; 1 1 0 0 0 0 x x -> pck contains meta-schedule but forwarded by a not TDMA node inside farea so meta-schedule no good
  uint8_t path_head;                // funneling-MAC
  uint8_t meta_schedule[4];         // funneling-MAC
  uint8_t data[(TOSH_DATA_LENGTH - 14)];
} __attribute__ ((packed)) TOS_FMACMsg;

typedef struct QueryMsg {
  uint8_t seqno;
  uint16_t rate;
} __attribute__ ((packed)) QueryMsg;

typedef struct BeaconMsg {
  uint16_t sourceaddr;
  uint16_t superframe_dur;
  uint16_t csma_dur;
  uint16_t tdma_dur;
  uint16_t tdmarate;
  uint8_t notdmaslots;
  uint8_t morebroadcast_pck;
} __attribute__ ((packed)) BeaconMsg;

typedef struct Schedule_Field {
	uint8_t headbranch_addr;
	uint8_t  no_slots;
} __attribute__ ((packed)) ScheduleField;

typedef struct ScheduleMsg {
	ScheduleField schedule[NO_BRANCHES_SCH];
} __attribute__ ((packed)) ScheduleMsg;

typedef struct Branch {
  uint8_t branch;
  uint8_t hoptraveled;
} Branch;

typedef struct RegisteredNodes {
  uint8_t ActiveBranches[NO_BRANCHES_SCH]; 
  uint8_t traffic_src[NO_BRANCHES_SCH]; 
  Branch branches[NO_BRANCHES_SCH];
} RegisteredNodes;

typedef struct Slot {
  uint8_t slots;    //stores no of slots have to wait before next tx
  uint16_t slotsTotdmaExpires;  //contains the number of slots to the tdma expiration since the tx slot of node
  bool ifSrc; // if TRUE means i'm a source for this slot
} Slot;

typedef struct My_Branch {
  uint16_t OriginAddr; //stores the source addr
  uint16_t Headaddr;  //stores the path above it
  uint8_t hops;   //stores the no of hops from branch head
  bool isScheduled; //if TRUE the branch has ben scheduled for TDMA phase
  bool isBranchHead; //if TRUE the node is branch head but not source
 } My_Branch;

typedef struct NodeTable {
  bool ImEnode;  // if TRUE the node is an EDGE node
  My_Branch mybranch[NO_BRANCHES_SCH];
  Slot NoSlot[NO_BRANCHES_SCH];
} NodeTable;

typedef struct Child {
  uint8_t child_id;
  uint16_t pks_rx;
} Child;

typedef struct ChildrenTable {
  Child mychild[NO_NODES_LOSSTABLE];
} ChildrenTable;

typedef struct Parent {
  uint8_t parent_id;
  uint16_t pks_tx;
} Parent;

typedef struct ParentsTable {
  Parent myparent[NO_NODES_LOSSTABLE];
} ParentsTable;

#endif /* _TOS_FUNNELINGMAC_H */
