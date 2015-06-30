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
#include "TONE_DETECT.h"

//Frame Declaration
#define TOS_FRAME_TYPE TONE_DETECT_frame
TOS_FRAME_BEGIN(TONE_DETECT_frame) {
        char state;
	char read;
	char count;
        char light;
        char detected;
	char mic_reboot;
}
TOS_FRAME_END(TONE_DETECT_frame);


/* TONE_DETECT_INIT: 
   Clear all the LEDs, turn sounder off, and initialize state
*/

char TOS_COMMAND(TONE_DETECT_INIT)(){
  TOS_CALL_COMMAND(TONE_DETECT_LEDr_off)();
  TOS_CALL_COMMAND(TONE_DETECT_LEDy_off)();
  TOS_CALL_COMMAND(TONE_DETECT_LEDg_off)();
  VAR(state)=0;
  VAR(read) =0;
  VAR(count) = 0;
  VAR(light) = 0;
  VAR(detected) = 0;
  TOS_CALL_COMMAND(TONE_DETECT_SUB_INIT)(tick128ps); 
  TOS_CALL_COMMAND(TONE_DETECT_UART_INIT)();
  /* Turn Microphone on and set the pot setting to 64,
     use bandpass filter output, no interrupt*/
  TOS_CALL_COMMAND(TONE_DETECT_MIC_INIT)();
  TOS_CALL_COMMAND(TONE_DETECT_MIC_PWR)(1);
  TOS_CALL_COMMAND(TONE_DETECT_MIC_MUX_SEL)(1);
  TOS_CALL_COMMAND(TONE_DETECT_POT_ADJUST)(64);
  TOS_CALL_COMMAND(TONE_DETECT_MIC_TONE_INTR)(0);

  return 1;
}

/* TONE_DETECT_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(TONE_DETECT_START)(){
  return 1;
}

/* Clock Event Handler:
   Toggle the Red LED and sounder on each tick.
 */
void TOS_EVENT(TONE_DETECT_CLOCK_EVENT)(){
  char state = VAR(state);
  char in;

  /* Periodically power cycle the microphone circuit
     to avoid the oscillation bug in the hardware. */
  if (VAR(mic_reboot) == 0){
    TOS_CALL_COMMAND(TONE_DETECT_MIC_PWR)(1);
  }
  if (++VAR(mic_reboot) > 126){
    TOS_CALL_COMMAND(TONE_DETECT_MIC_PWR)(0);
    VAR(mic_reboot)=0;
  }

  if (state < 5) {
    VAR(state)++;
    TOS_CALL_COMMAND(TONE_DETECT_LEDr_on)();  
  } else {
    VAR(state)++;
    if (VAR(state) > 25)
      VAR(state) = 0;
    TOS_CALL_COMMAND(TONE_DETECT_LEDr_off)();
  }

  /* Read the input from the tone detector */
  in = TOS_CALL_COMMAND(TONE_DETECT_READ_TONE_DETECTOR)();

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
        TOS_CALL_COMMAND(TONE_DETECT_LEDy_off)();
        VAR(detected) = 0;
     }
  }

  // Threshold detection setting
  if (VAR(count) > 5){
     TOS_CALL_COMMAND(TONE_DETECT_LEDy_on)();
     VAR(detected) = 1;
     VAR(light) = 16;
  }
   
}

char TOS_EVENT(TONE_DETECT_MIC_TONE_DETECTED)(void){
  return 1;
}

/* This event is triggered from the ADC */
char TOS_EVENT(TONE_DETECT_DATA_EVENT)(short data){
  TOS_CALL_COMMAND(TONE_DETECT_SEND_DATA)(data >> 2);
  return 1;
}

/* This even is triggered from the UART */
char TOS_EVENT(TONE_DETECT_DATA_SEND_DONE)(char success){
  return 1;
}

char TOS_EVENT(TONE_DETECT_DATA_RECV_DONE)(char data, char success){
  return 1;
}


