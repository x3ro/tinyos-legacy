/*									tab:4
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:   Alec Woo
 * History:   created 4/23/2002
 *
 *
 */
#include <string.h>
#include "tos.h"
#include "NEIGHBOR_ROUTE.h"
#include "NEIGHBORHOOD_TABLE.inc"
#include "dbg.h"

#define IDLE 1
#define PROCESSING 2

// will go away when link layer seq_num is implemented
extern char seq_num;

#define TOS_FRAME_TYPE NEIGHBOR_ROUTE_frame
TOS_FRAME_BEGIN(NEIGHBOR_ROUTE_frame) {
  TOS_MsgPtr buf;
  TOS_MsgPtr upper_buf;
  // Access to the table to keep track of statistics of my neighbors
  neighborhood_t * table_ptr[TABLE_SIZE];
  char hop;
  short route;
  char send_pending;
  char state;
  char count;
}
TOS_FRAME_END(NEIGHBOR_ROUTE_frame);

TOS_TASK(ROUTE_SELECTION){
  int i;
  char allow_new_entries = 0;
  char first_tier_min=0x7f, second_tier_min=0x7f;
  unsigned short first_tier_min_id=0xffff, second_tier_min_id=0xffff;
  unsigned short mr_stable, backward_estimate;
  
  for (i=0; i < TABLE_SIZE; i++){
    mr_stable = VAR(table_ptr)[i]->mr_stable;
    backward_estimate = VAR(table_ptr)[i]->backward_estimate;
    // First tier selection: 75% or more goodness, min hop count with smallest id
    //if (mr_stable >= 190 || backward_estimate >= 190){ //about 75% goodness for first tier
    if (backward_estimate >= 190){ //about 75% goodness for first tier
	  if (VAR(table_ptr)[i]->hop <= first_tier_min){
	    if (VAR(table_ptr)[i]->node < first_tier_min_id){
	      first_tier_min_id = VAR(table_ptr)[i]->node;
	      first_tier_min = VAR(table_ptr)[i]->hop;
	    }
	  }
    } // Second tier selection 50% to 75% goodness, min hop count with smallest id
    //else if (mr_stable >= 127 || backward_estimate >= 127){ //about 50% goodness for second tier
    else if (backward_estimate >= 127){ //about 50% goodness for second tier
      if (VAR(table_ptr)[i]->hop <= second_tier_min){
	if (VAR(table_ptr)[i]->node < second_tier_min_id){
	  second_tier_min_id = VAR(table_ptr)[i]->node;
	  second_tier_min = VAR(table_ptr)[i]->hop;
	}
      }
    }
  }
  
  // Update route and hop based on whether a good parent can be found
  // I will only change my hop and route to a node which is one hop below me
  // otherwise, I will hold on to it unless I hear no one with the same hop
  // as I do is around

  // When your parent is gone and there are no one with hops smaller than you,
  // what should you do? => hold on to the last parent and hold on to your gradient
  if (first_tier_min != 0x7f){
    if (VAR(hop) > first_tier_min){
      VAR(hop) = first_tier_min + 1;
      VAR(route) = first_tier_min_id;
      allow_new_entries = 1;
    }
  }else if (second_tier_min != 0x7f){
    if (VAR(hop) > second_tier_min){
      VAR(hop) = second_tier_min + 1;
      VAR(route) = second_tier_min_id;
      allow_new_entries = 1;
    }
  }else{
    // If no parents can be selected, hold on to the last route
    // but my hop level is all the way out, so none of my children will pick me up as parent
    VAR(hop) = 0x7f;
    allow_new_entries = 1;
  }
  TOS_CALL_COMMAND(NEIGHBOR_ROUTE_SET_HOP)(VAR(hop), allow_new_entries);
  TOS_CALL_COMMAND(NEIGHBOR_ROUTE_DISPLAY_HOP)((short) VAR(hop));
}


