// $Id: hardware.h,v 1.1.1.1 2007/11/05 19:10:11 jpolastre Exp $

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
 * Authors:             Jason Hill, Philip Levis, Nelson Lee, David Gay
 * Version:		$Id: hardware.h,v 1.1.1.1 2007/11/05 19:10:11 jpolastre Exp $
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

#ifndef TOSH_HARDWARE_MICA2DOT
#define TOSH_HARDWARE_MICA2DOT
#endif // tosh hardware

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <avrhardware.h>
#include "CC1000Const.h"
//#include "mydebug.h"
// avrlibc may define ADC as a 16-bit register read.  This collides with the nesc
// ADC interface name
uint16_t inline getADC() {
  return inw(ADC);
}
#undef ADC

#define TOSH_CYCLE_TIME_NS 250

void inline TOSH_wait_250ns() {
      asm volatile  ("nop" ::);
}  

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, A, 2);

// YELLOW_LED and GREEN_LED pins don't exist on mica2dot, but do exist on
// mica2 prerelease which uses the same platform files with mica2dot.
TOSH_ASSIGN_PIN(YELLOW_LED, A, 0); // Doesn't actually exist on mica2dot
TOSH_ASSIGN_PIN(GREEN_LED, A, 1);  // Doesn't actually exist on mica2dot

// battery monitor pins
TOSH_ASSIGN_PIN(BAT_MON, C, 6);
TOSH_ASSIGN_PIN(BAT_MON_REF, C, 7);

// ChipCon control assignments
TOSH_ASSIGN_PIN(CC_CHP_OUT, E, 7); 	// chipcon CHP_OUT
TOSH_ASSIGN_PIN(CC_PDATA, D, 7);  	// chipcon PDATA 
TOSH_ASSIGN_PIN(CC_PCLK, D, 6);		// chipcon PCLK
TOSH_ASSIGN_PIN(CC_PALE, D, 5);		// chipcon PALE

// "GPS" pin
TOSH_ASSIGN_PIN(GPS_ENA, E, 6);

TOSH_ASSIGN_PIN(PWM1B, B, 6);

// Flash assignments
TOSH_ASSIGN_PIN(FLASH_SELECT, E, 5);	// changed for mica2dot
TOSH_ASSIGN_PIN(FLASH_CLK,  A, 3);
TOSH_ASSIGN_PIN(FLASH_OUT,  A, 7);
TOSH_ASSIGN_PIN(FLASH_IN,  A, 6);

// interrupt assignments
TOSH_ASSIGN_PIN(INT0, D, 0);
TOSH_ASSIGN_PIN(INT1, D, 1);
TOSH_ASSIGN_PIN(INT2, D, 2);
TOSH_ASSIGN_PIN(INT3, D, 3);

// spibus assignments 
TOSH_ASSIGN_PIN(MOSI,  B, 2);
TOSH_ASSIGN_PIN(MISO,  B, 3);
TOSH_ASSIGN_PIN(SPI_OC1C, B, 7);
TOSH_ASSIGN_PIN(SPI_SCK,  B, 1);

// power control assignments
TOSH_ASSIGN_PIN(PW0, C, 0);
TOSH_ASSIGN_PIN(PW1, C, 1);
TOSH_ASSIGN_PIN(PW2, C, 2);
TOSH_ASSIGN_PIN(PW3, C, 3);
TOSH_ASSIGN_PIN(PW4, C, 4);
TOSH_ASSIGN_PIN(PW5, C, 5);
TOSH_ASSIGN_PIN(PW6, C, 6);
TOSH_ASSIGN_PIN(PW7, C, 7);

// adc assignments
TOSH_ASSIGN_PIN(ADC2, F, 2);
TOSH_ASSIGN_PIN(ADC3, F, 3);
TOSH_ASSIGN_PIN(ADC4, F, 4);
TOSH_ASSIGN_PIN(ADC5, F, 5);
TOSH_ASSIGN_PIN(ADC6, F, 6);
TOSH_ASSIGN_PIN(ADC7, F, 7);

// i2c bus assignments
TOSH_ALIAS_PIN(I2C_BUS1_SCL, PW0);
TOSH_ALIAS_PIN(I2C_BUS1_SDA, INT1);


// general purpose io assignements
TOSH_ASSIGN_PIN(LITTLE_GUY_RESET, E, 6);

// uart assignments
TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRD);
  outp(0x02, DDRE);
  outp(0x02, PORTE);

  TOSH_MAKE_INT3_INPUT();
  TOSH_MAKE_ADC7_INPUT();
  
  // Only PW0, PW1 are connected, and we leave it to their users
  // to make them outputs
  outp(0x0, DDRC);
  outp(0xff, PORTC);

  TOSH_MAKE_CC_CHP_OUT_INPUT();	// modified for mica2dot
    
  TOSH_MAKE_CC_PALE_OUTPUT();    
  TOSH_MAKE_CC_PDATA_OUTPUT();
  TOSH_MAKE_CC_PCLK_OUTPUT();
  TOSH_MAKE_MISO_INPUT();
  TOSH_MAKE_SPI_OC1C_INPUT();
}

enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

enum 
{
  TOSH_ACTUAL_CC_RSSI_PORT = 0,
  TOSH_ACTUAL_BANDGAP_PORT = 30,
  TOSH_ACTUAL_GND_PORT	   = 31
};

enum 
{
  TOS_ADC_CC_RSSI_PORT = 0,
  TOS_ADC_BANDGAP_PORT = 10,
  TOS_ADC_GND_PORT     = 11
};

/**
 * (Busy) wait <code>usec</code> microseconds
 */
void inline TOSH_uwait(int u_sec)
{
  /* In most cases (constant arg), the test is elided at compile-time */
  if (u_sec)
    /* loop takes 4 cycles, aka 1us */
    asm volatile (
"1:	sbiw	%0,1\n"
"	brne	1b" : "+w" (u_sec));
}

#endif //TOSH_HARDWARE_H
