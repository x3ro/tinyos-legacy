/*									tab:4
 * temp_test.c - simple application to test the temperature sensor
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
#include "TEMP_TEST.h"


//Frame Declaration
#define TOS_FRAME_TYPE TEMP_TEST_frame
TOS_FRAME_BEGIN(TEMP_TEST_frame) {
        char state;
}
TOS_FRAME_END(TEMP_TEST_frame);


/* TEMP_TEST_INIT: 
   Clear all the LEDs and initialize state
*/

char TOS_COMMAND(TEMP_TEST_INIT)(){
  VAR(state)=0;
  TOS_CALL_COMMAND(TEMP_TEST_LEDr_off)();
  TOS_CALL_COMMAND(TEMP_TEST_LEDy_off)();
  TOS_CALL_COMMAND(TEMP_TEST_LEDg_off)();
  TOS_CALL_COMMAND(TEMP_TEST_SUB_INIT)(tick1ps); 
  TOS_CALL_COMMAND(TEMP_TEST_UART_INIT)();
  TOS_CALL_COMMAND(TEMP_TEST_TEMP_INIT)();
  return 1;
}

/* TEMP_TEST_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(TEMP_TEST_START)(){
  return 1;
}

/* Clock Event Handler:
   Toggle the Red LED on each tick.
 */
void TOS_EVENT(TEMP_TEST_CLOCK_EVENT)(){
  char state = VAR(state);
  if (state == 0) {
    VAR(state) = 1;
    TOS_CALL_COMMAND(TEMP_TEST_LEDr_on)(); 
    TOS_CALL_COMMAND(TEMP_TEST_GET_DATA)();
  } else {
    VAR(state) = 0;
    TOS_CALL_COMMAND(TEMP_TEST_LEDr_off)();
  }
}

/* UART Event Handler
 */
char TOS_EVENT(TEMP_TEST_UART_TX_READY_EVENT)(char success){
  return 1;
}

char TOS_EVENT(TEMP_TEST_UART_RX_READY_EVENT)(char data, char error){
  return 1;
}

/* TEMP Event Handler:
 */
char TOS_EVENT(TEMP_TEST_DATA_EVENT)(short data){ 
  TOS_CALL_COMMAND(TEMP_TEST_SEND_BYTE)(data >> 2);
  return 1;
}



