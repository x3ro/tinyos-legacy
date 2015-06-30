// $Id: hardware.h,v 1.1 2006/03/06 10:07:40 palfrey Exp $

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
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * $Id: hardware.h,v 1.1 2006/03/06 10:07:40 palfrey Exp $
 *
 */

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#ifndef TOSH_HARDWARE_TNODE
#define TOSH_HARDWARE_TNODE
#endif // tosh hardware

#define TNODE_4MHZ 4
#define TNODE_8MHZ 8

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <avrhardware.h>
#include <CC1000Const.h>

// avrlibc may define ADC as a 16-bit register read.  This collides with the nesc
// ADC interface name
uint16_t inline getADC() {
  /* now deprecated */
  //return inw(ADC);
  return _SFR_WORD(ADC);
}
#undef ADC

#ifndef TNODE_SPEED
#error must define TNODE_SPEED
#endif

#if TNODE_SPEED==TNODE_8MHZ
#define TOSH_CYCLE_TIME_NS 125
inline void TOSH_wait_250ns() {
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
}

inline void TOSH_uwait(int u_sec)
{
  /* In most cases (constant arg), the test is elided at compile-time */
    while (u_sec > 0) {
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      u_sec--;
    }
}
#elif TNODE_SPEED==TNODE_4MHZ
#define TOSH_CYCLE_TIME_NS 250

void inline TOSH_wait_250ns() {
      asm volatile  ("nop" ::);
}

void inline TOSH_uwait(int u_sec)
{
  /* In most cases (constant arg), the test is elided at compile-time */
  if (u_sec)
    /* loop takes 4 cycles, aka 1us */
    asm volatile (
"1:     sbiw    %0,1\n"
"       brne    1b" : "+w" (u_sec));
}

#else
#error "Can't handle that speed of Tnode"
#endif


// LED assignments
TOSH_ASSIGN_PIN(RED_LED, C, 2);
TOSH_ASSIGN_PIN(GREEN_LED, C, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, C, 0);

TOSH_ASSIGN_PIN(SERIAL_ID, C, 3);
// TOSH_ASSIGN_PIN(BAT_MON, A, 5);
// TOSH_ASSIGN_PIN(THERM_PWR, A, 7);

// ChipCon control assignments
TOSH_ASSIGN_PIN(CC_CHP_OUT, E, 5); // chipcon CHP_OUT (PLL_LOCK)
TOSH_ASSIGN_PIN(CC_PDATA, B, 6);   // chipcon PDATA 
TOSH_ASSIGN_PIN(CC_PCLK, B, 5);	   // chipcon PCLK
TOSH_ASSIGN_PIN(CC_PALE, B, 4);	   // chipcon PALE

// Flash assignments
TOSH_ASSIGN_PIN(FLASH_SELECT, D, 4);
TOSH_ASSIGN_PIN(FLASH_CLK,  D, 5);
TOSH_ASSIGN_PIN(FLASH_OUT,  D, 3);
TOSH_ASSIGN_PIN(FLASH_IN,  D, 2);

// interrupt assignments
// TOSH_ASSIGN_PIN(INT0, D, 0);
// TOSH_ASSIGN_PIN(INT1, D, 1);
// TOSH_ASSIGN_PIN(INT2, D, 2);
// TOSH_ASSIGN_PIN(INT3, D, 3);
TOSH_ASSIGN_PIN(INT4, E, 4);
TOSH_ASSIGN_PIN(INT5, E, 5);
TOSH_ASSIGN_PIN(INT6, E, 6);
TOSH_ASSIGN_PIN(INT7, E, 7);

// spibus assignments 
TOSH_ASSIGN_PIN(SPI_SCK, B, 1);
TOSH_ASSIGN_PIN(MOSI, B, 2);
TOSH_ASSIGN_PIN(MISO, B, 3);
TOSH_ASSIGN_PIN(SPI_OC1C, B, 7);


// power control assignments
// TOSH_ASSIGN_PIN(PW0, C, 0);
// TOSH_ASSIGN_PIN(PW1, C, 1);
// TOSH_ASSIGN_PIN(PW2, C, 2);
// TOSH_ASSIGN_PIN(PW3, C, 3);
// TOSH_ASSIGN_PIN(PW4, C, 4);
// TOSH_ASSIGN_PIN(PW5, C, 5);
// TOSH_ASSIGN_PIN(PW6, C, 6);
// TOSH_ASSIGN_PIN(PW7, C, 7);

// i2c bus assignments
TOSH_ASSIGN_PIN(I2C_BUS1_SCL, D, 0);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, D, 1);

// uart assignments
TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);
TOSH_ASSIGN_PIN(UART_XCK0, B, 1);

TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);
TOSH_ASSIGN_PIN(UART_XCK1, D, 5);

TOSH_ASSIGN_PIN(ADC2, F, 2);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  TOSH_MAKE_CC_CHP_OUT_INPUT();	// modified for mica2 series
    
  // TOSH_MAKE_PW7_OUTPUT();
  // TOSH_MAKE_PW6_OUTPUT();
  // TOSH_MAKE_PW5_OUTPUT();
  // TOSH_MAKE_PW4_OUTPUT();
  // TOSH_MAKE_PW3_OUTPUT(); 
  // TOSH_MAKE_PW2_OUTPUT();
  // TOSH_MAKE_PW1_OUTPUT();
  // TOSH_MAKE_PW0_OUTPUT();

  TOSH_MAKE_CC_PALE_OUTPUT();    
  TOSH_MAKE_CC_PDATA_OUTPUT();
  TOSH_MAKE_CC_PCLK_OUTPUT();
  TOSH_MAKE_MISO_INPUT();
  TOSH_MAKE_SPI_OC1C_INPUT();

  TOSH_MAKE_INT4_INPUT();
  TOSH_MAKE_INT5_INPUT();
  TOSH_MAKE_INT6_INPUT();
  TOSH_MAKE_INT7_INPUT();

  TOSH_MAKE_SERIAL_ID_INPUT();
  TOSH_CLR_SERIAL_ID_PIN();  // Prevent sourcing current
}

enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

enum 
{
  TOSH_ACTUAL_CC_RSSI_PORT = 0,
  TOSH_ACTUAL_VOLTAGE_PORT = 7,
  TOSH_ACTUAL_BANDGAP_PORT = 30,  // 1.23 Fixed bandgap reference
  TOSH_ACTUAL_GND_PORT     = 31   // GND 
};

enum 
{
  TOS_ADC_CC_RSSI_PORT = 0,
  TOS_ADC_VOLTAGE_PORT = 1,
  TOS_ADC_BANDGAP_PORT = 10,
  TOS_ADC_GND_PORT     = 11
};

#endif //TOSH_HARDWARE_H

