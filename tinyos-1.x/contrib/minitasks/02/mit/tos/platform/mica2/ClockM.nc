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

#if CLOCK_TYPE == CLOCK_TYPE_NORMAL && defined(__AVR_ATmega103__)

	uint16_t scaling_limit[7] __attribute__((C)) = { 1, 256, 2047, 8191, 16383, 32767, 65280u };
	uint8_t  scaling_shift[7] __attribute__((C)) = { 0,   0,    3,    5,     6,     7,      8 };
	int8_t   scaling_delta[7] __attribute__((C)) = { 0,   1,    0,    0,     0,     0,      0 };

#elif CLOCK_TYPE == CLOCK_TYPE_LOWRES && defined(__AVR_ATmega103__)

	uint16_t scaling_limit[8] __attribute__((C)) = { 0, 0, 255, 1023, 2047, 4095, 8191, 32640u };
	uint8_t  scaling_shift[8] __attribute__((C)) = { 0, 0,   0,    2,    3,    4,    5,      7 };
	int8_t   scaling_delta[8] __attribute__((C)) = { 0, 0,   0,    0,    0,    0,    0,      0 };

#elif CLOCK_TYPE == CLOCK_TYPE_NORMAL && defined(__AVR_ATmega128__)

	uint16_t scaling_limit[7] __attribute__((C)) = { 1, 256, 2055, 8223, 16447, 32895u, 65280u };
	uint8_t  scaling_shift[7] __attribute__((C)) = { 0,   0,    3,    5,     6,      7,      8 };
	int8_t   scaling_delta[7] __attribute__((C)) = { 0,   1,    1,    1,     1,      1,      1 };

#elif CLOCK_TYPE == CLOCK_TYPE_LOWRES && defined(__AVR_ATmega128__)

	uint16_t scaling_limit[8] __attribute__((C)) = { 0, 0, 256, 1027, 2055, 4111, 8223, 32768u };
	uint8_t  scaling_shift[8] __attribute__((C)) = { 0, 0,   0,    2,    3,    4,    5,      7 };
	int8_t   scaling_delta[8] __attribute__((C)) = { 0, 0,   1,    1,    1,    1,    1,      1 };

#endif

	struct rate_s
	{
		uint8_t scale;		// in the range [0,7]
		uint8_t interval;	// must be 0 if scale is 0
	};

	// the rate must be valid
	uint16_t rate2jiffies(struct rate_s rate)
	{
		uint16_t jiffies = rate.interval;
		jiffies += scaling_delta[rate.scale];
		jiffies <<= scaling_shift[rate.scale];

		return jiffies;
	}

	struct rate_s jiffies2rate(uint16_t jiffies)
	{
		struct rate_s rate;

		if( jiffies > CLOCK_RATE_MAX )
			jiffies = CLOCK_RATE_MAX;
		else if( jiffies < CLOCK_RATE_MIN )
			jiffies = 0;

		rate.scale = 0;
		while( jiffies > scaling_limit[rate.scale] )
			++rate.scale;

		jiffies >>= scaling_shift[rate.scale];
		jiffies -= scaling_delta[rate.scale];
		rate.interval = jiffies;

		return rate;
	}

	uint8_t current_scale;
	uint16_t current_jiffies;
	volatile uint32_t current_time;

	command result_t Clock.setRate(uint8_t interval, uint8_t scale)
	{
		struct rate_s rate;
		uint16_t jiffies;
		uint8_t elapsed;

		// calculate the new rates
		rate.scale = scale & 0x07;
		rate.interval = interval;
		jiffies = rate2jiffies(rate);

		// disable CLOCK interrupts
		cbi(TIMSK, TOIE0);
		cbi(TIMSK, OCIE0);

		// drive the clock asyncronously (at 32.768 KHz)
		sbi(ASSR, AS0);

		// update the control registers
		outp(0x08 | rate.scale, TCCR0);
		outp(0, TCNT0);
		outp(interval, OCR0);

		// get the elapsed time, this reads the old content
		elapsed = inp(TCNT0);

		// adjust if CLOCK interrupt is pending
		if( bit_is_set(TIFR, OCF0) )
		{
			current_time += current_jiffies;

			// reread the counter
			elapsed = inp(TCNT0);
		}

		// add scaled elapsed time
		current_time += ((uint16_t)elapsed) << scaling_shift[current_scale];

		// update the rates
		current_scale = rate.scale;
		current_jiffies = jiffies;

		// enable CLOCK interrupts
		sbi(TIMSK, OCIE0);

		return SUCCESS;
	}

	command result_t Clock.setRate2(uint16_t jiffies)
	{
		struct rate_s rate;

		// calculate the rate
		rate = jiffies2rate(jiffies);

		return call Clock.setRate(rate.interval, rate.scale);
	}

	command uint16_t Clock.getRate2()
	{
		return current_jiffies;
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
		current_time += current_jiffies;

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

		// get the elapsed time
		elapsed = inp(TCNT0);

		// copy the time, wait at least 3 CPU cycles
		time = current_time;

		// adjust if CLOCK interrupt is pending
		if( bit_is_set(TIFR, OCF0) )
		{
			time += current_jiffies;

			// reread the counter
			elapsed = inp(TCNT0);
		}

		// enable CLOCK interrupts
		sbi(TIMSK, OCIE0);

		// add scaled elapsed time
		time += ((uint16_t)elapsed) << scaling_shift[current_scale];

		return time;
	}

	command uint32_t LocalTime.systemToLocalTime(uint16_t time)
	{
		uint8_t elapsed, sreg;
		uint16_t systemTime;
		uint32_t clockTime;

		// disable interrupts
		sreg = inp(SREG);
		cli();

		// get the elapsed time
		elapsed = inp(TCNT0);

		// interrupts are disabled, no need for __inw_atomic
		systemTime = __inw(TCNT1L);

		// copy the time, wait at least 3 CPU cycles
		clockTime = current_time;

		// adjust if CLOCK interrupt is pending
		if( bit_is_set(TIFR, OCF0) )
		{
			clockTime += current_jiffies;

			// reread the counters
			elapsed = inp(TCNT0);
			systemTime = __inw(TCNT1L);
		}

		// enable interrupts
		outp(sreg, SREG);

		// add scaled elapsed time, this is the current time
		clockTime += ((uint16_t)elapsed) << scaling_shift[current_scale];

		// get the time corresponding to time
		clockTime -= (uint16_t)(systemTime - time) / 225;

		return clockTime;
	}
}
