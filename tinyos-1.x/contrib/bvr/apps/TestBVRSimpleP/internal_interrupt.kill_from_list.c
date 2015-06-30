// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: internal_interrupt.kill_from_list.c,v 1.1 2005/11/19 02:58:52 rfonseca76 Exp $

/*                                                                      
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
 * Authors:  Rodrigo Fonseca
 * Date Last Modified: 2005/05/26
 */


/* Allows events with global knowledge independent of the actual code
   on the motes. This is a mechanism that allows powerful scripting,
   by inserting identified events in the event queue.*/


#include <BVR.h>
#include <BVRCommand.h>
#include "kill_nodes.h"

/* Description: */
/* This simulation generates route request to random pairs of nodes at a constant rate */
/* After KILL_INITIAL_INTERVAL, all nodes in kill_nodes.h are killed */

enum {
  ROUTING_BEACONS = 12
};

enum {
  INT_EVENT_FIRST = 0x8000,
  INT_EVENT_SEND_MSG,
  INT_EVENT_KILL_MOTE,
};

/* Internal Functions */

enum {
  MSGS_INITIAL_WAIT = 3600,  //wait for 10 minutes to stabilize
  MSGS_INTERVAL = 1,         //send one message per second
  KILL_INITIAL_WAIT = 5400,  //30 minutes after the routes start
  KILL_INTERVAL = 0,
};

//Forward Declarations
result_t select_random_routing_pair(short *from, short *to, 
     Coordinates * coords_from, Coordinates * coords_to);
long int get_next_route_interval();
void send_route_to_command(short origin, short dest, Coordinates * coords_to);
result_t select_mote_to_kill(short *mote);
long long get_next_kill_interval();



void schedule_first_events() {
  dbg_clear(DBG_USR3,"II:schedule_first_events, at %llu\n",tos_state.tos_time);
  scheduleInterrupt(INT_EVENT_SEND_MSG, (long long)MSGS_INITIAL_WAIT*4000000);
  scheduleInterrupt(INT_EVENT_KILL_MOTE, (long long)KILL_INITIAL_WAIT*4000000);
}

void send_route_to_random_pair() {
  short from,to;
  Coordinates coords_from,coords_to;
  dbg_clear(DBG_USR3,"II:Choosing a random pair to route\n");
  if (select_random_routing_pair(&from,&to,&coords_from,&coords_to) == SUCCESS) {
    dbg_clear(DBG_USR3,"II:Selected pair: from %d to %d\n",from,to);
    dbg_clear(DBG_USR3,"II:Coordinates for dest mote %d: ",to);
    coordinates_print(DBG_USR3,&coords_to);
    //Send route command
    send_route_to_command(from,to,&coords_to);
  } else {
    dbg_clear(DBG_USR3,"II:Failed to select pair, skipping slot\n");
  }
  scheduleInterrupt(INT_EVENT_SEND_MSG, tos_state.tos_time + get_next_route_interval());
}

/* Every one second...*/
long int get_next_route_interval() {
  return (long int)4000000*MSGS_INTERVAL;
}

void kill_all_motes() {
  int i;
  dbg_clear(DBG_USR3,"II: Killing %d motes at %llu\n",KILL_NODES,tos_state.tos_time);
  for (i = 0; i < KILL_NODES; i++) {
    nido_stop_mote(kill_motes[i]);
  }
}

//choose a mote that is alive and is not a beacon
void periodic_kill_motes() {
  short victim;
  if (select_mote_to_kill(&victim)) {
   dbg_clear(DBG_USR3,"II: Killing mote %d at %llu\n",victim,tos_state.tos_time);
    nido_stop_mote(victim); 
    scheduleInterrupt(INT_EVENT_KILL_MOTE, tos_state.tos_time + get_next_kill_interval());
  }
  //else stop: no one else to kill
}

long long get_next_kill_interval() {
  return (long long)4000000*KILL_INTERVAL;
}


