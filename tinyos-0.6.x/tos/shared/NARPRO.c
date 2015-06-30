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
 *                      Nelson Lee
 *
 */

/*
 *   FILE: NARPRO.c
 * AUTHOR: Phil Levis
 *         Nelson Lee 
 *  DESCR: Beaconless routing protocol
 *
 *  NARPRO is a Beacon-LESS routing protocol for TinyOS. All data messages
 *  are sent as broadcasts. Motes sniff data traffic for other motes that
 *  can be heard. If the current parent mote (to whom messages are sent to
 *  get to the base station) is unheard for an interval, the mote switches
 *  to a new parent. The distance for the base station is stored in every
 *  data packet. If a mote hears a transmission from a mote that is closer
 *  to the base station than its current parent, it updates its cache of possible 
 *  parents. If it hears its parent, but its parent suddenly is more distant
 *  from the base station, it rejects its parent and tries to find a new one
 *  (otherwise, cycles in the routing graph could easily result).
 *
 *  Motes maintain a cache of 8 heard motes in case that a parent change is
 *  necessary. The base station periodically sends out a data message to
 *  itself, so that nearby motes can associate.
 *
 *  The NARPRO message format stores the source, the hop source (so you know
 *  who is transmitting it), hop destination, previous hop source (used as a heuristic
 *  when determining next parent), the hop distance of the hop src,
 *  and data.
 *
 *  The command NARPRO_INIT must be called or mapped to MAIN_SUB_INIT for
 *  the NARPRO component to work. The application narpro_test shows a trivial
 *  example use of NARPRO.
 *
 *  Certain parameters can be adjusted to improve performance.  For instance, if the 
 *  network is very well structured and will not change often, increasing TIMEOUT_HEURISTIC,
 *  and EVAL_HEURISTICS will keep the node's current parent longer.  Furthermore, 
 *  EVAL_HEURISTICS, EVAL_PARENT, and COUNT_TO_SEND_PING can also be increased to 
 *  conserve computation time as well as network bandwidth.
 *
 */


#include "NARPRO.h"
#include "tos.h"
#include "dbg.h"
#include "narpro_msg.h"

#define NO_PARENT -1
#define MAX_HOPS  8
#define EVAL_PARENT 40
#define EVAL_HEURISTICS 4
#define NUM_ENTRIES 8
#define WORST_VALUE_HEURISTIC 126
#define NO_MOTE -64
#define TIMEOUT_HEURISTIC 80
#define COUNT_TO_SEND_PING 3


extern short TOS_LOCAL_ADDRESS;

#define TOS_FRAME_TYPE NARPRO_obj_frame
TOS_FRAME_BEGIN(NARPRO_obj_frame) {
  char sent_counter;
  char received_counter;
  char parent_index;

  short parent_address;
  char send_pending;
  
  short cache_addr[NUM_ENTRIES];
  char cache_hop_count[NUM_ENTRIES];
  char cache_heuristics[NUM_ENTRIES];

  char heard_bitmask;
  char echo_bitmask;

  short ping_receive_addr;
  
  TOS_Msg data_buf;
  TOS_MsgPtr msg;
} 
TOS_FRAME_END(NARPRO_obj_frame);

inline void change_heuristic(int index, char change_amount) {
  int change_amount_int = (int) change_amount;
  int heuristic_int = (int) VAR(cache_heuristics)[index];
  int new_amount = change_amount_int + heuristic_int;
  if (new_amount < 0)
    VAR(cache_heuristics)[index] = 0;
  else if (new_amount > WORST_VALUE_HEURISTIC)
    VAR(cache_heuristics)[index] = WORST_VALUE_HEURISTIC+1;
  else 
    VAR(cache_heuristics)[index] = (char) new_amount;
}

