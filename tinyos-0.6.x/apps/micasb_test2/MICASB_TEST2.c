 /*									tab:4
 * tone_detect.c - simple application to test the microphone by turning
 *                 on yellow led when sounder's tone is detected
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
#include "MICASB_TEST2.h"

//Frame Declaration
#define TOS_FRAME_TYPE MICASB_TEST2_frame
TOS_FRAME_BEGIN(MICASB_TEST2_frame) {
        char state;
	char read;
	char count;
        char light;
        char detected;
}
TOS_FRAME_END(MICASB_TEST2_frame);


/* MICASB_TEST2_INIT: 
   Clear all the LEDs, turn sounder off, and initialize state
*/

char TOS_COMMAND(MICASB_TEST2_INIT)(){
  TOS_CALL_COMMAND(MICASB_TEST2_LEDr_off)();
  TOS_CALL_COMMAND(MICASB_TEST2_LEDy_off)();
  TOS_CALL_COMMAND(MICASB_TEST2_LEDg_off)();
  VAR(state)=0;
  VAR(read) =0;
  VAR(count) = 0;
  VAR(light) = 0;
  VAR(detected) = 0;
  TOS_CALL_COMMAND(MICASB_TEST2_SUB_INIT)(tick128ps); 
  TOS_CALL_COMMAND(MICASB_TEST2_UART_INIT)();
  TOS_CALL_COMMAND(MICASB_TEST2_SOUNDER_INIT)();
  TOS_CALL_COMMAND(MICASB_TEST2_PHOTO_INIT)();

  /* Turn Microphone on and set the pot setting to 64,
     use bandpass filter output, no interrupt*/
  TOS_CALL_COMMAND(MICASB_TEST2_MIC_INIT)();
  TOS_CALL_COMMAND(MICASB_TEST2_MIC_PWR)(1);
  TOS_CALL_COMMAND(MICASB_TEST2_MIC_MUX_SEL)(1);
  TOS_CALL_COMMAND(MICASB_TEST2_POT_ADJUST)(64);
  TOS_CALL_COMMAND(MICASB_TEST2_MIC_TONE_INTR)(0);

  return 1;
}

/* MICASB_TEST2_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(MICASB_TEST2_START)(){
  return 1;
}

/* Clock Event Handler:
   Toggle the Red LED and sounder on each tick.
 */
void TOS_EVENT(MICASB_TEST2_CLOCK_EVENT)(){
  char state = VAR(state);
  char in;

  if (state < 5) {
    VAR(state)++;
    TOS_CALL_COMMAND(MICASB_TEST2_LEDr_on)();  
  } else {
    VAR(state)++;
    if (VAR(state) > 25)
      VAR(state) = 0;
    TOS_CALL_COMMAND(MICASB_TEST2_LEDr_off)();
  }

  if (state == 0){
    TOS_CALL_COMMAND(MICASB_TEST2_GET_PHOTO_DATA)();
  }

  /* Read the input from the tone detector */
  in = TOS_CALL_COMMAND(MICASB_TEST2_READ_TONE_DETECTOR)();

  // Low pass filtering
  if (in == 0){
     if (VAR(count) < 32)
       VAR(count)++;
  }else{
     if (VAR(count) > 0)
       VAR(count)--;
  }

  // Turn on YELLOW LED if detected
  if (VAR(detected) == 1){
     VAR(light)--;
     if (VAR(light) == 0){
        TOS_CALL_COMMAND(MICASB_TEST2_LEDy_off)();
        VAR(detected) = 0;
     }
  }

  // Threshold detection setting
  if (VAR(count) > 5){
     TOS_CALL_COMMAND(MICASB_TEST2_LEDy_on)();
     VAR(detected) = 1;
     VAR(light) = 16;
  }
   
}

char TOS_EVENT(MICASB_TEST2_MIC_TONE_DETECTED)(void){
  return 1;
}

/* This event is triggered from the ADC */
char TOS_EVENT(MICASB_TEST2_DATA_EVENT)(short data){
  //TOS_CALL_COMMAND(MICASB_TEST2_SEND_DATA)(data >> 2);
  char value = data >> 7;

  if ((value & 0x7) <= 0x2)
    TOS_COMMAND(MICASB_TEST2_SOUNDER_ON)();
  else
    TOS_COMMAND(MICASB_TEST2_SOUNDER_OFF)();
  return 1;
}

/* This even is triggered from the UART */
char TOS_EVENT(MICASB_TEST2_DATA_SEND_DONE)(char success){
  return 1;
}

char TOS_EVENT(MICASB_TEST2_DATA_RECV_DONE)(char data, char success){
  return 1;
}







