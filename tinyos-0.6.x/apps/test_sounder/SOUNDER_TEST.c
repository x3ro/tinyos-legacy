/*									tab:4
 * sounder_test.c - simple application to chirp the sounder
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:   Alec Woo
 * History:   created 1/23/2002
 *
 */

#include "tos.h"
#include "SOUNDER_TEST.h"


//Frame Declaration
#define TOS_FRAME_TYPE SOUNDER_TEST_frame
TOS_FRAME_BEGIN(SOUNDER_TEST_frame) {
        char state;
}
TOS_FRAME_END(SOUNDER_TEST_frame);


/* SOUNDER_TEST_INIT: 
   Clear all the LEDs, turn sounder off, and initialize state
*/

char TOS_COMMAND(SOUNDER_TEST_INIT)(){
  TOS_CALL_COMMAND(SOUNDER_TEST_LEDr_off)();
  TOS_CALL_COMMAND(SOUNDER_TEST_LEDy_off)();
  TOS_CALL_COMMAND(SOUNDER_TEST_LEDg_off)();
  VAR(state)=0;
  TOS_CALL_COMMAND(SOUNDER_TEST_SUB_INIT)(tick1ps); 
  TOS_CALL_COMMAND(SOUNDER_INIT)();
  return 1;
}

/* SOUNDER_TEST_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(SOUNDER_TEST_START)(){
  return 1;
}

/* Clock Event Handler:
   Toggle the Red LED and sounder on each tick.
 */
void TOS_EVENT(SOUNDER_TEST_CLOCK_EVENT)(){
  char state = VAR(state);
  if (state == 0) {
    VAR(state) = 1;
    TOS_CALL_COMMAND(SOUNDER_TEST_LEDr_on)();  
    TOS_CALL_COMMAND(SOUNDER_PWR_ON)();
  } else {
    VAR(state) = 0;
    TOS_CALL_COMMAND(SOUNDER_TEST_LEDr_off)();
    TOS_CALL_COMMAND(SOUNDER_PWR_OFF)();
  }
}



