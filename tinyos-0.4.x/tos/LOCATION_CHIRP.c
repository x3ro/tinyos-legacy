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
#include "LOCATION_CHIRP.h"

#define TOS_FRAME_TYPE LOCATION_CHIRP_obj_frame
TOS_FRAME_BEGIN(LOCATION_CHIRP_obj_frame) {
	TOS_Msg recv_buf;
	TOS_Msg data_buf;
	TOS_MsgPtr msg;
	char data_send_pending;
	char msg_send_pending;
}
TOS_FRAME_END(LOCATION_CHIRP_obj_frame);

char TOS_COMMAND(LOCATION_CHIRP_INIT)(){
  int i;
    //initialize sub components
   TOS_CALL_COMMAND(LOCATION_CHIRP_SUB_INIT)();
   VAR(msg) = &VAR(recv_buf);
   VAR(data_send_pending) = 0;
   VAR(msg_send_pending) = 0;
   // send out beacon every 1/2 a second
   TOS_COMMAND(LOCATION_CHIRP_SUB_CLOCK_INIT)(255, 0x5);
   VAR(data_buf).data[0] = TOS_LOCAL_ADDRESS;
   for (i=1; i < 29; i=i+2){
     VAR(data_buf).data[i] = 0x96;
     VAR(data_buf).data[i+1] = 0xca;
   }
   return 1;
}

char TOS_COMMAND(LOCATION_CHIRP_START)(){
  return 1;
}

//This handler responds to routing updates.
TOS_MsgPtr TOS_MSG_EVENT(LOCATION_CHIRP_SIGNAL_MSG)(TOS_MsgPtr msg){
  return msg;
}


void TOS_EVENT(LOCATION_CHIRP_SUB_CLOCK)(){
    //clear LED3 when the clock ticks.
    printf("route clock\n");

    //if is the base, then it should send out the route update.
    if(VAR(data_send_pending) == 0){
      VAR(data_send_pending) = TOS_CALL_COMMAND(LOCATION_CHIRP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(LOCATION_CHIRP_SIGNAL_MSG),&VAR(data_buf));
    }
    TOS_CALL_COMMAND(LOCATION_CHIRP_LED1_TOGGLE)();
}


char TOS_EVENT(LOCATION_CHIRP_SEND_DONE)(TOS_MsgPtr data){
	if(data == VAR(msg)) VAR(msg_send_pending) = 0;
	if(data == &VAR(data_buf)) VAR(data_send_pending) = 0;
	return 1;
}



