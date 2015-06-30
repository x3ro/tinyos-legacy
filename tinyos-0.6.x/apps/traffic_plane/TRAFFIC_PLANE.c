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
 * Authors:		Jason Hill
 *
 *
 */


//this components explores routing topology and then broadcasts back
// light readings.

#include "tos.h"
#include "TRAFFIC_PLANE.h"
#include "dbg.h"

#define TOS_FRAME_TYPE TRAFFIC_PLANE_obj_frame
TOS_FRAME_BEGIN(TRAFFIC_PLANE_obj_frame) {
	TOS_Msg recv_buf;
	TOS_Msg data_buf;
	TOS_MsgPtr msg;
	char data_send_pending;
	char bs_send_pending;
	char getData;
}
TOS_FRAME_END(TRAFFIC_PLANE_obj_frame);

char TOS_COMMAND(TRAFFIC_PLANE_INIT)(){
    //initialize sub components
   TOS_CALL_COMMAND(TRAFFIC_PLANE_SUB_INIT)();
   VAR(msg) = &VAR(recv_buf);
   VAR(data_send_pending) = 0;
   VAR(bs_send_pending) = 0;
   VAR(getData) = 0;
   // send out beacon every 1/2 a second
   TOS_COMMAND(TRAFFIC_PLANE_SUB_CLOCK_INIT)(255, 0x04);
   VAR(data_buf).data[0] = 0;
   return 1;
}

char TOS_COMMAND(TRAFFIC_PLANE_START)(){
	return 1;
}

//This handler responds to routing updates.
TOS_MsgPtr TOS_MSG_EVENT(TRAFFIC_PLANE_READ_MSG)(TOS_MsgPtr msg){
    TOS_MsgPtr tmp;
    char* data = msg->data;

    //clear LED2 when update is received.
    TOS_CALL_COMMAND(TRAFFIC_PLANE_LED2_TOGGLE)();

    //send the update packet.
    if(VAR(bs_send_pending) == 0){
      VAR(bs_send_pending) = TOS_CALL_COMMAND(TRAFFIC_PLANE_SUB_SEND_MSG)(TOS_UART_ADDR, AM_MSG(TRAFFIC_PLANE_READ_MSG),msg);
    }else{
      return msg;
    }
    
    VAR(getData) = 1;
    tmp = VAR(msg);
    VAR(msg) = msg;
    return tmp;
}


void TOS_EVENT(TRAFFIC_PLANE_SUB_CLOCK)(){
    //clear LED3 when the clock ticks.
    dbg(DBG_USR1, ("traffic route clock\n"));

    //if is the base, then it should send out the route update.
    if(VAR(data_send_pending) == 0 && VAR(getData) == 0){
      VAR(data_send_pending) = TOS_CALL_COMMAND(TRAFFIC_PLANE_SUB_SEND_MSG)(TOS_BCAST_ADDR, 7,&VAR(data_buf));
      TOS_CALL_COMMAND(TRAFFIC_PLANE_LED3_TOGGLE)();
    }

    VAR(getData) = 0;

    TOS_CALL_COMMAND(TRAFFIC_PLANE_LED1_TOGGLE)();
}


char TOS_EVENT(TRAFFIC_PLANE_SEND_DONE)(TOS_MsgPtr data){
	if(data == VAR(msg)) VAR(bs_send_pending) = 0;
	if(data == &VAR(data_buf)) VAR(data_send_pending) = 0;
	return 1;
}



