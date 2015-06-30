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
 * $Id: SnoozeM.nc,v 1.1.1.2 2004/03/06 03:00:48 mturon Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check http://webs.cs.berkeley.edu/tos/hardware/diode_html.html
 * That page also has information for how to install the diode.
 */


/**
 * Implementation of the Snooze component for the Mica platform.
 **/

module SnoozeM
{
  provides interface Snooze;
  // uses interface Chipcon; sudha
  uses interface StdControl as CC1000StdControl;
  uses interface CC1000Control;
}

implementation {

#if 0
#define nops(int i) { while(--i) asm volatile ("nop"::); }
#endif

#define nops(x)

  /**
   * Keep track of the number of 4 second iterations required.
   * 0 is default init, currently explicit init is forbidden.
   **/
  char nintrs; 
  /**
   * Array to store the state of the ports on the microcontroller to be
   * restored upon wakeup.
   **/
  unsigned char port[10];
  unsigned int power_val; // sudha

  /**
   * Triggers the mote to put itself in a low power sleep state for
   * a specified amount of time.
   * 
   * @param length Length of the low power sleep in units of 1/32 of a second.
   * For example, length=32 would snooze for 1 second, length=32*5 would
   * snooze for 5 seconds.  If length=0, the mote will snooze for 4 seconds
   * (this is the default snooze time).
   *
   * @return SUCCESS if the mote is about to enter the sleep state
   **/
  command result_t Snooze.snooze(uint16_t length) {
    uint16_t timeout;

//disable interrupts
    cli();

// put the radio to sleep
//	call Chipcon.off();  sudha

//        power_val = call CC1000Control.GetRFPower();

        // set the PA_POW to 00h to ensure lowest possible leakage current
	call CC1000Control.SetRFPower(0x00); 

        // power down the radio
	call CC1000StdControl.stop();
  
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

    timeout = length & 0x7f;
    nintrs = (length >> 7) & 0x1ff;
    if (timeout == 0) {
	  timeout = 128; 
	  nintrs--;
    }

// calculate the number and length of periods to sleep
    outp(-(timeout & 0xff), TCNT0); nops(8);
    while(inp(ASSR) & 0x07) nops(8);
    sbi(TIMSK, TOIE0); nops(8);
 
// set minimum power state
// NOTE: this enables pull-ups; 
//       -may be sensor board dependant
//       - (ex: Port C should be lo during sleep, not hi?)

	outp(0x00, DDRA);	// input    
	outp(0x01, DDRB);	// input    //leave PB0 as output ( drives 10K ohm -> gnd)
    outp(0x00, DDRC);	// input    
	outp(0x00, DDRD);	// input    
	outp(0x00, DDRE);	// input

    outp(0xff, PORTA);	// enable pull-ups 
	outp(0xfe, PORTB);  // enable pull-ups except for PB0 
    outp(0xff, PORTC);	// enable pull-ups 
	outp(0xff, PORTD);	// enable pull-ups 

    cbi(ADCSRA, ADEN);     //  disable adc
	sbi(ACSR,ACD);         //  disable analog comparator

// if watchdog used, then disable it?
//	cbi(WDTCR, WDE);

// enable power save mode
// next scheduler invokation
    sbi(MCUCR, SM1); nops(8);
    sbi(MCUCR, SM0); nops(8);
    sbi(MCUCR, SE);  nops(8);

// enable interrupts
    sei(); nops(8);
    return SUCCESS;
  }  

  /**
   * Timer/Counter0 overflow handler
   **/
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

//reenable adc/comparators
    sbi(ADCSRA, ADEN);     //  enable adc
	cbi(ACSR,ACD);         //  enable analog comparator

//    call Chipcon.on(); sudha
//    call CC1000Control.SetRFPower(power_val);

    // activates to TxMode from power down mode
    // do we need to call init() before start?
    call CC1000StdControl.start();


	while(inp(ASSR) & 0x07) { nops(8);};

	signal Snooze.wakeup();
	return;
    }

    nintrs--;
    outp(0x80, TCNT0);  nops(8);
    while(inp(ASSR) & 0x7){ nops(8);}
    return;
  }
}
