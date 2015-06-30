/*									tab:4
 * RCHIRP.c - periodically emits an active message containing light reading
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
 * History:   created 10/30/2000
 *
 *
 */

#include "tos.h"
#include "RCHIRP.h"

#define TOS_FRAME_TYPE CHIRP_frame
TOS_FRAME_BEGIN(CHIRP_frame) {
  int state;			/* Component counter state */
  int light;			/* Recent light reading */
}
TOS_FRAME_END(CHIRP_frame);

extern const char LOCAL_ADDR_BYTE_1; 
extern const char TOS_LOCAL_ADDRESS;

/* CHIRP_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(CHIRP_INIT)(){
  TOS_CALL_COMMAND(CHIRP_LEDy_on)();   
  TOS_CALL_COMMAND(CHIRP_LEDr_on)();
  TOS_CALL_COMMAND(CHIRP_LEDg_on)();       /* light LEDs */

  TOS_CALL_COMMAND(CHIRP_SUB_INIT)();       /* initialize lower components */
  VAR(state) = 0;
  VAR(light) = 0;
  TOS_CALL_COMMAND(CHIRP_LEDy_off)();
  TOS_CALL_COMMAND(CHIRP_LEDr_off)();   
  TOS_CALL_COMMAND(CHIRP_LEDg_off)();

  printf("CHIRP initialized\n");
  return 1;
}

/* CHIRP_START command: start data reading. 
*/
char TOS_COMMAND(CHIRP_START)(){
  return TOS_CALL_COMMAND(CHIRP_GET_DATA)();
}

/*  CHIRP_DATA_EVENT(data):
    handler for subsystem data event, fired when data ready.
    Sends sensor data ove multihop network
 */
char TOS_EVENT(CHIRP_DATA_EVENT)(int data){
  printf("CHIRP data event\n");
  //  TOS_CALL_COMMAND(CHIRP_LEDr_toggle)();
  VAR(light) = data;
  return TOS_CALL_COMMAND(CHIRP_SEND_DATA)(data);
}

/* Clock Event Handler  */

void  TOS_EVENT (CHIRP_CLOCK_EVENT)(){
  printf("CHIRP clock event\n");
  VAR(state)++;
  TOS_CALL_COMMAND(CHIRP_LEDr_toggle)();
  return TOS_CALL_COMMAND(CHIRP_SEND_DATA)(VAR(state));
    //  TOS_CALL_COMMAND(CHIRP_GET_DATA)(); /* start data reading */
}

