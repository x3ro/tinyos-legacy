/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Date last modified: 12/07/03
 */

/**
 * This module provides a 921.6 KHz timer on the MICA2 platform,
 * and 500 KHz timer on the MICA2DOT platform. We use 1/8 prescaling.
 */
module SysTimeM
{
	provides 
	{
		interface StdControl;
		interface SysTime;
	}
}

implementation
{
	// this field holds the high 16 bits of the current time
	uint16_t currentTime;

	union time_u
	{
		struct
		{
			uint16_t low;
			uint16_t high;
		};
		uint32_t full;
	};

	async command uint16_t SysTime.getTime16()
	{
		return __inw_atomic(TCNT3L);
	}

	async command uint32_t SysTime.getTime32()
	{
		register union time_u time;

		atomic
		{
			time.low = __inw(TCNT3L);
			time.high = currentTime;

			// maybe there was a pending interrupt
			if( bit_is_set(ETIFR, TOV3) && ((int16_t)time.low) >= 0 )
				++time.high;
		}

		return time.full;
	}

	async command uint32_t SysTime.castTime16(uint16_t time16)
	{
		uint32_t time = call SysTime.getTime32();
		time += (int16_t)time16 - (int16_t)time;
		return time;
	}

	// Use SIGNAL instead of INTERRUPT to get atomic update of time
	TOSH_SIGNAL(SIG_OVERFLOW3)
	{
		++currentTime;
	}

	command result_t StdControl.init()
	{
		uint8_t etimsk;

		outp(0x00, TCCR3A);
		outp(0x00, TCCR3B);

		atomic
		{
			etimsk = inp(ETIMSK);
			etimsk &= (1<<OCIE1C);
			etimsk |= (1<<TOIE3);
			outp(etimsk, ETIMSK);
		}

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		// start the timer with 1/8 prescaler, 921.6 KHz on MICA2
		outp(0x02, TCCR3B);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		// stop the timer
		outp(0x00, TCCR3B);
		return SUCCESS;
	}
}
