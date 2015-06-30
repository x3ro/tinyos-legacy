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
 * Date last modified: 3/21/03
 */

// NOTE: This file is included in ClockM.nc when building it for the PC platform.

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
	// use the default values for ATmega103

	uint16_t scaling_limit[7] __attribute__((C)) = { 1, 256, 2047, 8191, 16383, 32767, 65280u };
	uint8_t  scaling_shift[7] __attribute__((C)) = { 0,   0,    3,    5,     6,     7,      8 };
	int8_t   scaling_delta[7] __attribute__((C)) = { 0,   1,    0,    0,     0,     0,      0 };

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

	uint16_t current_jiffies;

	command result_t Clock.setRate(uint8_t interval, uint8_t scale)
	{
		struct rate_s rate = {scale & 0x07, interval};
		current_jiffies = rate2jiffies(rate);

		TOSH_clock_set_rate(interval, scale);
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

	TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE2, ()) 
	{
	    signal Clock.fire();
	}

	command uint32_t LocalTime.read()
	{
		return tos_state.tos_time;
	}

	command uint32_t LocalTime.systemToLocalTime(uint16_t systemTime)
	{
		// do not adjust
		return call LocalTime.read();
	}
}
