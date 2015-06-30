/*									tab:4
 * CHIRP_ACCEL.c - periodically emits an active message containing light reading
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
#include "CHIRP_ACCEL.h"

/* Utility functions */

char x;

void wait() {
  int i, n = 200;
  for (i = 0; i<n; i++) x++;
}

struct adc_packet{
	char dest;
	char id;
	int count;
	char data[24];
	char extra;
};


#define TOS_FRAME_TYPE CHIRP_ACCEL_frame
TOS_FRAME_BEGIN(CHIRP_ACCEL_frame) {
  volatile int state;			/* Component counter state */
  char buf[30];			/* Send msg buffer */

}
TOS_FRAME_END(CHIRP_ACCEL_frame);

extern const char LOCAL_ADDR_BYTE_1; 
extern const char TOS_LOCAL_ADDRESS;

/* CHIRP_ACCEL_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(CHIRP_ACCEL_INIT)(){
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDy_on)();   
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDr_on)();
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_on)();       /* light LEDs */
  TOS_CALL_COMMAND(CHIRP_ACCEL_SUB_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(CHIRP_ACCEL_CLOCK_INIT)(5);    /* set clock interval */
  VAR(state) = 0;
  {
  struct adc_packet* pack = (struct adc_packet*)VAR(buf);
  pack->id = TOS_LOCAL_ADDRESS;		/* Constant portion of msg buf */
  pack->dest = 0x7e;
  pack->count = 0; 
  }
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDy_off)();
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDr_off)();   
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_off)();
#ifdef FULLPC
  printf("CHIRP_ACCEL initialized\n");
#endif
 TOS_CALL_COMMAND(CHIRP_ACCEL_START)();
  return 1;
}

/* CHIRP_ACCEL_START
   shut off the LEDs and start data reading.
*/
char TOS_COMMAND(CHIRP_ACCEL_START)(){
 
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDr_on)();  		/* Red LED while reading photo */
  TOS_CALL_COMMAND(CHIRP_ACCEL_GET_DATA)(1); /* start data reading */
  return 1;
}

char TOS_EVENT(CHIRP_ACCEL_DATA_EVENT_1)(int data){
  struct adc_packet* pack = (struct adc_packet*)VAR(buf);
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_on)();	
  pack->count ++; 
  data = data >> 2; 
  pack->data[VAR(state)] = data & 0xff;
  VAR(state) ++;
   TOS_CALL_COMMAND(CHIRP_ACCEL_GET_DATA)(2); 
   return 1;
}

char TOS_EVENT(CHIRP_ACCEL_DATA_EVENT_2)(int data){
  struct adc_packet* pack = (struct adc_packet*)VAR(buf);
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_on)();
  pack->count ++; 
  data -= 0x100;
  pack->data[VAR(state)] = data & 0xff;
  VAR(state) ++;
  TOS_CALL_COMMAND(CHIRP_ACCEL_GET_DATA)(3); 
  return 1;
}
char TOS_EVENT(CHIRP_ACCEL_DATA_EVENT_3)(int data){
  struct adc_packet* pack = (struct adc_packet*)VAR(buf);
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_on)();		
  pack->count ++; 
  data -= 0x100;
  pack->data[VAR(state)] = data & 0xff;
  VAR(state) ++;
  TOS_CALL_COMMAND(CHIRP_ACCEL_GET_DATA)(4);
  return 1;
}
char TOS_EVENT(CHIRP_ACCEL_DATA_EVENT_4)(int data){
  struct adc_packet* pack = (struct adc_packet*)VAR(buf);
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_on)();		
  pack->count ++; 
  pack->data[VAR(state)] = data & 0xff;
  VAR(state) ++;
  if(VAR(state) < 16) 
  	TOS_CALL_COMMAND(CHIRP_ACCEL_GET_DATA)(4);
  else
  	TOS_CALL_COMMAND(CHIRP_ACCEL_GET_DATA)(6);
  return 1;
}

char TOS_EVENT(CHIRP_ACCEL_DATA_EVENT_6)(int data){
  struct adc_packet* pack = (struct adc_packet*)VAR(buf);
  pack->count ++; 
  data = data >> 2;
  pack->data[VAR(state)] = data & 0xff;
  VAR(state) ++;
	VAR(state) = 0;
  	if (TOS_CALL_COMMAND(CHIRP_ACCEL_SUB_SEND_MSG)(TOS_BCAST_ADDR,0x06,VAR(buf))) {
  		TOS_CALL_COMMAND(CHIRP_ACCEL_LEDr_off)();  
    		return 1;
	}else {
    		TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_off)();
    		return 0;
  	}
}


/*   AM_msg_handler_0      handler for msg of type 0

     data: msg buffer passed
     on arrival, flash the y LED
*/
char TOS_MSG_EVENT(AM_msg_handler_0)(char* data){
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDy_on)(); wait(); TOS_CALL_COMMAND(CHIRP_ACCEL_LEDy_off)();
  printf("CHIRP_ACCEL: %x, %x\n", data[0], data[1]);
  return 1;
}


/* Clock Event Handler: 
   signaled at end of each clock interval.

 */

char TOS_EVENT(CHIRP_ACCEL_SUB_MSG_SEND_DONE)(char success){
	VAR(state) = 0;
    TOS_CALL_COMMAND(CHIRP_ACCEL_LEDr_on)();
    TOS_CALL_COMMAND(CHIRP_ACCEL_LEDy_on)();
    TOS_CALL_COMMAND(CHIRP_ACCEL_GET_DATA)(1); /* start data reading */
  return 1;
}

/*   CHIRP_ACCEL_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
void TOS_EVENT(CHIRP_ACCEL_CLOCK_EVENT)(){
  TOS_CALL_COMMAND(CHIRP_ACCEL_LEDg_off)();
}