/* NEIGHBOR_ROUTE_INIT:  
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(NEIGHBOR_ROUTE_INIT)(){
  neighborhood_t *ptr;
  int i;

  TOS_CALL_COMMAND(NEIGHBOR_ROUTE_SUB_INIT)();       /* initialize lower components */
  VAR(send_pending) = 0;
  VAR(state) = IDLE;
  if (TOS_LOCAL_ADDRESS != 1){
    VAR(hop) = 0x7f;
  }else{
    VAR(hop) = 0;
  }
  if (TOS_LOCAL_ADDRESS == 1)
    VAR(route) = TOS_UART_ADDR;
  else
    VAR(route) = 0;

  ptr = (neighborhood_t *) TOS_CALL_COMMAND(NEIGHBOR_ROUTE_GET_TABLE)();
  for (i=0; i < TABLE_SIZE; i++,ptr++)
    VAR(table_ptr)[i] = ptr;
  TOS_CALL_COMMAND(NEIGHBOR_ROUTE_SET_HOP)(VAR(hop));
  dbg(DBG_BOOT, ("NEIGHBOR_ROUTE initialized\n"));
  return 1;
}

// Periodically explore the best route around this node
// best route is based on link connectivity and hop count

// may want first check how bad was the last route
// hold on to it if it is still good
// otherwise, look for another one
void TOS_EVENT(NEIGHBOR_ROUTE_CLOCK_EVENT)(){

  if (TOS_LOCAL_ADDRESS != 1){
    VAR(count)++;
    // Every 10 seconds, update route selection
    if (VAR(count) == 10){
      TOS_POST_TASK(ROUTE_SELECTION);
      VAR(count) = 0;
    }
  }
  return;
}


// When a routing packet is received, route it.
TOS_MsgPtr TOS_EVENT(NEIGHBOR_ROUTE_RX_PACKET)(TOS_MsgPtr data){
  if (VAR(send_pending) == 0){
    VAR(buf) = data;
    // Update extra header information including src, seq_num, and hop count
    *(short *)&(data->data[0]) = TOS_LOCAL_ADDRESS;
    data->data[3] = VAR(hop);
    VAR(send_pending) = TOS_CALL_COMMAND(NEIGHBOR_ROUTE_SEND_MSG)(VAR(route), AM_MSG(NEIGHBOR_ROUTE_RX_PACKET), data);
    if (VAR(send_pending) != 0){
      data->data[2] = seq_num++;
    }
  }
  return data;
}


char TOS_COMMAND(NEIGHBOR_ROUTE_DELIVER_MSG)(TOS_MsgPtr data){

  if (VAR(send_pending) == 0 && VAR(route) != 0){
    // Update extra header information including src, seq_num, and hop count
    *(short *)&(data->data[0]) = TOS_LOCAL_ADDRESS;
    data->data[3] = VAR(hop);
    VAR(send_pending) = TOS_CALL_COMMAND(NEIGHBOR_ROUTE_SEND_MSG)(VAR(route), AM_MSG(NEIGHBOR_ROUTE_RX_PACKET), data);
    if (VAR(send_pending) != 0){
      data->data[2] = seq_num++;
      VAR(upper_buf) = data;
      return 1;
    } 
  }
  return 0;
}

char TOS_EVENT(NEIGHBOR_ROUTE_TX_PACKET_DONE)(TOS_MsgPtr data){
  if(VAR(buf) == data){
    dbg(DBG_USR1, ("NEIGHBOR_ROUTE send buffer free\n"));
    VAR(send_pending) = 0;
  }else if (VAR(upper_buf) == data){
    dbg(DBG_USR1, ("NEIGHBOR_ROUTE send buffer free\n"));
    VAR(send_pending) = 0;
    TOS_SIGNAL_EVENT(NEIGHBOR_ROUTE_DELIVER_MSG_DONE)(data);
  }
  return 1;
}

