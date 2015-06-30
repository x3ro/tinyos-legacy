/*									tab:4
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
 * Authors:   Jason Hill
 * History:   created 1/25/2001
 *
 *
 */

/* GENERIC_BASE.c - captures all the packets that it can hear and report it
                    back to the UART
                  - forward all incoming UART messages out to the radio
*/

#include "tos.h"
#include "GENERIC_BASE.h"
#include "dbg.h"

/* Utility functions */

#define TOS_FRAME_TYPE GENERIC_BASE_frame
TOS_FRAME_BEGIN(GENERIC_BASE_frame) {
  TOS_Msg data; 
  TOS_MsgPtr msg;
  char send_pending;
}
TOS_FRAME_END(GENERIC_BASE_frame);


/* GENERIC_BASE_INIT:  
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(GENERIC_BASE_INIT)(){
  TOS_CALL_COMMAND(GENERIC_BASE_SUB_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(GENERIC_BASE_SUB_UART_INIT)();       /* initialize lower components */
  VAR(msg) = &VAR(data);
  VAR(send_pending) = 0;
  dbg(DBG_BOOT, ("GENERIC_BASE initialized\n"));
  dbg(DBG_BOOT, ("%s\n",__FILE__));
  return 1;
}
char TOS_COMMAND(GENERIC_BASE_START)(){
	return 1;
}

TOS_MsgPtr TOS_EVENT(GENERIC_BASE_RX_PACKET)(TOS_MsgPtr data){
	TOS_MsgPtr tmp = data;

	dbg(DBG_USR1, ("GENERIC_BASE received packet\n"));
	if(VAR(send_pending) == 0) {// && (data->group == (LOCAL_GROUP & 0xff))){
		tmp = VAR(msg);
		VAR(msg) = data;
		data->addr = TOS_UART_ADDR;
		dbg(DBG_USR1, ("GENERIC_BASE forwarding packet\n"));
		//CLR_RED_LED_PIN();
		TOS_CALL_COMMAND(GENERIC_BASE_FLASH_RX)();
		if(TOS_CALL_COMMAND(GENERIC_BASE_SUB_UART_TX_PACKET)(data)){
			dbg(DBG_USR1, ("GENERIC_BASE send pending\n"));
			VAR(send_pending)  = 1;
		}
	}
	return tmp;
}

char TOS_EVENT(GENERIC_BASE_TX_PACKET_DONE)(TOS_MsgPtr data){
	if(VAR(msg) == data){
		dbg(DBG_USR1, ("GENERIC_BASE send buffer free\n"));
		VAR(send_pending) = 0;
	}
	return 1;
}

TOS_MsgPtr TOS_EVENT(GENERIC_BASE_SUB_UART_RX_PACKET)(TOS_MsgPtr data){
	TOS_MsgPtr tmp = data;
	dbg(DBG_USR2, ("GENERIC_BASE received packet\n"));
	if(VAR(send_pending) == 0) {// && data->group == LOCAL_GROUP){
		tmp = VAR(msg);
		VAR(msg) = data;
		dbg(DBG_USR2, ("GENERIC_BASE forwarding packet\n"));
		CLR_RED_LED_PIN();
		TOS_CALL_COMMAND(GENERIC_BASE_FLASH_TX)();
		if(TOS_CALL_COMMAND(GENERIC_BASE_TX_PACKET)(data)){
			dbg(DBG_USR2, ("GENERIC_BASE send pending\n"));
			VAR(send_pending)  = 1;
		}
	}
	return tmp;
}

char TOS_EVENT(GENERIC_BASE_SUB_UART_TX_PACKET_DONE)(TOS_MsgPtr data){
	if(VAR(msg) == data){
		dbg(DBG_USR2, ("GENERIC_BASE send buffer free\n"));
		VAR(send_pending) = 0;
	}
	return 1;
}

