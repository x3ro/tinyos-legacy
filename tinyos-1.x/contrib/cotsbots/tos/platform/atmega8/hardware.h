/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
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
 * Authors:		Sarah Bergbreiter
 * Date last modified:  7/9/02
 *
 */

/* A somewhat abstacted view of the hardware (but not a full hardware
   abstraction layer) */

#ifndef TOSH_MOTOR_HARDWARE_H
#define TOSH_MOTOR_HARDWARE_H

#include <avrhardware.h>

TOSH_ASSIGN_PIN(PW0, D, 5);
TOSH_ASSIGN_PIN(PW1, D, 6);
TOSH_ASSIGN_PIN(RED_LED, D, 4);

// These pins not currently in use as LED, but allows you to access the
// MPW components through the LED interface
TOSH_ASSIGN_PIN(GREEN_LED, D, 7);
TOSH_ASSIGN_PIN(YELLOW_LED, B, 0);

TOSH_ASSIGN_PIN(MPW0, D, 7);
TOSH_ASSIGN_PIN(MPW1, B, 0);

TOSH_ASSIGN_PIN(MOTOR1PWM, B, 1);
TOSH_ASSIGN_PIN(MOTOR1DIR, B, 6);
TOSH_ASSIGN_PIN(MOTOR2PWM, B, 2);
TOSH_ASSIGN_PIN(MOTOR2DIR, B, 7);

TOSH_ASSIGN_PIN(MINT0, D, 2);
TOSH_ASSIGN_PIN(MINT1, D, 3);

TOSH_ASSIGN_PIN(UART_RXD, D, 0);
TOSH_ASSIGN_PIN(UART_TXD, D, 1);

TOSH_ASSIGN_PIN(I2C_CLK, C, 5);
TOSH_ASSIGN_PIN(I2C_DATA, C, 4);

void TOSH_SET_PIN_DIRECTIONS(void){
    outp(0x00, DDRB);
    outp(0x00, DDRC);
    outp(0x00, DDRD);

    TOSH_MAKE_MPW0_OUTPUT();
    TOSH_MAKE_MPW1_OUTPUT();
    TOSH_MAKE_RED_LED_OUTPUT();

    TOSH_MAKE_PW0_OUTPUT();
    TOSH_MAKE_PW1_OUTPUT();

    TOSH_MAKE_MOTOR1PWM_OUTPUT();
    TOSH_MAKE_MOTOR1DIR_OUTPUT();
    TOSH_MAKE_MOTOR2PWM_OUTPUT();
    TOSH_MAKE_MOTOR2DIR_OUTPUT();

}

// avrlibc may define ADC as a 16-bit register read.  This collides
// with the nesc ADC interface name so provide the getADC() function
// instead and undefine ADC
uint16_t inline getADC() {
  return inw(ADC);
}
#undef ADC

enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

#endif //TOSH_MOTOR_HARDWARE_H