// returns 1 if a parent was assigned, 0 otherwise
inline char assign_new_parent() {
  int i; 
  int best_index = -1;
  char best_heuristic = WORST_VALUE_HEURISTIC + 1;
  
  for (i = 0; i < NUM_ENTRIES; i++) {
    if (VAR(cache_heuristics)[i] < best_heuristic) {
      best_heuristic = VAR(cache_heuristics)[i];
      best_index = i;
    }
  }
  
  if (best_index == -1) {
    TOS_CALL_COMMAND(NARPRO_YELLOW_LED_OFF)();
    TOS_CALL_COMMAND(NARPRO_GREEN_LED_OFF)();
    return 0;
  }
  else {
    VAR(parent_index) = best_index;
    if ((VAR(cache_addr)[best_index] == 1) || (VAR(cache_addr)[best_index] == 3)) {
      TOS_CALL_COMMAND(NARPRO_GREEN_LED_ON)();
    }
    else {
      TOS_CALL_COMMAND(NARPRO_GREEN_LED_OFF)();
    }
    if ((VAR(cache_addr)[best_index] == 2) || (VAR(cache_addr)[best_index] == 3)) {
      TOS_CALL_COMMAND(NARPRO_YELLOW_LED_ON)();
    }
    else {
      TOS_CALL_COMMAND(NARPRO_YELLOW_LED_OFF)();
    }
    return 1;
  }
}


inline void mark_heard(short hop_source, short prev_source, char hop_source_hop_distance) {
  int i;
  int index = -1;
  int replace_index = -1;
  char worst_heuristic = -1;

  for (i = 0; i < NUM_ENTRIES; i++) {
    if (VAR(cache_addr)[i] == hop_source) {
      index = i;
      break;
    }
  }
  
  // hop_source already in cache
  if (index != -1) {
    // if our parent's hop count increased, remove him as parent and remove his entry
    if ((hop_source_hop_distance > VAR(cache_hop_count)[index]) &&
	(index == VAR(parent_index))) {
      VAR(cache_addr)[index] = NO_MOTE;
      VAR(cache_hop_count)[index] = MAX_HOPS + 1;
      VAR(cache_heuristics)[index] = WORST_VALUE_HEURISTIC + 1;
      VAR(parent_index) = NO_PARENT;
      VAR(echo_bitmask) &= (~(1 << index));
      VAR(heard_bitmask) &= (~(1 << index));      
    }
    // now check if hop_count increased past MAX_HOPS, if so, remove from cache
    else if (hop_source_hop_distance > MAX_HOPS) {
      VAR(cache_addr)[index] = NO_MOTE;
      VAR(cache_hop_count)[index] = MAX_HOPS + 1;
      VAR(cache_heuristics)[index] = WORST_VALUE_HEURISTIC + 1;
      VAR(echo_bitmask) &= (~(1 << index));
      VAR(heard_bitmask) &= (~(1 << index));
    }      
    // else, update the heuristic based on how much hop_count changed
    else {
      VAR(cache_hop_count)[index] = hop_source_hop_distance;
      change_heuristic(index, hop_source_hop_distance - VAR(cache_hop_count)[index]);
      if (prev_source == TOS_LOCAL_ADDRESS) 
	VAR(echo_bitmask) |= (1 << index);
      else 
	VAR(heard_bitmask) |= (1 << index);
    }
  }
  
  // we need to insert this entry into cache, only if hops_source_hop_distance
  // not as far as it should be
  else {
    if (!(hop_source_hop_distance > MAX_HOPS)) {
      for (i = 0; i < NUM_ENTRIES; i++) {
	if ((VAR(parent_index) != i) && (VAR(cache_heuristics)[i] > worst_heuristic)) {
	  replace_index = i;
	  worst_heuristic = VAR(cache_heuristics[i]);
	}
	
      }
      
      // insert new info at replace_index
      VAR(cache_addr)[replace_index] = hop_source;
      VAR(cache_hop_count)[replace_index] = hop_source_hop_distance;
      VAR(cache_heuristics)[replace_index] = hop_source_hop_distance;
      
      if (prev_source == TOS_LOCAL_ADDRESS)
	VAR(echo_bitmask) |= (1 << replace_index);
      else
	VAR(heard_bitmask) |= (1 << replace_index);
    }
  }
  
  if (VAR(parent_index) == NO_PARENT)
    assign_new_parent();
}


