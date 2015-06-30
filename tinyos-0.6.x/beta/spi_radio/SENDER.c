/*									tab:4
 * SENDER.c - simple application component to display a counter on LEDS
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
 * Authors:   Jason Hill
 * History:   created 1/23/2001
 *            DEC 1/30/2001: fix to use local name for output event
 *
 */

#include "tos.h"
#include "SENDER.h"

//Frame Declaration

#define TOS_FRAME_TYPE SENDER_frame
TOS_FRAME_BEGIN(SENDER_frame) {
        char state;
	TOS_Msg buf;
}
TOS_FRAME_END(SENDER_frame);

typedef struct{
	char source;
	long count;
	long count2;
} SENDER_MSG;

//Commands accepted

char TOS_COMMAND(SENDER_INIT)(){
  int i;
  VAR(state) = 0;
  /* initialize output component */
  for(i = 0; i < 30; i ++){
	((char*)&VAR(buf))[i] = i;
  }
  ((SENDER_MSG*)VAR(buf).data)->count = 0;
  ((SENDER_MSG*)VAR(buf).data)->count2 = 0;
  TOS_CALL_COMMAND(SENDER_SUB_OUTPUT_INIT)();
     TOS_CALL_COMMAND(AM_SEND_MSG)(TOS_BCAST_ADDR, 4, &VAR(buf));
	return 1;
}

char TOS_COMMAND(SENDER_START)(){
  /* initialize clock component and start event processing */
  return TOS_CALL_COMMAND(SENDER_SUB_CLOCK_INIT)(tick64ps);
}

//Events handled

/* Clock Event Handler:
   update LED state as 3-bit counter and set LEDs to match
 */
void TOS_EVENT(SENDER_CLOCK_EVENT)(){
	//the clock is not used.
}

/* Output Completion Event Handler 
   Indicate that notification was successful
*/
char TOS_EVENT(SENDER_OUTPUT_COMPLETE)(char success){
	return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(cnt_to_leds)(TOS_MsgPtr msg){
	
	char read = (((SENDER_MSG*)(msg->data))->count) & 0xf;
//	if((read & 0x1) == 0) SET_RED_LED_PIN(); else CLR_RED_LED_PIN();
	if((read & 0x2) == 0) SET_GREEN_LED_PIN(); else CLR_GREEN_LED_PIN();
	if((read & 0x4) == 0) SET_YELLOW_LED_PIN(); else CLR_YELLOW_LED_PIN();
	return msg;
}

char TOS_EVENT(TX_DONE)(TOS_MsgPtr x){
  if(READ_RED_LED_PIN()) CLR_RED_LED_PIN();
  else SET_RED_LED_PIN();
  ((SENDER_MSG*)VAR(buf).data)->source = TOS_LOCAL_ADDRESS;	
  if((++((SENDER_MSG*)VAR(buf).data)->count) == 0)
	 ((SENDER_MSG*)VAR(buf).data)->count2 ++;	
  TOS_CALL_COMMAND(AM_SEND_MSG)(TOS_BCAST_ADDR, 4, &VAR(buf));
	
	return 1;
}
