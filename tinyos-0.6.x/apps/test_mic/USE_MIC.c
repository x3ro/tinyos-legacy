/*									tab:4
 * use_mic.c - simple application to test the microphone
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
 *
 */

#include "tos.h"
#include "USE_MIC.h"

typedef struct{
  char samples[30]; //holds 24 samples if compacted together
}mic_data;

//Frame Declaration
#define TOS_FRAME_TYPE USE_MIC_frame
TOS_FRAME_BEGIN(USE_MIC_frame) {
        char state;
	char count;
}
TOS_FRAME_END(USE_MIC_frame);


/* USE_MIC_INIT: 
   Clear all the LEDs, turn sounder off, and initialize state
*/

char TOS_COMMAND(USE_MIC_INIT)(){
  TOS_CALL_COMMAND(USE_MIC_LEDr_off)();
  TOS_CALL_COMMAND(USE_MIC_LEDy_off)();
  TOS_CALL_COMMAND(USE_MIC_LEDg_off)();
  VAR(state)=0;
  TOS_CALL_COMMAND(USE_MIC_SUB_INIT)(tick1ps); 
  TOS_CALL_COMMAND(USE_MIC_UART_INIT)();
  /* Turn Microphone on and set the pot setting to 16*/
  TOS_CALL_COMMAND(USE_MIC_MIC_INIT)();
  TOS_CALL_COMMAND(USE_MIC_MIC_PWR)(1);
  TOS_CALL_COMMAND(USE_MIC_MIC_MUX_SEL)(1);
  TOS_CALL_COMMAND(USE_MIC_POT_ADJUST)(16);

  return 1;
}

/* USE_MIC_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(USE_MIC_START)(){
  TOS_CALL_COMMAND(USE_MIC_SET_SAMPLING_RATE)(sample480us);
  TOS_CALL_COMMAND(USE_MIC_GET_CONTINUOUS_DATA)();
  return 1;
}

/* Clock Event Handler:
   Toggle the Red LED and sounder on each tick.
 */
void TOS_EVENT(USE_MIC_CLOCK_EVENT)(){
  char state = VAR(state);
  
  if (state < 3) {
    VAR(state)++;
    TOS_CALL_COMMAND(USE_MIC_LEDr_on)();  
  } else {
    VAR(state)++;
    if (VAR(state) > 5)
      VAR(state) = 0;
    TOS_CALL_COMMAND(USE_MIC_LEDr_off)();
  }

}

char TOS_EVENT(USE_MIC_MIC_TONE_DETECTED)(void){
  return 1;
}

/* This event is triggered from the ADC */
char TOS_EVENT(USE_MIC_DATA_EVENT)(short data){
  TOS_CALL_COMMAND(USE_MIC_SEND_DATA)(data >> 2);
  return 1;
}

/* This even is triggered from the UART */
char TOS_EVENT(USE_MIC_DATA_SEND_DONE)(char success){
  return 1;
}

char TOS_EVENT(USE_MIC_DATA_RECV_DONE)(char data, char success){
  return 1;
}









