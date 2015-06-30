/*									tab:4
 * IDLE.c - display sensor value on the LEDs
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
#include "IDLE.h"

//Frame Declaration
#define TOS_FRAME_TYPE IDLE_frame
TOS_FRAME_BEGIN(IDLE_frame) {
}
TOS_FRAME_END(IDLE_frame);

/* IDLE_INIT: 
   Clear all the LEDs and initialize state
*/

char TOS_COMMAND(IDLE_INIT)(){
  return 1;
}

/* IDLE_START: 
   initialize clock component to generate periodic events.
*/
volatile int val = 0;

char TOS_COMMAND(IDLE_START)(){
  volatile int *foo = &val;
  *foo = 0;

  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRD);
  outp(0x00, DDRE);
  outp(0xff, PORTA);
  outp(0xff, PORTB);
  outp(0xff, PORTC);
  outp(0xff, PORTD);

  MAKE_RED_LED_OUTPUT();
  MAKE_GREEN_LED_OUTPUT();
  MAKE_YELLOW_LED_OUTPUT();

  CLR_FLASH_IN_PIN();

  MAKE_RFM_CTL0_OUTPUT();
  MAKE_RFM_CTL1_OUTPUT();
  CLR_RFM_CTL0_PIN();
  CLR_RFM_CTL1_PIN();

  MAKE_POT_SELECT_OUTPUT();
  CLR_POT_SELECT_PIN();

  MAKE_RFM_TXD_OUTPUT();
  CLR_RFM_TXD_PIN();

  MAKE_POT_POWER_OUTPUT();
  CLR_POT_POWER_PIN();

  MAKE_ONE_WIRE_OUTPUT();
  CLR_ONE_WIRE_PIN();

  MAKE_BOOST_ENABLE_OUTPUT();
  CLR_BOOST_ENABLE_PIN();

  while(1) {
//    *foo++;
    cli();
    sbi(MCUCR, SM1);
    cbi(MCUCR, SM0);
    sbi(MCUCR, SE); 

    asm volatile ("sleep" ::);
    asm volatile ("nop" ::);
    asm volatile ("nop" ::);
  }

  return 1;
}
