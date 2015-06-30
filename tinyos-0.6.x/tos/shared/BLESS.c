/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Phil Levis
 *
 *
 */

/*
 *   FILE: BLESS.c
 * AUTHOR: pal
 *  DESCR: Beaconless routing protocol - BETA, known bugs
 *
 *  BLESS is a Beacon-LESS routing protocol for TinyOS. All data messages
 *  are sent as broadcasts. Motes sniff data traffic for other motes that
 *  can be heard. If the current parent mote (to whom messages are sent to
 *  get to the base station) is unheard for an interval, the mote switches
 *  to a new parent. The distance for the base station is stored in every
 *  data packet. If a mote hears a transmission from a mote that is closer
 *  to the base station than its current parent, it makes that mote its new
 *  parent. If it hears its parent, but its parent suddenly is more distant
 *  from the base station, it rejects its parent and tries to find a new one
 *  (otherwise, cycles in the routing graph could easily result).
 *
 *  Motes maintain a cache of 8 heard motes in case that a parent change is
 *  necessary. The base station periodically sends out a data message to
 *  itself, so that nearby motes can associate.
 *
 *  The BLESS message format stores the source, the hop source (so you know
 *  who is transmitting it), hop destination, the hop distance of the hop src,
 *  and data.
 *
 *  The command BLESS_INIT must be called or mapped to MAIN_SUB_INIT for
 *  the BLESS component to work. The application bless_test shows a trivial
 *  example use of BLESS.
 *
 *  BLESS has known bugs. First, its cache replacement policy purges
 *  the current parent identically to any other entry without updating
 *  dependent * state variables (e.g. current hop count). Second, it
 *  cannot detect if a link is asymmetric. As BLESS tries to use the
 *  parent with the lowest hop count, it favors long links. Initial
 *  experimental results have shown that a significant proportion of
 *  long links are asymmetric.
 *
 */

/* Always use the bless_msg structure when messing with messages. */

#include "tos.h"
#include "BLESS.h"
#include "bless_msg.h"
#include "dbg.h"

extern short TOS_LOCAL_ADDRESS;

#define MAX_HOPS 16
#define CLOCK_PARAM 0x07 // 32 tick/sec
#define INTR_PARAM  32  // ticks/intr (5sec)
#define PARENT_TIMEOUT 6 // Every 6 intr (30 seconds)
#define NO_PARENT -64
#define NUM_ENTRIES 8
#define NO_MOTE -128

#define TOS_FRAME_TYPE BLESS_obj_frame
TOS_FRAME_BEGIN(BLESS_obj_frame) {
  char hop_distance;
  char send_pending;
  char temp_read_counter;
  char time;
  
  short motes_heard[NUM_ENTRIES];
  char heard_hops[NUM_ENTRIES];
  char heard_index;
  char parent_index;
  char heard_bitmask;
  
  TOS_Msg data_buf;	
  TOS_MsgPtr msg;
  int prev;
  
  char parentTimeout;
}
TOS_FRAME_END(BLESS_obj_frame);

inline void prepare_route_msg() {
  int i;
  bless_msg* b_message = (bless_msg*)VAR(data_buf).data;
  
  b_message->dest = TOS_UART_ADDR;
  b_message->hop_src = TOS_LOCAL_ADDRESS;
  b_message->src = TOS_LOCAL_ADDRESS;
  b_message->src_hop_distance = 0;

  for (i = 0; i < 26; i++) {
    b_message->data[i] = 0x00;
  }
  
}

inline char has_parent() {return VAR(parent_index) != NO_PARENT;}

/* Returns if the address is in the cache; if so, returns the cache
 * line number */
inline char is_present(short addr) {
  char i;
  for (i = 0; i < NUM_ENTRIES; i++) { 
    if (VAR(motes_heard)[(int)i] == addr) {return i;} 
  } 
  return -1;	
}

/* Searches for a new parent in the cache. If one is found,
 * it is chosen. */

inline void find_next_parent() {
  char i;
  for (i = 0; i < NUM_ENTRIES; i++) {
    if (VAR(heard_bitmask) & (1 << i) &&
        VAR(heard_hops)[(int)i] < MAX_HOPS) { // If we've heard this entry

      VAR(parent_index) = i;
      VAR(hop_distance) = VAR(heard_hops)[(int)VAR(parent_index)] + 1;
      return;
    }
  }
}

/* Notes the address heard. Returns 1 if addr is new parent, 0 otherwise */
inline char mark_heard(short addr, char hops) { 
  char index = is_present(addr);

  if (addr == TOS_LOCAL_ADDRESS) {return 0;}

  if (index >= 0 && index < NUM_ENTRIES) {
    if (index == VAR(parent_index) && 
        hops >= VAR(hop_distance)) { // Heard our parent with higher hop count
      
      // Purge parent from cache entirely; prevents cycles
      VAR(motes_heard)[(int)VAR(parent_index)] = NO_MOTE;
      VAR(heard_hops)[(int)VAR(parent_index)] = MAX_HOPS + 1;
      VAR(parent_index) = NO_PARENT;
      VAR(heard_bitmask) &= (~(1 << VAR(parent_index)));
      find_next_parent();
    } 
    VAR(heard_bitmask) |= (1 << index);
    VAR(heard_hops)[(int)index] = hops;
  } 

  else  { // New entry in cache 
    VAR(motes_heard)[(int)VAR(heard_index)] = addr; 
    VAR(heard_hops)[(int)VAR(heard_index)] = hops;
    VAR(heard_bitmask) |= (1 << VAR(heard_index));
    
    if (((VAR(parent_index) == NO_PARENT) && (hops < MAX_HOPS)) || 
         (hops < VAR(heard_hops)[(int)VAR(parent_index)])) { 
      VAR(parent_index) = VAR(heard_index); 
      VAR(hop_distance) = hops + 1;
      VAR(heard_index) = (VAR(heard_index) + 1) % NUM_ENTRIES; 
	  return 1;
    } 
    VAR(heard_index) = (VAR(heard_index) + 1) % NUM_ENTRIES; 
  }
  
  return 0;
}

