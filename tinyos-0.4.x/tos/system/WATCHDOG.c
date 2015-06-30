/*									tab:4
 * WATCHDOG.c
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
 * Authors:   Deepak Ganesan
 * History:   created 07/15/2001
 *
 * Sets the watchdog timer to the specified period, and powers down the big guy 
 * on the rene. The watchdog reset will restart the rene after the period.
 * prescale settings to choose from are defined in hardware.h (also shown below)
 *
 * Watchdog Prescaler
 * #define period16 0x00 // 47ms
 * #define period32 0x01 // 94ms
 * #define period64 0x02 // 0.19s
 * #define period128 0x03 // 0.38s
 * #define period256 0x04 // 0.75s
 * #define period512 0x05 // 1.5s
 * #define period1024 0x06 // 3.0s
 * #define period2048 0x07 // 6.0s
 *
 *
 */


#include "tos.h"
#include "WATCHDOG.h"

void TOS_COMMAND(SET_WATCHDOG)(char prescale) {

  cli();   //disable interrupts

  /* for the rene */
  /*
  outp(0x00, DDRA);
  outp(0x07, DDRB); //Set rfm txmod/ctrl1/ctrl2 bits to output
  outp(0x00, DDRC);
  outp(0x00, DDRD);
  outp(0xff, PORTA);
  outp(0xf8, PORTB); //Set rfm txmod/ctrl1/ctrl2 bits to 0
  outp(0xff, PORTC);
  outp(0xff, PORTD);
  */
  /* for the dot */
  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRC);
  outp(0x00, DDRD);
  outp(0xff, PORTA);
  outp(0xff, PORTB);
  outp(0xff, PORTC);
  outp(0xff, PORTD);
  MAKE_RFM_TXD_OUTPUT();
  MAKE_RFM_CTL0_OUTPUT();
  MAKE_RFM_CTL1_OUTPUT();
  CLR_RFM_TXD_PIN();
  CLR_RFM_CTL0_PIN();
  CLR_RFM_CTL1_PIN();

  //Set watchdog timeout to specified period
  wdt_enable(prescale);

  //Set processor to PowerDown Mode
  sbi(MCUCR, SM1);
  cbi(MCUCR, SM0);
  sbi(MCUCR, SE); 
  asm volatile ("sleep" ::);
  asm volatile ("nop" ::);
  asm volatile ("nop" ::);

}
 
