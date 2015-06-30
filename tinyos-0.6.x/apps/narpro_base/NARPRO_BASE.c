/*									tab:4
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
 * Authors:		Jason Hill, Phil Levis 
 * Modified:            Nelson Lee
x *
 */

/*
 *   FILE: NARPRO_BASE.c
 * AUTHOR: pal
 *  DESCR: Beaconless routing protocol base station - BETA
 *
 *  NARPRO is a Beacon-LESS routing protocol for TinyOS. All data messages
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
 *  The NARPRO message format stores the source, final destination (for if
 *  the protocol is expanded to point-to-point routing), hop destination,
 *  and hop source, as well as the hop distance of the source and data.
 *  Currently, the data is used to store the path the message takes, for
 *  easy debugging and visualization.
 *
 *  This component is a NARPRO base station. It periodically sends out dummy
 *  data messages to itself (every 15 seconds) so other motes hear it. It
 *  forwards messages sent to it to the UART.
 */

#include "tos.h"
#include "NARPRO_BASE.h"
#include "dbg.h"
#include "narpro_msg.h"

extern short TOS_LOCAL_ADDRESS;

#define CLOCK_PARAM 0x07 // 32 tick/sec
#define INTR_PARAM  32  // ticks/intr (5sec)

#define TOS_FRAME_TYPE NARPRO_BASE_obj_frame
TOS_FRAME_BEGIN(NARPRO_BASE_obj_frame) {
	char hop_distance;
	char send_pending;
	char uart_send_pending;
	char temp_read_counter;
	char time;
	
	TOS_Msg data_buf;	
	TOS_MsgPtr msg;
	int prev;
}
TOS_FRAME_END(NARPRO_BASE_obj_frame);

inline void prepare_route_msg() {
  int i;
  narpro_msg* n_message = (narpro_msg*)VAR(data_buf).data;
  
  n_message->dest = TOS_UART_ADDR;
  n_message->hop_src  = TOS_LOCAL_ADDRESS;
  n_message->src = TOS_LOCAL_ADDRESS;
  n_message->prev_src = TOS_LOCAL_ADDRESS;
  n_message->src_hop_distance = 0;

  for (i = 0; i < 20; i++) {
    n_message->data[i] = 0xee;
  }
  
}

char TOS_COMMAND(NARPRO_BASE_INIT)(){
  VAR(msg) = &VAR(data_buf);
  VAR(send_pending) = 0;
  
  TOS_CALL_COMMAND(NARPRO_BASE_SUB_INIT)();
  TOS_CALL_COMMAND(NARPRO_BASE_YELLOW_LED_ON)();

  // Issue clock interrupt once every 5 seconds
  TOS_CALL_COMMAND(NARPRO_BASE_SUB_CLOCK_INIT)(INTR_PARAM, CLOCK_PARAM);
  dbg(DBG_ROUTE, ("NARPRO: base initialized\n"));
  return 1;
}

char TOS_COMMAND(NARPRO_BASE_START)(){
  return 1;
}

// This handler forwards packets traveling to the base.

TOS_MsgPtr TOS_MSG_EVENT(DATA_MSG)(TOS_MsgPtr msg){
    narpro_msg* n_message = (narpro_msg*)msg->data;
    TOS_MsgPtr tmp = msg;

    // Green LED toggles when message received
    TOS_CALL_COMMAND(NARPRO_BASE_GREEN_LED_TOGGLE)();
	
    //Re-transmit to UART address
    //if(n_message->dest == TOS_LOCAL_ADDRESS && VAR(send_pending) == 0) {
    if (VAR(send_pending) == 0) {
	  VAR(send_pending) = 1;
	  
	  //n_message->prev_src = n_message->hop_src;
	  //n_message->hop_src = TOS_LOCAL_ADDRESS;
	  //n_message->src = TOS_LOCAL_ADDRESS; // Our (source) addr
	  //n_message->src_hop_distance = 0;    // Our hop distance

	  TOS_CALL_COMMAND(NARPRO_BASE_YELLOW_LED_TOGGLE)();
	  TOS_CALL_COMMAND(NARPRO_BASE_SUB_SEND_MSG)((short)TOS_UART_ADDR,AM_MSG(DATA_MSG),msg);
	  
	  tmp = VAR(msg);
	}
	
	return tmp;
}


void TOS_EVENT(NARPRO_BASE_SUB_CLOCK)(){
  dbg(DBG_ROUTE, ("route clock\n"));;
  //if is the base, then it should send out the route update.
  if (VAR(send_pending) == 0){
	VAR(send_pending) = 1;
	prepare_route_msg();
	TOS_CALL_COMMAND(NARPRO_BASE_SUB_SEND_MSG)((short)TOS_BCAST_ADDR,AM_MSG(DATA_MSG),&VAR(data_buf));
	TOS_CALL_COMMAND(NARPRO_BASE_RED_LED_ON)();
  }
}


char TOS_EVENT(NARPRO_BASE_SEND_DONE)(TOS_MsgPtr data){
  VAR(send_pending) = 0;
  TOS_CALL_COMMAND(NARPRO_BASE_RED_LED_OFF)();
  return 1;
}





























