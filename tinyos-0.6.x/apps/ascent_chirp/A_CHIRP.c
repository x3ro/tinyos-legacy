/*									tab:4
 * A_CHIRP.c - ASCENT-enabled chirp
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
 * Authors:   Thanos Stathopoulos
 * 
 *
 */

#include "tos.h"
#include "A_CHIRP.h"
#include "ascent_msgs.h"

#ifndef INFINITE_CHIRPS
#define INFINITE_CHIRPS 0
#endif

void time_expired();

//your FRAME
#define TOS_FRAME_TYPE A_CHIRP_frame
TOS_FRAME_BEGIN(A_CHIRP_frame) {
  uint16_t count;			/* Component counter state */
  TOS_Msg data; 		/* Message to be sent out */
  char send_pending;		/* Variable to store state of buffer*/
	char yellow;
	char task_posted;
	Timer t;
	uint8_t check;
	uint8_t rand;
}
TOS_FRAME_END(A_CHIRP_frame);

TOS_TASK(A_CHIRP_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(A_CHIRP_TIMER)(&VAR(t), 5*timer1ps)==0) {
		TOS_POST_TASK(A_CHIRP_TIMER_TASK);                                          }
}               


/* A_CHIRP_INIT:  
   turn on the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/


char TOS_COMMAND(A_CHIRP_INIT)(){
  TOS_CALL_COMMAND(A_CHIRP_SUB_INIT)();       /* initialize lower components */
  VAR(count) = 0;
	/* Create the TOS message */
	VAR(data).addr=TOS_LOCAL_ADDRESS;
	VAR(data).type=0x6;
	VAR(data).group=DEFAULT_LOCAL_GROUP;
	initTimer(&VAR(t));
	setPeriodic(&VAR(t), 5*timer1ps);
	VAR(t).f=time_expired;
//	TOS_CALL_COMMAND(A_CHIRP_RTC_INIT)(128+VAR(rand), 6);
	if (TOS_CALL_COMMAND(A_CHIRP_TIMER)(&VAR(t), 5*timer1ps)==0) { 
		TOS_POST_TASK(A_CHIRP_TIMER_TASK);
	}
  return 1;
}


char TOS_COMMAND(A_CHIRP_START)(){
  return 1;
}


TOS_TASK(A_CHIRP_TRYAGAIN)
{
	if (TOS_CALL_COMMAND(A_CHIRP_XMIT)(VAR(count))==0) {
		TOS_POST_TASK(A_CHIRP_TRYAGAIN);
	} else {

		if (VAR(yellow))
			SET_YELLOW_LED_PIN();
		else
			CLR_YELLOW_LED_PIN();
		VAR(yellow)= ! VAR(yellow);  

	}
}

/* Clock Event Handler: 
   signaled at end of each clock interval.

 */

void time_expired()
{
/*
	if (VAR(yellow)) 
		SET_YELLOW_LED_PIN();
	else 
		CLR_YELLOW_LED_PIN();

	VAR(yellow)= ! VAR(yellow);
*/
	 if (VAR(count) < INFINITE_CHIRPS && VAR(send_pending) == 0) {
		//increment the counter
	//	VAR(count) ++;
		//turn on the red led while data is being read.

		if ((TOS_CALL_COMMAND(A_CHIRP_XMIT)(VAR(count))==0)) {
//			TOS_CALL_COMMAND(A_CHIRP_RTC_INIT)(128+VAR(rand), 6);
			TOS_POST_TASK(A_CHIRP_TRYAGAIN);
//			VAR(task_posted)=1;
//			flip_error_led();
		} else {

			if (VAR(yellow))
				SET_YELLOW_LED_PIN();
			else
				CLR_YELLOW_LED_PIN();
			VAR(yellow)= ! VAR(yellow);  

		}
			
/*
		if (VAR(check)==0) {
			TOS_CALL_COMMAND(A_CHIRP_RTC_INIT)();	
			VAR(check)=1;
		}
*/
	} 
}


/*  A_CHIRP_DATA_EVENT(data):
    handler for subsystem data event, fired when data ready.
    Put int data in a broadcast message to handler 0.
    Post msg.
 */

char TOS_EVENT(A_CHIRP_TX_PACKET_DONE)(TOS_MsgPtr msg)
{
	//check to see if the message that finished was yours.
	//if so, then clear the send_pending flag.
  if(&VAR(data) == msg){ 
	  VAR(send_pending) = 0;
  }
  return 1;
}

char TOS_COMMAND(A_CHIRP_XMIT)(int count)
{
	int i=0, j=0;
	j=0;

	if (INFINITE_CHIRPS==0)
		return 0;

	for (i=0; i<30; i++) {
		VAR(data).data[i]=++j;
	}

	if (VAR(send_pending)==1) {
		return 0;	
	}

	VAR(data).data[0]=(uint8_t)count;
	if (TOS_COMMAND(ASCENT_TX_PACKET)(&VAR(data))) {
		VAR(send_pending)=1;
		return 1;
	}


	return 0;
}	

TOS_MsgPtr TOS_EVENT(A_CHIRP_RX_PACKET)(TOS_MsgPtr msg) 
{
	// EMPTY
	return NULL;
}

/*
void TOS_EVENT(A_CHIRP_RTC_EVENT)()
{
	time_expired();
}
*/
