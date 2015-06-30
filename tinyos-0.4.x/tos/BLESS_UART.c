/*									tab:4
 * BLESS_UART.c - periodically emits an active message containing light reading
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
 * Authors:   Philip Levis
 * History:   created 7/25/2001
 *
 *
 */

#include "tos.h"
#include "BLESS_UART.h"
#include "bless_msg.h"
#include "dbg.h"

/* Utility functions */

#define TOS_FRAME_TYPE BLESS_UART_frame
TOS_FRAME_BEGIN(BLESS_UART_frame) {
  TOS_Msg data; 
  TOS_MsgPtr msg;
  char rf_pending;
  char uart_pending;
}
TOS_FRAME_END(BLESS_UART_frame);


/* BLESS_UART_INIT:  
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(BLESS_UART_INIT)(){
  TOS_CALL_COMMAND(BLESS_UART_SUB_INIT)();    /* init lower components */
  TOS_CALL_COMMAND(BLESS_UART_SUB_UART_INIT)();/* init lower components */
  TOS_CALL_COMMAND(BLESS_UART_CLOCK_INIT)(160, 0x07); /* every 5 seconds */
  VAR(msg) = &VAR(data);
  VAR(rf_pending) = 0;
  VAR(uart_pending) = 0;
  printf("BLESS_UART initialized\n");
  return 1;
}

char TOS_COMMAND(BLESS_UART_START)(){
  return 1;
}

TOS_MsgPtr TOS_EVENT(BLESS_UART_RX_PACKET)(TOS_MsgPtr data){
  TOS_MsgPtr tmp = data;
  bless_msg* b_message = (bless_msg*)data->data;
  
  printf("BLESS_UART received packet\n");
  if(VAR(uart_pending) == 0 &&
	 data->group == LOCAL_GROUP &&
	 b_message->dest == TOS_LOCAL_ADDRESS){

	tmp = VAR(msg);
	VAR(msg) = data;
	data->addr = 0x7e;
	TOS_COMMAND(BLESS_UART_GREEN_LED)();
	printf("BLESS_UART forwarding packet\n");
	if(TOS_COMMAND(BLESS_UART_SUB_UART_TX_PACKET)(data)){
	  printf("BLESS_UART send pending\n");
	  VAR(uart_pending)  = 1;
	}
  }
  return tmp;
}

char TOS_EVENT(BLESS_UART_TX_PACKET_DONE)(TOS_MsgPtr data){
	printf("BLESS_UART send buffer free\n");
	TOS_COMMAND(BLESS_UART_RED_LED)();
	VAR(rf_pending) = 0;
	return 1;
}

TOS_MsgPtr TOS_EVENT(BLESS_UART_SUB_UART_RX_PACKET)(TOS_MsgPtr data){
	TOS_MsgPtr tmp = data;
	printf("BLESS_UART received packet\n");
	if(VAR(rf_pending) == 0 && data->group == LOCAL_GROUP){
		tmp = VAR(msg);
		VAR(msg) = data;
		printf("BLESS_UART forwarding packet\n");
		if(TOS_COMMAND(BLESS_UART_TX_PACKET)(data)){
		  printf("BLESS_UART send pending\n");
		  VAR(rf_pending)  = 1;
		}
	}
	return tmp;
}

char TOS_EVENT(BLESS_UART_SUB_UART_TX_PACKET_DONE)(TOS_MsgPtr data){
	if(VAR(msg) == data){
		printf("BLESS_UART send buffer free\n");
		VAR(uart_pending) = 0;
	}
	return 1;
}

inline void prepare_route_msg() {
  int i;
  bless_msg* b_message = (bless_msg*)VAR(data).data;

  VAR(data).addr = TOS_BCAST_ADDR;
  VAR(data).type = 7;
  VAR(data).group = LOCAL_GROUP;
  b_message->dest = TOS_UART_ADDR;
  b_message->hop_src = TOS_LOCAL_ADDRESS;
  b_message->src = TOS_LOCAL_ADDRESS;
  b_message->src_hop_distance = 0;

  for (i = 0; i < 26; i++) {
    b_message->data[i] = 0xee;
  }
  
}

void TOS_EVENT(BLESS_UART_CLOCK_TICK)(){
  dbg(DBG_ROUTE, ("route clock\n"));;
  //if is the base, then it should send out the route update.
  if (VAR(rf_pending) == 0){
	VAR(rf_pending) = 1;
	prepare_route_msg();
	TOS_CALL_COMMAND(BLESS_UART_RED_LED)();
	TOS_CALL_COMMAND(BLESS_UART_TX_PACKET)(&VAR(data));
  }
}
