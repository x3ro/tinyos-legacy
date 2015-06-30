/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 1/13/03
 */

includes Clock;

module ClockM
{
	provides
	{
		interface Clock;
		interface LocalTime;
	}
}

implementation
{
	uint8_t currentRate;
	volatile uint8_t referencePoint;
	volatile uint32_t currentTime;

	// This implementation does not fully support Clock.setRate
	command result_t Clock.setRate(uint8_t interval, uint8_t scale)
	{
		if( scale <= 1 )
			return call Clock.setRate2(interval);

		return FAIL;
	}

	command result_t Clock.setRate2(uint16_t jiffies)
	{
		uint8_t counter;

		// disable CLOCK interrupt
		cbi(TIMSK, TOIE0);
		cbi(TIMSK, OCIE0);

		if( jiffies < CLOCK_RATE_MIN )
		{
			// stop the timer
			outp(0x00, TCCR0);
			currentRate = 0;

			return SUCCESS;
		}
		else if( jiffies > CLOCK_RATE_MAX )
			currentRate = CLOCK_RATE_MAX;
		else
			currentRate = jiffies;

		// drive the clock asyncronously at 32.768 KHz
		outp(1<<AS0, ASSR);
		outp(0x01, TCCR0);

		// read the counter register
		counter = inp(TCNT0);

		// add the elapsed time
		currentTime += (uint8_t)(counter - referencePoint);

		// set the next reference point
		referencePoint = counter;

		// set the next interrupt point
		outp(counter + currentRate, OCR0);

		// wait till the registers gets updated
		while( (inp(ASSR) & ((1<<OCR0UB)|(1<<TCR0UB))) != 0 )
			;

		// clear pending CLOCK interrupts and enable it
		outp(1<<OCF0, TIFR);
		sbi(TIMSK, OCIE0);

		return SUCCESS;
	}

	command uint16_t Clock.getRate2()
	{
		return currentRate;
	}

	default event result_t Clock.fire()
	{
		return SUCCESS;
	}
	
	/**
	 * Use SIGNAL instead of INTERRUPT to get atomic update of time
	 */
	TOSH_SIGNAL(SIG_OUTPUT_COMPARE0)
	{
		// change the reference point 
		referencePoint = inp(OCR0);

		// set the next interrupt point
		outp(referencePoint + currentRate, OCR0);

		// add the elapsed time
		currentTime += currentRate;

		// enable interrupts
		sei();

		signal Clock.fire();
	}

	command uint32_t LocalTime.read()
	{
		uint8_t elapsed;
		uint32_t time;

		// disable CLOCK interrupts to get atomic read of time
		cbi(TIMSK, OCIE0);

		// get the remaining time
		elapsed = inp(TCNT0) - referencePoint;

		// copy the time,
		time = currentTime;

		// enable CLOCK interrupts
		sbi(TIMSK, OCIE0);

		return time + elapsed;
	}

	command uint32_t LocalTime.systemToLocalTime(uint16_t time)
	{
		uint8_t elapsed, sreg;
		uint16_t systemTime;
		uint32_t clockTime;

		// disable interrupts
		sreg = inp(SREG);
		cli();

		// interrupts are disabled, no need for __inw_atomic
		systemTime = __inw(TCNT1L);

		// get the remaining time
		elapsed = inp(TCNT0) - referencePoint;

		// copy the time,
		clockTime = currentTime;

		// enable interrupts
		outp(sreg, SREG);

		// this is the current time
		clockTime += elapsed;

		// this is the clock time that corresponds to time
		clockTime -= (int16_t)(systemTime - time) / 122;

		return clockTime;
	}
}