char TOS_COMMAND(NARPRO_INIT)() {
  int i;
  VAR(parent_index) = NO_PARENT;
  VAR(msg) = &VAR(data_buf);
  VAR(send_pending) = 0;
  VAR(heard_bitmask) = 0;
  VAR(echo_bitmask) = 0;
  VAR(ping_receive_addr) = NO_PARENT;

  for (i = 0; i < NUM_ENTRIES; i++) {
    VAR(cache_addr)[i] = NO_MOTE;
    VAR(cache_hop_count)[i] = MAX_HOPS + 1;
    VAR(cache_heuristics)[i] = WORST_VALUE_HEURISTIC + 1; 
  }
  
  TOS_CALL_COMMAND(NARPRO_SUB_INIT)();
  TOS_CALL_COMMAND(NARPRO_YELLOW_LED_ON)();
  TOS_CALL_COMMAND(NARPRO_GREEN_LED_ON)();
  
  return 1;
}

TOS_TASK(eval_counter_parent) {
  int i;
  int j;
  char heard_temp = 0;
  char echo_temp = 0;

  // if the node has a parent and it's time to send it a ping, do so
  if ((((VAR(sent_counter) + VAR(received_counter)) % 16) == COUNT_TO_SEND_PING) &&
      (VAR(parent_index) != NO_PARENT)) 
    TOS_CALL_COMMAND(NARPRO_PING_SEND)(VAR(cache_addr)[(int)VAR(parent_index)], 0);
    
  // update heuristics based on heard and echo indices!
  if (((VAR(sent_counter) + VAR(received_counter)) % 5) == EVAL_HEURISTICS) {
    for (i = 0; i < NUM_ENTRIES; i++) {
      if (VAR(cache_addr)[i] != NO_MOTE) {
	
	// if my parent node's heuristic exceeded TIMEOUT_HEURISTIC, remove from cache and as parent
	// and clear cache
	if ((VAR(cache_heuristics)[i] > TIMEOUT_HEURISTIC) &&
	    (VAR(parent_index) == i)) {
	  VAR(parent_index) = NO_PARENT;
	  
	  for (j = 0; j < NUM_ENTRIES; j++) {
	    VAR(cache_addr)[j] = NO_MOTE;
	    VAR(cache_hop_count)[j] = MAX_HOPS + 1;
	    VAR(cache_heuristics)[j] = WORST_VALUE_HEURISTIC + 1; 
	  }
	  VAR(echo_bitmask) = 0;
	  VAR(heard_bitmask) = 0;
	  
	  // no point calling assign_new_parent because everything's been cleared from cache
	  //assign_new_parent();
	}
	// if this node's heuristic exceeded TIMEOUT_HEURISTIC, remove from cache
	else if (VAR(cache_heuristics)[i] > TIMEOUT_HEURISTIC) {
	  VAR(cache_addr)[i] = NO_MOTE;
	  VAR(cache_hop_count)[i] = MAX_HOPS + 1;
	  VAR(cache_heuristics)[i] = WORST_VALUE_HEURISTIC + 1;
	  VAR(echo_bitmask) &= (~(1 << i));
	  VAR(heard_bitmask) &= (~(1 << i));
	}
	// else, simply update the heuristic value based on heard and echo bitmasks
	else {
	  if (VAR(heard_bitmask) & (1 << i)) 
	    heard_temp = 1; 
	  else 
	    heard_temp = 0;
	  if (VAR(echo_bitmask) & (1 << i))
	    echo_temp = 1;
	  else
	    echo_temp = 0;
	}
	change_heuristic(i, -2*echo_temp + -1*heard_temp + 3);    
      }
    }
    
    VAR(echo_bitmask) = 0;
    VAR(heard_bitmask) = 0;
  }
  
  if ((VAR(sent_counter) + VAR(received_counter)) == EVAL_PARENT) {
    assign_new_parent();
    VAR(sent_counter) = 0;
    VAR(received_counter) = 0;
  }
}


