/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 *
 *
 */

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#include <avrhardware.h>

TOSH_ASSIGN_PIN(RED_LED, C, 5);
TOSH_ASSIGN_PIN(YELLOW_LED, C, 3);
TOSH_ASSIGN_PIN(GREEN_LED, C, 4);

TOSH_ASSIGN_PIN(UD, C, 4);
TOSH_ASSIGN_PIN(INC, C, 5);
TOSH_ASSIGN_PIN(POT_SELECT, C, 2);

TOSH_ASSIGN_PIN(RFM_RXD,  D, 2);
TOSH_ASSIGN_PIN(RFM_TXD,  B, 2);
TOSH_ASSIGN_PIN(RFM_CTL0, B, 0);
TOSH_ASSIGN_PIN(RFM_CTL1, B, 1);

TOSH_ASSIGN_PIN(PW1, B, 4);
TOSH_ASSIGN_PIN(PW2, B, 3);
TOSH_ASSIGN_PIN(PW3, D, 5);
TOSH_ASSIGN_PIN(PW4, D, 6);

TOSH_ASSIGN_PIN(I2C_BUS1_SCL, D, 3);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, D, 4);
TOSH_ASSIGN_PIN(I2C_BUS2_SCL, C, 0);
TOSH_ASSIGN_PIN(I2C_BUS2_SDA, C, 1);

TOSH_ASSIGN_PIN(LITTLE_GUY_RESET, D, 7);

TOSH_ASSIGN_PIN(UART_RXD0, D, 0);
TOSH_ASSIGN_PIN(UART_TXD0, D, 1);

#define UCR UCSRB
#define USR UCSRA

void TOSH_SET_PIN_DIRECTIONS(void)
{
  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRC);
  outp(0x00, DDRD);
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_POT_SELECT_OUTPUT();
    
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT();
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();
    
  TOSH_MAKE_RFM_CTL0_OUTPUT();
  TOSH_MAKE_RFM_CTL1_OUTPUT();
  TOSH_MAKE_RFM_TXD_OUTPUT();
    
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();
}

enum
{
	TOSH_ACTUAL_VOLTAGE_PORT = 30
};
enum
{
	TOS_ADC_VOLTAGE_PORT = 7
};

#endif //TOSH_HARDWARE_H
