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

module VerifyClock2M
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface DiagMsg;
		interface StdControl as SubControl;
	}
}

implementation
{
	// only approximate
	void wait(int16_t microseconds)
	{
		while( --microseconds >= 0 )
		{
			int16_t i;

			// one loop is around 4-8 cycles
			for(i = 700; --i >= 0; )
			{
				// prevent the loop to be optimized away
				inp(SREG);
			}
		}
	}

	uint32_t seed;
	#define INITIAL_SEED 93186752;

	// simple linear congruential random number generator
	float rand()
	{
		seed = 784588716*(seed % 2) - 578306215*(seed / 2);
		return (float)(seed ^ __inw(TCNT1L)) / 2147483647.0;
	}

	// wait at most that many microseconds
	void randWait(int16_t microseconds)
	{
		int32_t delay = microseconds;
		delay *= 700;
		delay = (float)delay * rand();

		while( --delay >= 0 )
			inp(SREG);
	}

	void init()
	{
		// disable all TIMER interrupts
		outp(0x00, TIMSK);

		// set the clock to asynchronous
		sbi(ASSR, AS0);

		// set TIMER 0 rate to 32768 Hz
		outp(0x01, TCCR0);

		// set TIMER 1 rate to 1 CPU cycle
		outp(0x00, TCCR1A);
		outp(0x01, TCCR1B);

		// stop TIMER 2
		outp(0x00, TCCR2);

		// wait for the crystal to stabilize
		wait(1000);

		// clear all pending interrupts
		outp(0xff, TIFR);
	}

	struct TimeInterval
	{
		int16_t min;
		int16_t max;
	};

	// calculate the minimum and maximum tick time in CPU cycles
	struct TimeInterval getTimeInterval(uint8_t scaling)
	{
		uint8_t counter;
		int16_t cpu, measurements;
		struct TimeInterval time;

		// reset and set scaling
		init();
		outp(scaling & 0x07, TCCR0);
		wait(500);

		time.min = 32000;
		time.max = -32000;
		measurements = 1000;

		// get alignment
		counter = inp(TCNT0);
		while( counter == inp(TCNT0) )
			;
		
		// get current time
		cpu = __inw(TCNT1L);
		counter = inp(TCNT0);

		while( --measurements > 0 )
		{
			int16_t cpu2, elapsed;

			// wait for the tick
			while( counter == inp(TCNT0) )
				;
		 
			cpu2 = __inw(TCNT1L);
			counter = inp(TCNT0);

			elapsed = cpu2 - cpu;
			cpu = cpu2;

			if( elapsed < time.min )
				time.min = elapsed;
			if( elapsed > time.max )
				time.max = elapsed;
		}

		return time;
	}

/*
RESULTS on ATmega103:
	scaling = 1: min = 119, max = 125
	scaling = 2: min = 973, max = 980
	scaling = 6: min = 31251, max = 31256
*/
	void sendTimeInterval()
	{
		struct TimeInterval i1 = getTimeInterval(1);
		struct TimeInterval i2 = getTimeInterval(2);
		struct TimeInterval i6 = getTimeInterval(6);

		call SubControl.init();
		call SubControl.start();

		call DiagMsg.record();
		call DiagMsg.str("rate");
		call DiagMsg.int16(i1.min);
		call DiagMsg.int16(i1.max);
		call DiagMsg.int16(i2.min);
		call DiagMsg.int16(i2.max);
		call DiagMsg.int16(i6.min);
		call DiagMsg.int16(i6.max);
		call DiagMsg.send();
	}

	struct TimeInterval getAsynchUpdate(uint8_t scaling)
	{
		int16_t cpu, elapsed, measurements;
		struct TimeInterval time;

		// reset and set scaling
		init();
		outp(scaling & 0x07, TCCR0);
		wait(500);

		time.min = 32000;
		time.max = -32000;
		measurements = 1000;

		while( --measurements != 0 )
		{
			randWait(11);

			// get current time
			cpu = __inw(TCNT1L);

			// update one of the registers
			outp(0x00, TCNT0);

			// wait for pending updates
			while( inp(ASSR) != 0x08 )
				;

			// elapsed time
			elapsed = __inw(TCNT1L) - cpu;

			if( elapsed < time.min )
				time.min = elapsed;
			if( elapsed > time.max )
				time.max = elapsed;
		}

		return time;
	}

/*
RESULTS on ATmega103:
	scaling = 1: min = 130, max = 250
	scaling = 2: min = 130, max = 250
	scaling = 6: min = 130, max = 250
*/
	void sendAsynchUpdate()
	{
		struct TimeInterval i1 = getAsynchUpdate(1);
		struct TimeInterval i2 = getAsynchUpdate(2);
		struct TimeInterval i6 = getAsynchUpdate(6);

		call SubControl.init();
		call SubControl.start();

		call DiagMsg.record();
		call DiagMsg.str("update");
		call DiagMsg.int16(i1.min);
		call DiagMsg.int16(i1.max);
		call DiagMsg.int16(i2.min);
		call DiagMsg.int16(i2.max);
		call DiagMsg.int16(i6.min);
		call DiagMsg.int16(i6.max);
		call DiagMsg.send();
	}

	struct TimeInterval getRateChange(uint8_t scaling1, uint8_t scaling2, int8_t ticks)
	{
		int16_t cpu, elapsed, measurements;
		struct TimeInterval time;

		// reset and set scaling
		init();

		// think about it
		++ticks;

		time.min = 32000;
		time.max = -32000;
		measurements = 1000;

		while( --measurements != 0 )
		{
			uint8_t counter;

			// set first scaling
			outp(scaling1 & 0x07, TCCR0);
			wait(2);
			randWait(7);

			// get alignment
			counter = inp(TCNT0);
			while( counter == inp(TCNT0) )
				;

			// get current time
			cpu = __inw(TCNT1L);

			// set the target scaling
			outp(scaling2 & 0x07, TCCR0);

			// set the target counter value
			counter += ticks;

			// wait for the target counter
			while( counter != inp(TCNT0) )
				;

			// elapsed time
			elapsed = __inw(TCNT1L) - cpu;

			if( elapsed < time.min )
				time.min = elapsed;
			if( elapsed > time.max )
				time.max = elapsed;
		}

		return time;
	}

/*
RESULTS on ATmega103:
	first scaling = 1, second scaling = 1, ticks = 1: min = 121, max = 125
	first scaling = 1, second scaling = 1, ticks = 2: min = 241, max = 245
	first scaling = 1, second scaling = 1, ticks = 3: min = 365, max = 369
	first scaling = 1, second scaling = 1, ticks = 4: min = 485, max = 489
	first scaling = 1, second scaling = 2, ticks = 1: min = 121, max = 125
	first scaling = 1, second scaling = 2, ticks = 2: min = 241, max = 245
	first scaling = 1, second scaling = 2, ticks = 3: min = 485, max = 1345
	first scaling = 1, second scaling = 2, ticks = 4: min = 1461, max = 2321
	first scaling = 2, second scaling = 1, ticks = 1: min = 365, max = 369
	first scaling = 2, second scaling = 1, ticks = 2: min = 485, max = 489
	first scaling = 2, second scaling = 1, ticks = 3: min = 609, max = 613
	first scaling = 2, second scaling = 1, ticks = 4: min = 729, max = 733
*/
	void sendRateChange()
	{
		struct TimeInterval i2 = getRateChange(1,1,1);
		struct TimeInterval i3 = getRateChange(1,1,2);
		struct TimeInterval i4 = getRateChange(1,1,3);
		struct TimeInterval i5 = getRateChange(1,1,4);

		call SubControl.init();
		call SubControl.start();

		call DiagMsg.record();
		call DiagMsg.str("change");
		call DiagMsg.int16(i2.min);
		call DiagMsg.int16(i2.max);
		call DiagMsg.int16(i3.min);
		call DiagMsg.int16(i3.max);
		call DiagMsg.int16(i4.min);
		call DiagMsg.int16(i4.max);
		call DiagMsg.int16(i5.min);
		call DiagMsg.int16(i5.max);
		call DiagMsg.send();
	}

	command result_t StdControl.init()
	{
		seed = INITIAL_SEED;

		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		sendRateChange();
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
}
