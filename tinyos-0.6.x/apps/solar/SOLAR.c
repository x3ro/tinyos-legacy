/*									tab:4
 * SOLAR.c - periodically emits an active message containing light reading
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
#include "SOLAR.h"

/* Utility functions */

char x;
extern const char TOS_LOCAL_ADDRESS;

void wait() {
  int i, n = 200;
  for (i = 0; i<n; i++) x++;
}



#define TOS_FRAME_TYPE SOLAR_frame
TOS_FRAME_BEGIN(SOLAR_frame) {
  int sleep_count;			/* Component counter state */
  int light;			/* Recent light reading */
  char buf[30];			/* Send msg buffer */

}
TOS_FRAME_END(SOLAR_frame);

extern const char LOCAL_ADDR_BYTE_1; 
extern const char TOS_LOCAL_ADDRESS;

/* SOLAR_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(SOLAR_INIT)(){
  TOS_CALL_COMMAND(SOLAR_LEDy_on)();   
  TOS_CALL_COMMAND(SOLAR_LEDr_on)();
  TOS_CALL_COMMAND(SOLAR_LEDg_on)();       /* light LEDs */
  TOS_CALL_COMMAND(SOLAR_SUB_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(SOLAR_CLOCK_INIT)(6);    /* set clock interval */
  VAR(sleep_count) = 0;
  VAR(light) = 0;
  VAR(buf)[1] = 0x5;
  VAR(buf)[0] = TOS_LOCAL_ADDRESS;
  TOS_CALL_COMMAND(SOLAR_LEDy_off)();
  TOS_CALL_COMMAND(SOLAR_LEDr_off)();   
  TOS_CALL_COMMAND(SOLAR_LEDg_off)();
#ifdef FULLPC
  printf("SOLAR initialized\n");
#endif
  return 1;
}

/* SOLAR_START
   shut off the LEDs and start data reading.
*/
char TOS_COMMAND(SOLAR_START)(){
 
  TOS_CALL_COMMAND(SOLAR_LEDr_on)();  		/* Red LED while reading photo */
  TOS_CALL_COMMAND(SOLAR_GET_DATA)(); /* start data reading */
  return 1;
}

/*  SOLAR_DATA_EVENT(data):
    handler for subsystem data event, fired when data ready.
    Put int data in a broadcast message to handler 0.
    Post msg.
 */
char TOS_EVENT(SOLAR_DATA_EVENT)(int data){
  TOS_CALL_COMMAND(SOLAR_LEDr_off)();  
  TOS_CALL_COMMAND(SOLAR_LEDg_on)();			/* Green LED while sending */
  VAR(light) = data;
  VAR(buf)[6] = (char)(data >> 8) & 0xff;
  VAR(buf)[7] = ((char)data) & 0xff;
  if (TOS_CALL_COMMAND(SOLAR_SUB_SEND_MSG)(0x5,0x06,VAR(buf))) 
    return 1;
  else {
    TOS_CALL_COMMAND(SOLAR_LEDg_off)();
    return 0;
  }
}

/*   SOLAR_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(SOLAR_SUB_MSG_SEND_DONE)(char success){
  TOS_CALL_COMMAND(SOLAR_LEDg_off)();
  TOS_CALL_COMMAND(SOLAR_SUB_PWR)(0);       /* turn on lower components */
  sbi(MCUCR,SM0);
  sbi(MCUCR,SM1);
  while(inp(ASSR) & 0x7){}
  return 1;
}

/*   AM_msg_handler_0      handler for msg of type 0

     data: msg buffer passed
     on arrival, flash the y LED
*/
char TOS_MSG_EVENT(AM_msg_handler_0)(char* data){
 TOS_CALL_COMMAND(SOLAR_LEDy_on)(); wait(); TOS_CALL_COMMAND(SOLAR_LEDy_off)();
#ifdef FULLPC
  printf("SOLAR: %x, %x\n", data[0], data[1]);
#endif
  return 1;
}


/* Clock Event Handler: 
   signaled at end of each clock interval.

 */
#define NUM_SLEEP 2 

void TOS_EVENT(SOLAR_CLOCK_EVENT)(){
  if (VAR(sleep_count)++ == NUM_SLEEP) {
    VAR(sleep_count) = 0;
    TOS_CALL_COMMAND(SOLAR_LEDr_on)();
    TOS_CALL_COMMAND(SOLAR_SUB_PWR)(1);       /* turn on lower components */
    cbi(MCUCR,SM0);
    cbi(MCUCR,SM1);
    wait();
    TOS_CALL_COMMAND(SOLAR_GET_DATA)(); /* start data reading */
  } else{
	//must spin wait for the counter to update.  It is tempting
        //to wait for the check in the MAIN area so that useful work
        //could be done but there is no way to gurante that we aren't
        //already after the check instruction and before the sleep...
        outp(0x00, TCNT2);
        while(inp(ASSR) & 0x7){}
        return;
  }
}

