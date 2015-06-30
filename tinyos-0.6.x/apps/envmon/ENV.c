/*									tab:4
 * ENV.c - take periodic environmental samples (light and temp)
 * perform simple local processing.
 * periodically emit data message
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
 * Authors:   David Culler
 * History:   created 10/5/2000
 *
 *
 */

#include "tos.h"
#include "ENV.h"

typedef struct{
  char src;
  char  msgNum;
  char photo;
  char temp;
} env_Msg;

#define MAX_READ 1
#define SFT_READ 0

//your FRAME
#define TOS_FRAME_TYPE ENV_frame
TOS_FRAME_BEGIN(ENV_frame) {
  TOS_Msg msg;			/* Message to be sent out */
  char send_pending;		/* Variable to store state of buffer*/
  char dataCount;
  int photoSum;
  int tempSum;
}
TOS_FRAME_END(ENV_frame);

/* ENV_INIT:  
   turn on the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(ENV_INIT)(){
  env_Msg* envMsg = (env_Msg *)VAR(msg).data;
  TOS_CALL_COMMAND(ENV_LEDy_on)();   /* light LEDs on init*/
  TOS_CALL_COMMAND(ENV_LEDr_on)();
  TOS_CALL_COMMAND(ENV_LEDg_on)();       
  VAR(dataCount) = 0;
  VAR(photoSum)   = 0;
  VAR(tempSum)    = 0;
  envMsg->src     = TOS_LOCAL_ADDRESS;
  envMsg->msgNum  = 0;
  TOS_CALL_COMMAND(ENV_SUB_INIT)(); /* initialize lower components */
  printf("ENV initialized\n");
  return 1;
}

char TOS_COMMAND(ENV_START)(){
  TOS_CALL_COMMAND(ENV_CLOCK_INIT)(tick1ps);    /* set clock interval */
  TOS_CALL_COMMAND(ENV_LEDy_off)();  
  TOS_CALL_COMMAND(ENV_LEDr_off)();
  TOS_CALL_COMMAND(ENV_LEDg_off)();       
  return 1;
}

/* ENV_send_sample task
   Convert sum of 10-bit readings into 8-bit average
   build and send message
 */
TOS_TASK(ENV_send_sample) {
  env_Msg* envMsg = (env_Msg *)VAR(msg).data;
  TOS_CALL_COMMAND(ENV_LEDr_on)();
  envMsg->msgNum++;
  envMsg->photo   = (char) (VAR(photoSum) >> 2) & 0xFF;
  envMsg->temp    = (char) (VAR(tempSum)  >> 2) & 0xFF;
  VAR(photoSum)   = 0;
  VAR(tempSum)    = 0;
  VAR(dataCount)  = 0;
  if (TOS_CALL_COMMAND(ENV_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(ENV_MSG),
					 &VAR(msg))) {
    VAR(send_pending) = 1;
  }
}


/* Clock Event Handler: 
     - start data collection
 */
void TOS_EVENT(ENV_CLOCK_EVENT)(){
  TOS_CALL_COMMAND(ENV_LEDy_on)();	
  if (VAR(dataCount) < MAX_READ) 
    TOS_CALL_COMMAND(ENV_GET_PHOTO)(); /* start photo data reading */
}

/*  ENV_PHOTO_EVENT(data):
    Accumulate photo reading into frame and start temp collection
 */
char TOS_EVENT(ENV_PHOTO_EVENT)(short data){
  TOS_CALL_COMMAND(ENV_LEDg_on)();	
  VAR(photoSum) =+ data;
  return TOS_CALL_COMMAND(ENV_GET_TEMP)(); /* start temp data reading */
}

/*  ENV_TEMP_EVENT(data):
    Accumulate temp reading into frame and check for msg ready
 */
char TOS_EVENT(ENV_TEMP_EVENT)(short data){
  TOS_CALL_COMMAND(ENV_LEDg_off)();	
  TOS_CALL_COMMAND(ENV_LEDy_off)();	
  VAR(tempSum) =+ data;
  VAR(dataCount)++;
  if (VAR(dataCount) >= MAX_READ) TOS_POST_TASK(ENV_send_sample);
  return 1;
}
/*   ENV_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(ENV_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
  //check to see if the message that finished was ours
  //if so, then clear the send_pending flag.
  TOS_CALL_COMMAND(ENV_LEDr_off)();
  if(&VAR(msg) == msg){ 
    VAR(send_pending) = 0;
  }
  return 1;
}

/*   ENV_MSG msg handler dummy
     data: msg buffer passed
     on arrival, flash the y LED
*/
TOS_MsgPtr TOS_MSG_EVENT(ENV_MSG)(TOS_MsgPtr msg){
  printf("ENV: %x, %x\n", 
	 ((env_Msg *)VAR(msg).data)->src, 
	 ((env_Msg *)VAR(msg).data)->msgNum);
  return msg;
}


