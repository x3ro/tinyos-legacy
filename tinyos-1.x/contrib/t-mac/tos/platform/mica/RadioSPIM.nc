/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Author: Wei Ye (S-MAC implementation), Tom Parker (T-MAC Modifications)
 * This module provides the byte-level RadioSPI interface to the mica radio
 */

module RadioSPIM
{
	provides interface RadioSPI;
	uses {
		interface StdControl as PinControl;
		interface SlavePin;
		interface UARTDebug as Debug;
	}
}

implementation
{
#define SAMPLE_TIME 200
#include "TMACEvents.h"

	typedef enum { IDLE=1, SLEEP, TRANSMIT, RECEIVE } RadioState;

	RadioState state;
	
	command result_t RadioSPI.init()
	{
		call PinControl.init();
		cbi(TIMSK, TOIE2); // disable timer 2 overflow interrupt
		state = IDLE;
		call Debug.txStatus(_LL_RADIO_STATE, state);
		return SUCCESS;
	}

	command result_t RadioSPI.sleep()
	{
		if (state == SLEEP) return SUCCESS;
		// stop timer/counter 2
		outp(0x00, TCCR2);
		cbi(TIMSK, OCIE2); // disable timer 2 compare match interrupt
		// turn off SPI
		outp(0x00, SPCR);
		if (state != IDLE) {
			call SlavePin.high(FALSE);
		}
		// set RFM to sleep mode
		TOSH_CLR_RFM_TXD_PIN();
		TOSH_CLR_RFM_CTL0_PIN();
		TOSH_CLR_RFM_CTL1_PIN();
		state = SLEEP;
		call Debug.txStatus(_LL_RADIO_STATE, state);
		return SUCCESS;
	}

	command result_t RadioSPI.send(uint8_t data)
	{
		outp(data,SPDR);
		return SUCCESS;
	}

	command result_t RadioSPI.idle()
	{
		if (state == IDLE) return SUCCESS;
		// stop timer/counter 2
		outp(0x00, TCCR2); // stop SPI clock after tx/rx - important
		cbi(TIMSK, OCIE2); // disable compare match interrupt
		// turn off SPI
		outp(0x00, SPCR);
		if (state == RECEIVE || state == TRANSMIT) {
			call SlavePin.high(FALSE);
		}
		//set RFM to Rx mode
		TOSH_SET_RFM_CTL0_PIN();
		TOSH_SET_RFM_CTL1_PIN();
		TOSH_CLR_RFM_TXD_PIN();
		// clear state variables
		state = IDLE;
		call Debug.txStatus(_LL_RADIO_STATE, state);

		// start timer/counter 2
		outp(0x09, TCCR2); // clear timer on compare match, no prescale
		outp(SAMPLE_TIME, OCR2); // set compare register
		outp(0x00, TCNT2); // clear current counter value
		sbi(TIMSK, OCIE2); // enable compare match interupt
		return SUCCESS;
	}

	command result_t RadioSPI.txMode()
	{
		char temp;
		outp(0x00, TCCR2);  // stop timer
		cbi(TIMSK, OCIE2);  // disable compare match interrupt
		// turn off SPI
		outp(0x00, SPCR);
		if (state != IDLE && state != SLEEP) {
			call SlavePin.high(FALSE);
		}
		state = TRANSMIT;
		call Debug.txStatus(_LL_RADIO_STATE, state);
		
		//set RFM to Tx mode
		TOSH_CLR_RFM_CTL0_PIN();
		TOSH_SET_RFM_CTL1_PIN();
		// start SPI
		temp = inp(SPSR);  // clear possible pending SPI interrupt
		outp(0xc0, SPCR);  // enable SPI and SPI interrupt
		call SlavePin.low();
		//start timer/counter 2 to provide clock to SPI
		outp(0, TCNT2);
		outp(SAMPLE_TIME/2, OCR2);
		sbi(DDRB, 7);   // set PB7 as output to provide clock signal to SPI
		cbi(PORTB, 7);  // set initial clock signal to low
		outp(0x19, TCCR2);  // toggle PB7 (OC2) on compare match
		
		state = TRANSMIT;
		call Debug.txStatus(_LL_RADIO_STATE, state);
		return SUCCESS;
	}
	
	event result_t SlavePin.notifyHigh()
	{
		return SUCCESS;
	}

	TOSH_SIGNAL(SIG_SPI)
	{
		uint8_t data;
		data = inp(SPDR);
		signal RadioSPI.dataReady(data,TRUE);
	}

	inline command uint16_t RadioSPI.getRSSI()
	{
		return 0;
	}
}
