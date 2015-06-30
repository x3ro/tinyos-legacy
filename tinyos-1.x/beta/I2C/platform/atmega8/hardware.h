/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:		Kamin Whitehouse, Fred Jiang
 * Date last modified:  3/20/03
 *
 */


#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#ifndef TOSH_HARDWARE_ATMEGA8
#define TOSH_HARDWARE_ATMEGA8
#endif // tosh hardware

#include <avrhardware.h>

#define TOSH_CYCLE_TIME_NS 1000

#define HARDWARE_I2C

void inline TOSH_wait_1us() {
	asm volatile ("nop" ::);
}

void inline TOSH_uwait(int u_sec)
{
  /* In most cases (constant arg), the test is elided at compile-time */
    if (u_sec)
    // loop takes 4 cycles, aka 1us 
        asm volatile (
"1:	sbiw	%0,1\n"
"	brne	1b" : "+w" (u_sec));
}


TOSH_ASSIGN_PIN(PW0, B, 0);
TOSH_ASSIGN_PIN(PW1, B, 1);
TOSH_ASSIGN_PIN(PW2, B, 2);
TOSH_ASSIGN_PIN(PW3, B, 3);
TOSH_ASSIGN_PIN(PW4, B, 4);
TOSH_ASSIGN_PIN(PW5, B, 5);
TOSH_ASSIGN_PIN(PW6, D, 4);
TOSH_ASSIGN_PIN(PW7, D, 5);
TOSH_ASSIGN_PIN(PW8, D, 6);
TOSH_ASSIGN_PIN(PW9, D, 7);

TOSH_ASSIGN_PIN(RED_LED, B, 6);
TOSH_ASSIGN_PIN(DEBUG1, B, 7); //debug

TOSH_ASSIGN_PIN(ADC0, C, 0);
TOSH_ASSIGN_PIN(ADC1, C, 1);
TOSH_ASSIGN_PIN(ADC2, C, 2);
TOSH_ASSIGN_PIN(ADC3, C, 3);

TOSH_ASSIGN_PIN(INT0, D, 2);
TOSH_ASSIGN_PIN(INT1, D, 3);

TOSH_ASSIGN_PIN(UART_RXD, D, 0); 
TOSH_ASSIGN_PIN(UART_TXD, D, 1); 

TOSH_ASSIGN_PIN(I2C_CLK, C, 5); 
TOSH_ASSIGN_PIN(I2C_DATA, C, 4); 

TOSH_ALIAS_PIN(I2C_BUS1_SCL, I2C_CLK);
TOSH_ALIAS_PIN(I2C_BUS1_SDA, I2C_DATA);

//annoying second level of indirection because the mica2 and mica2dot
//do not have the same pins aliased by I2C_BUS1
TOSH_ALIAS_PIN(I2C_HW1_SCL, I2C_CLK);
TOSH_ALIAS_PIN(I2C_HW1_SDA, I2C_DATA);

static inline void TOSH_SET_YELLOW_LED_PIN() {}
static inline void TOSH_CLR_YELLOW_LED_PIN() {}
static inline int TOSH_READ_YELLOW_LED_PIN() {}
static inline void TOSH_MAKE_YELLOW_LED_OUTPUT() {}
static inline void TOSH_MAKE_YELLOW_LED_INPUT() {} 

static inline void TOSH_SET_GREEN_LED_PIN() {}
static inline void TOSH_CLR_GREEN_LED_PIN() {}
static inline int TOSH_READ_GREEN_LED_PIN() {}
static inline void TOSH_MAKE_GREEN_LED_OUTPUT() {}
static inline void TOSH_MAKE_GREEN_LED_INPUT() {} 

void TOSH_SET_PIN_DIRECTIONS(void){
	TOSH_MAKE_RED_LED_OUTPUT();
/*    outp(0x00, DDRB);
	  outp(0x0F, DDRC); 
	  outp(0x00, DDRD);
//    outp(DDRB, 0x00);
//    outp(DDRC, 0x0F); 
//    outp(DDRD, 0x00);

TOSH_MAKE_INT0_INPUT();
TOSH_MAKE_INT1_OUTPUT();
TOSH_MAKE_PW9_OUTPUT();
//TOSH_MAKE_PW8_OUTPUT();
TOSH_MAKE_PW7_OUTPUT();
TOSH_MAKE_PW6_OUTPUT();
//    TOSH_MAKE_PW5_OUTPUT();
//    TOSH_MAKE_PW4_OUTPUT();
//    TOSH_MAKE_PW3_OUTPUT();
TOSH_MAKE_PW2_OUTPUT();
TOSH_MAKE_PW1_OUTPUT();
TOSH_MAKE_PW0_OUTPUT();*/
}

#endif //TOSH_HARDWARE_H
