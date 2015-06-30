/*									tab:4
 * RFSENSE.c - display sensor value on the LEDs
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
 * History:   created 10/9/2001
 *
 */

#include "tos.h"
#include "RFSENSE.h"

//Frame Declaration
#define TOS_FRAME_TYPE RFSENSE_frame
TOS_FRAME_BEGIN(RFSENSE_frame) {
  short last;
}
TOS_FRAME_END(RFSENSE_frame);

/* RFSENSE_INIT: 
   Clear all the LEDs and initialize state
*/

char TOS_COMMAND(RFSENSE_INIT)(){
  ADC_PORTMAP_BIND(TOS_ADC_PORT_0, 0);

  //radio
  SET_RFM_CTL0_PIN();
  SET_RFM_CTL1_PIN();

  TOS_CALL_COMMAND(RFSENSE_SUB_INIT)(); 
  return 1;
}

/* RFSENSE_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(RFSENSE_START)(){
  TOS_CALL_COMMAND(RFSENSE_CLOCK_INIT)(tick1ps); 
  return 1;
}

/* Clock Event Handler:
   Increment counter and display
 */
void TOS_EVENT(RFSENSE_CLOCK_EVENT)(){
  TOS_CALL_COMMAND(RFSENSE_GET_DATA)(TOS_ADC_PORT_0);
}

/* Data ready event Handler:
 *   full dark should display 7
 *   full light zero
*/
char TOS_EVENT(RFSENSE_DATA_READY)(short data){
  unsigned short val = (unsigned) data;
  TOS_CALL_COMMAND(RFSENSE_LEDy_off)();
  TOS_CALL_COMMAND(RFSENSE_LEDg_off)();
  TOS_CALL_COMMAND(RFSENSE_LEDr_off)();

  if(val > 500) {
    TOS_CALL_COMMAND(RFSENSE_LEDy_on)();  
    TOS_CALL_COMMAND(RFSENSE_LEDg_on)();  
    TOS_CALL_COMMAND(RFSENSE_LEDr_on)();  
  } 

  return 1;
}