char TOS_COMMAND(NARPRO_SEND)(char* data, char len) {
  int i;
  narpro_msg* n_message = (narpro_msg*)(VAR(msg)->data);
  
  len = (len > 21)? 21 : len;
  
  
  if ((VAR(send_pending) == 1) || VAR(parent_index) == NO_PARENT) {
    //do nothing
  }
  else {
    n_message->dest = VAR(cache_addr)[(int)VAR(parent_index)];
    n_message->hop_src = TOS_LOCAL_ADDRESS;
    n_message->prev_src = TOS_LOCAL_ADDRESS;
    n_message->src = TOS_LOCAL_ADDRESS;
    n_message->src_hop_distance = (VAR(cache_hop_count)[(int)VAR(parent_index)] + 1);
    

    
    for (i = 0; i < len; i++) 
      n_message->data[i] = data[i];
    
    if (TOS_CALL_COMMAND(NARPRO_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(DATA_MSG), VAR(msg))) {
      //TOS_CALL_COMMAND(NARPRO_RED_LED_TOGGLE)();
      VAR(send_pending) = 1;
      return 1;
    }
  }

  return 0;
}
 
 
char TOS_COMMAND(NARPRO_ACTIVE)() {
  return VAR(parent_index) != NO_PARENT;

}


TOS_MsgPtr TOS_MSG_EVENT(DATA_MSG)(TOS_MsgPtr msg) {
  narpro_msg* n_message = (narpro_msg*)msg->data;
  TOS_MsgPtr tmp;

  TOS_CALL_COMMAND(NARPRO_RED_LED_TOGGLE)();
  // I received a message, update received_counter
  VAR(received_counter) += 1;
  
  TOS_POST_TASK(eval_counter_parent);
  
  
  // update cache
  mark_heard(n_message->hop_src, n_message->prev_src, n_message->src_hop_distance);
  
  if ((VAR(parent_index) != NO_PARENT) && (n_message->dest == TOS_LOCAL_ADDRESS && VAR(send_pending) == 0)) {
    VAR(send_pending) = 1;
    n_message->dest = VAR(cache_addr)[(int) VAR(parent_index)];
    n_message->prev_src = n_message->hop_src;
    n_message->hop_src = TOS_LOCAL_ADDRESS;
    n_message->src_hop_distance = (VAR(cache_hop_count)[(int) VAR(parent_index)] + 1);
    TOS_CALL_COMMAND(NARPRO_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(DATA_MSG),msg);
    tmp = VAR(msg);
    VAR(msg) = msg;
    return tmp;
  }
  return msg;
}  

TOS_TASK(INCREMENT_SEND_COUNTER) {
  VAR(sent_counter) += 1;
}

char TOS_EVENT(NARPRO_SEND_DONE)(TOS_MsgPtr data) {  
  VAR(send_pending) = 0;
  //TOS_CALL_COMMAND(NARPRO_RED_LED_TOGGLE)();
  TOS_POST_TASK(INCREMENT_SEND_COUNTER);
  TOS_POST_TASK(eval_counter_parent);
  return 1;
}

TOS_TASK(ping_received_update) {
  if ((VAR(parent_index) == NO_PARENT) || (VAR(ping_receive_addr != VAR(cache_addr)[(int)VAR(parent_index)]))) {
  }
  else {
    VAR(echo_bitmask) |= (1 << VAR(parent_index));
    VAR(heard_bitmask) |= (1 << VAR(parent_index));
  }
  return;
}


char TOS_EVENT(NARPRO_PING_RESPONSE)(short moteID, char sequence) {
  VAR(ping_receive_addr) = moteID;
  TOS_POST_TASK(ping_received_update);
}



char TOS_EVENT(NARPRO_PING_RECEIVE)(short moteID, char sequence) {
  return 1 ;
}

























