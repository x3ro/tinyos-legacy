// $Id: hardware.h,v 1.3 2003/10/07 21:46:30 idgay Exp $

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

/* Authors:             Jason Hill, Philip Levis, Nelson Lee, David Gay
 *
 *
 */

/**
 * @author Jason Hill
 * @author Philip Levis
 * @author Nelson Lee
 * @author David Gay
 */


#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <avrhardware.h>

// avrlibc may define ADC as a 16-bit register read.  This collides with the nesc
// ADC interface name
uint16_t inline getADC() {
  return inw(ADC);
}
#undef ADC

TOSH_ASSIGN_PIN(RED_LED, A, 2);
TOSH_ASSIGN_PIN(YELLOW_LED, A, 0);
TOSH_ASSIGN_PIN(GREEN_LED, A, 1);

TOSH_ASSIGN_PIN(UD, A, 1);
TOSH_ASSIGN_PIN(INC, A, 2);
TOSH_ASSIGN_PIN(POT_SELECT, D, 5);
TOSH_ASSIGN_PIN(POT_POWER, E, 7);
TOSH_ASSIGN_PIN(BOOST_ENABLE, E, 4);

TOSH_ASSIGN_PIN(FLASH_SELECT,  B, 0);
TOSH_ASSIGN_PIN(FLASH_CLK,  A, 3);
TOSH_ASSIGN_PIN(FLASH_OUT,  A, 7);
TOSH_ASSIGN_PIN(FLASH_IN,  A, 6);

TOSH_ASSIGN_PIN(INT1, D, 1);
TOSH_ASSIGN_PIN(INT2, D, 2);
TOSH_ASSIGN_PIN(INT3, D, 3);

TOSH_ASSIGN_PIN(RFM_RXD,  B, 2);
TOSH_ASSIGN_PIN(RFM_TXD,  B, 3);
TOSH_ASSIGN_PIN(RFM_CTL0, D, 7);
TOSH_ASSIGN_PIN(RFM_CTL1, D, 6);

TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW0, C, 0);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW1, C, 1);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW2, C, 2);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW3, C, 3);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW4, C, 4);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW5, C, 5);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW6, C, 6);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW7, C, 7);

// These are for SOFTWARE based I2C on pins A4 and A5 only
// Hardware based I2C uses different pins.
TOSH_ASSIGN_PIN(I2C_BUS1_SCL, A, 4);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, A, 5);

TOSH_ASSIGN_PIN(LITTLE_GUY_RESET, E, 6);

TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);
TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);

TOSH_ASSIGN_PIN(ONE_WIRE, E, 5);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRD);
  outp(0x02, DDRE);
  outp(0x02, PORTE);
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_POT_SELECT_OUTPUT();
  TOSH_MAKE_POT_POWER_OUTPUT();
    
  TOSH_MAKE_PW7_OUTPUT();
  TOSH_MAKE_PW6_OUTPUT();
  TOSH_MAKE_PW5_OUTPUT();
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT();
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();
  TOSH_MAKE_PW0_OUTPUT();
    
  TOSH_MAKE_RFM_CTL0_OUTPUT();
  TOSH_MAKE_RFM_CTL1_OUTPUT();
  TOSH_MAKE_RFM_TXD_OUTPUT();
  TOSH_SET_POT_POWER_PIN();

  TOSH_MAKE_FLASH_SELECT_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_SET_FLASH_SELECT_PIN();
    
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();


  TOSH_MAKE_BOOST_ENABLE_OUTPUT();
  TOSH_SET_BOOST_ENABLE_PIN();

  TOSH_MAKE_ONE_WIRE_INPUT();
  TOSH_SET_ONE_WIRE_PIN();
}

// define the voltage port here because it's not associated with any sensorboards 
enum 
{ 
  TOSH_ACTUAL_VOLTAGE_PORT = 7 
}; 
enum 
{ 
  TOS_ADC_VOLTAGE_PORT = 7 
}; 

#endif //TOSH_HARDWARE_H