result_t select_random_routing_pair(short *from, short *to,
                          Coordinates *coords_from, Coordinates *coords_to) {
  //select random dest
  int i,c,d;
  bool found;
  char *name = "BVRStateM$my_coords";
  uintptr_t p;
  size_t size;
  
  d = (int)(((double)tos_state.num_nodes)*rand()/(RAND_MAX+1.0));
  //check that mote is on and has at least ROUTING_BEACONS coordinates valid
  found = 0;
  for (i = 0; i < tos_state.num_nodes && !found; i++) {
    c = (d + i) % tos_state.num_nodes;
    //get coordinates for this mote and count valid components 
    if (__nesc_nido_resolve(c, name, &p, &size) != 0) {
      dbg(DBG_USR3,"II: Error resolving %s for mote %d\n",name,c);
      continue;
    }
    coordinates_copy_k_closest((Coordinates*)p, coords_to, ROUTING_BEACONS);
    found = (tos_state.moteOn[c] && 
             coordinates_count_valid_components(coords_to) >= ROUTING_BEACONS);
    if (found) 
      *to = c;
  }
  if (!found)
    return FAIL;
  //look for a source
  d = (int)(((double)tos_state.num_nodes)*rand()/(RAND_MAX+1.0));
  //check that mote is on and has the same valid components

  found = 0;
  for (i = 0; i < tos_state.num_nodes && !found; i++) {
    c = (d + i) % tos_state.num_nodes;
    if (c == *to) continue;
    //get coordinates for this mote and count valid components 
    if (__nesc_nido_resolve(c, name, &p, &size) != 0) {
      dbg(DBG_USR3,"II: Error resolving %s for mote %d\n",name,c);
      continue;
    }
    coordinates_copy((Coordinates*)p, coords_from);
    found = (tos_state.moteOn[c] && 
             coordinates_has_same_valid_components(coords_from, coords_to));
 
    if (found) 
      *from = c;
  }
  if (!found)
    return FAIL;
  return SUCCESS;
}

void send_route_to_command(short from, short to,Coordinates *coords) {
  TOS_Msg message;
  BVRCommandMsg *cm = (BVRCommandMsg*) &message.data;
  
  BVRCommandArgs* cmd_args = 
       (BVRCommandArgs*) &cm->type_data.data;

  message.addr = from;
  message.type = AM_BVR_COMMAND_MSG;
  message.group = TOS_AM_GROUP; 
  message.length = sizeof(BVRCommandMsg);
  
  cm->header.last_hop = TOS_UART_ADDR;
  cm->header.seqno = 0;
  
  cm->type_data.hopcount = 1;
  cm->type_data.origin = TOS_UART_ADDR;
  cm->type_data.type = BVR_CMD_APP_ROUTE_TO;

  cmd_args->seqno = 1;
  cmd_args->flags = 0;

  //Destination
  cmd_args->args.dest.addr = to;
  cmd_args->args.dest.mode = 2;
  coordinates_copy(coords, &cmd_args->args.dest.coords);

  //Done setting up message, call 
  sendUARTMessage(from, &message);
  
}

result_t select_mote_to_kill(short *victim) {
  int d,c,i;
  bool found;

  d = (int)(((double)tos_state.num_nodes)*rand()/(RAND_MAX+1.0));
  found = 0;
  //select a mote that is alive and is not a beacon
  for (i = 0; i < tos_state.num_nodes && !found; i++) {
    c = (d + i) % tos_state.num_nodes;
    found = ( tos_state.moteOn[c] && 
             (hc_root_beacon_id[c] == INVALID_BEACON_ID)
            ); 
  }
  if (found) 
    *victim = c;
  return (found)?SUCCESS:FAIL;
}

/* --------------------------------------------------------------------*/
/* Exported Functions */

void internalInterruptInit() {
  dbg_clear(DBG_USR3,"II:InternalInterruptInit! %llu\n",tos_state.tos_time);
  scheduleInterrupt(INT_EVENT_FIRST, tos_state.tos_time);
}


/*This function is called whenever an interrupt event is
 *triggered. This allows us to dispatch different handlers
 *based on id. Rescheduling can be done by calling
 *scheduleInterrupt(id,time)
 */
void internalInterruptHandler(uint32_t id) {
  dbg_clear(DBG_USR3,"II:InternalInterruptHandler %llu!\n",tos_state.tos_time);
  switch(id) {
    case INT_EVENT_FIRST:
      schedule_first_events();
      break;
    case INT_EVENT_SEND_MSG:
      send_route_to_random_pair();
      break;
    case INT_EVENT_KILL_MOTE:
      kill_all_motes();
      break;
    default:
      break;
  }
}