char TOS_COMMAND(BLESS_INIT)(){
  //initialize sub components
  char i;
  TOS_CALL_COMMAND(BLESS_SUB_INIT)();
  
  VAR(msg) = &VAR(data_buf);
  VAR(send_pending) = 0;
  
  //initialize all the variables
  VAR(hop_distance) = MAX_HOPS + 1;
  VAR(parent_index) = NO_PARENT;
  VAR(temp_read_counter) = 0;
  VAR(heard_index) = 0;
  VAR(time) = 0;
  VAR(heard_bitmask) = 0;
  TOS_CALL_COMMAND(BLESS_SET_TIMEOUT)(6);
  
  for (i = 0; i < NUM_ENTRIES; i++) {
    VAR(motes_heard)[(int)i] = NO_MOTE;
    VAR(heard_hops)[(int)i] = MAX_HOPS + 1;
  }

  return 1;
}

char TOS_COMMAND(BLESS_START)(){
  return 1;
}

// Returns whether the node is network-active (sending packets)
char TOS_COMMAND(BLESS_ACTIVE)() {
  return has_parent();
}

char TOS_COMMAND(BLESS_SET_TIMEOUT)(char ticks) {
  if (ticks >= 0) {
    VAR(parentTimeout) = ticks;
    return 1;
  }
  else {
    return 0;
  }
}

char TOS_COMMAND(BLESS_SEND)(char* data, char len) {
  int i;
  bless_msg* b_message = (bless_msg*)(VAR(data_buf).data);
  
  dbg(DBG_ROUTE, ("BLESS sending data of length %i\n", len));
  
  if (VAR(send_pending) != 0 || VAR(parent_index) == NO_PARENT){
    return 0;
  }
 
  len = (len > 26)? 26 : len;

  b_message->dest = VAR(motes_heard)[(int)VAR(parent_index)];
  b_message->hop_src = TOS_LOCAL_ADDRESS;
  b_message->src = TOS_LOCAL_ADDRESS;
  b_message->src_hop_distance = VAR(hop_distance);
  
  for (i = 0; i < 26; i++) {
	b_message->data[i] = data[i];
  }

  if (TOS_CALL_COMMAND(BLESS_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(DATA_MSG),&VAR(data_buf))) {
    VAR(send_pending) = 1;
  }
  return 1;
}

// This handler forwards packets traveling to the base.

TOS_MsgPtr TOS_MSG_EVENT(DATA_MSG)(TOS_MsgPtr msg){
  bless_msg* b_message = (bless_msg*)msg->data;
  TOS_MsgPtr tmp;

  
  TOS_CALL_COMMAND(BLESS_LED2_TOGGLE)();
  
  // Mark address heard; if new parent, flicker the yellow. 
  if (mark_heard(b_message->hop_src, b_message->src_hop_distance)) {
	// Do nothing for now
  }
  
  
  //if a route is known, forward the packet towards the base.
  if(b_message->dest == TOS_LOCAL_ADDRESS && 
     VAR(parent_index) != NO_PARENT && 
     VAR(hop_distance) <= MAX_HOPS) {
    
    b_message->dest = VAR(motes_heard)[(int)VAR(parent_index)];// Next hop addr
    b_message->hop_src = TOS_LOCAL_ADDRESS;              // Our (source) addr
    b_message->src = b_message->src; // Remains unchanged
    b_message->src_hop_distance = VAR(hop_distance);   // Our hop distance
    
    dbg(DBG_ROUTE, ("BLESS routing to home %x\n", VAR(motes_heard)[(int)VAR(parent_index)]));
    
    //send the packet.
    if (VAR(send_pending) == 0){
      VAR(send_pending) = 1;
      TOS_CALL_COMMAND(BLESS_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(DATA_MSG),msg);
      tmp = VAR(msg);
      VAR(msg) = msg;
      return tmp;
    }
  }
  return msg;
}


void TOS_EVENT(BLESS_SUB_CLOCK)(){
  dbg(DBG_ROUTE, ("BLESS clock\n"));
  if (VAR(time) > VAR(parentTimeout)) {
    char i;
    
    if (!(VAR(heard_bitmask) & (1 << VAR(parent_index)))) {
      VAR(parent_index) = NO_PARENT;
      find_next_parent();
    }
    for (i = 0; i < NUM_ENTRIES; i++) {
      if (!(VAR(heard_bitmask) & (1 << i))) {
	VAR(motes_heard)[(int)i] = NO_MOTE;
	VAR(heard_hops)[(int)i] = MAX_HOPS + 1;
      }
    }
    VAR(heard_bitmask) = 0;       
	VAR(time) = 0;
  }
  
  VAR(time)++;
}

char TOS_EVENT(BLESS_SEND_DONE)(TOS_MsgPtr data){
  VAR(send_pending) = 0;
  return 1;
}
