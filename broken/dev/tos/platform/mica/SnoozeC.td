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
 * Authors:             Joe Polastre, Rob Szewczyk
 * 
 * $Id: SnoozeC.td,v 1.3 2002/09/05 16:35:18 idgay Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check www.cs.berkeley.edu/~polastre/nest/diode.html
 * That page also has information for how to install the diode.
 */


module SnoozeC
{
  provides interface Snooze;
}

implementation {

#if 0
#define nops(int i) { while(--i) asm volatile ("nop"::); }
#endif

#define nops(x)

  char nintrs; // 0 is default init, currently explicit init is forbidden
  unsigned char port[10];

  command result_t Snooze.snooze(uint16_t length) {
    uint16_t timeout;

    //disable interrupts
    cli();
  
    // save port state
    port[0] = inp(PORTA); nops(8);
    port[1] = inp(PORTB); nops(8);
    port[2] = inp(PORTC); nops(8);
    port[3] = inp(PORTD); nops(8);
    port[4] = inp(PORTE); nops(8);
    port[5] = inp(DDRA);  nops(8);
    port[6] = inp(DDRB);  nops(8);
    port[7] = inp(DDRD);  nops(8);
    port[8] = inp(DDRE);  nops(8);
    port[9] = inp(TCCR0); nops(8);
 
    // Disable TC0 interrupt and set timer/counter0 to be asynchronous from the CPU
    // clock with a second external clock (32,768kHz) driving it.  Prescale to 32 Hz.

    cbi(TIMSK, OCIE0);  nops(8);
    sbi(ASSR, AS0);  	nops(8);
    outp(0x0f, TCCR0);	nops(8);

    timeout = 32 * 4;    //  4 second sleep intervals
    nintrs = 4;     // 4 sleep periods (16s total)

    outp(-(timeout & 0xff), TCNT0); nops(8);
    while(inp(ASSR) & 0x07) nops(8);
    sbi(TIMSK, TOIE0); nops(8);
 
    // set minimum power state
    outp(0x00, DDRA);	// input
    outp(0x00, DDRB);	// input
    outp(0x00, DDRD);	// input
    outp(0x00, DDRE);	// input

    outp(0xff, PORTA);	// pull high
    outp(0xff, PORTB);	// pull high
    outp(0xff, PORTC);	// pull high
    outp(0xff, PORTD);	// pull high

    TOSH_MAKE_RFM_CTL0_OUTPUT();	// port D pin 7
    TOSH_CLR_RFM_CTL0_PIN();		// set low
    TOSH_MAKE_RFM_CTL1_OUTPUT();	// port D pin 6
    TOSH_CLR_RFM_CTL1_PIN();		// set low
    TOSH_MAKE_RFM_TXD_OUTPUT();	        // port B pin 3
    TOSH_CLR_RFM_TXD_PIN();		// set low
  
    TOSH_MAKE_POT_SELECT_OUTPUT();	// port D pin 5	??
    TOSH_SET_POT_SELECT_PIN();	// set low	??
    TOSH_MAKE_POT_POWER_OUTPUT();	// port E pin 7
    TOSH_CLR_POT_POWER_PIN();	// set low
    TOSH_MAKE_FLASH_IN_OUTPUT();	// port A pin 5
    TOSH_CLR_FLASH_IN_PIN();		// set low
    TOSH_MAKE_FLASH_SELECT_OUTPUT();	// port B pin 0
    TOSH_SET_FLASH_SELECT_PIN();	// set high

    TOSH_MAKE_ONE_WIRE_OUTPUT();	// port E pin 5
    TOSH_SET_ONE_WIRE_PIN();		// set high
    TOSH_MAKE_BOOST_ENABLE_OUTPUT();	// port E pin 4
    TOSH_CLR_BOOST_ENABLE_PIN();	// set low

    TOSH_MAKE_PW7_OUTPUT(); TOSH_CLR_PW7_PIN();
    TOSH_MAKE_PW6_OUTPUT(); TOSH_CLR_PW6_PIN();
    TOSH_MAKE_PW5_OUTPUT(); TOSH_CLR_PW5_PIN();
    TOSH_MAKE_PW4_OUTPUT(); TOSH_CLR_PW4_PIN();
    TOSH_MAKE_PW3_OUTPUT(); TOSH_CLR_PW3_PIN();
    TOSH_MAKE_PW2_OUTPUT(); TOSH_CLR_PW2_PIN();
    TOSH_MAKE_PW1_OUTPUT(); TOSH_CLR_PW1_PIN();
    TOSH_MAKE_PW0_OUTPUT(); TOSH_CLR_PW0_PIN();
  
    // enable power save mode
    // next scheduler invokation
    sbi(MCUCR, SM1); nops(8);
    sbi(MCUCR, SM0); nops(8);
    sbi(MCUCR, SE);  nops(8);

    // enable interrupts
    sei(); nops(8);
    return SUCCESS;
  }  

//
// Clock overflow handler
// 
  TOSH_INTERRUPT(SIG_OVERFLOW0) {
    if (nintrs <= 0) {
	cbi(MCUCR,SM0);  nops(8);
	cbi(MCUCR,SM1);  nops(8);
	outp(port[0], PORTA); nops(8);
	outp(port[1], PORTB); nops(8);
	outp(port[2], PORTC); nops(8);
	outp(port[3], PORTD); nops(8);
	outp(port[4], PORTE); nops(8);
	outp(port[5], DDRA);  nops(8);
	outp(port[6], DDRB);  nops(8);
	outp(port[7], DDRD);  nops(8);
	outp(port[8], DDRE);  nops(8);
	outp(port[9], TCCR0); nops(8);
	cbi(TIMSK, TOIE0); nops(8);
	sbi(TIMSK, OCIE0); nops(8);
	outp(0x00, TCNT0); nops(8);
	while(inp(ASSR) & 0x07) { nops(8);};

	TOSH_MAKE_BOOST_ENABLE_OUTPUT();
	TOSH_SET_BOOST_ENABLE_PIN();

	signal Snooze.wakeup();
	return;
    }

    nintrs--;
    outp(0x80, TCNT0);  nops(8);
    while(inp(ASSR) & 0x7){ nops(8);}
    return;
  }
}
