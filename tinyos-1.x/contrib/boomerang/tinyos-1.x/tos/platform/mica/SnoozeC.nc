// $Id: SnoozeC.nc,v 1.1.1.1 2007/11/05 19:10:08 jpolastre Exp $

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
/*
 *
 * Authors:             Joe Polastre, Rob Szewczyk
 * 
 * $Id: SnoozeC.nc,v 1.1.1.1 2007/11/05 19:10:08 jpolastre Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check http://webs.cs.berkeley.edu/tos/hardware/diode_html.html
 * That page also has information for how to install the diode.
 */


/**
 * Implementation of the Snooze component for the Mica platform.
 * @author Joe Polastre
 * @author Rob Szewczyk
 **/
module SnoozeC
{
  provides interface Snooze;
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
  norace char nintrs; 
  /**
   * Array to store the state of the ports on the microcontroller to be
   * restored upon wakeup.
   **/
  unsigned char port[10];

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
  async command result_t Snooze.snooze(uint16_t length) {
    uint16_t timeout;

    //disable interrupts
    atomic {
  
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
      TOSH_SET_POT_SELECT_PIN();		// set low	??
      TOSH_MAKE_POT_POWER_OUTPUT();	// port E pin 7
      TOSH_CLR_POT_POWER_PIN();		// set low
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
    }; nops(8);
    return SUCCESS;
  }  

  /**
   * Timer/Counter0 overflow handler
   **/
  TOSH_INTERRUPT(SIG_OVERFLOW0) {
    if (nintrs <= 0) {
      cbi(MCUCR,SM0);  nops(8);
      cbi(MCUCR,SM1);  nops(8);
      atomic {
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
      }
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
