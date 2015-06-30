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

module TestClock1M
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface Clock;
		interface LocalTime;
		interface Leds;
	}
}

implementation
{
	enum
	{
		INTERRUPT_RATE = 200,
		SWITCH_RATE = 32000,
		SWITCH_NUMBER = SWITCH_RATE / INTERRUPT_RATE,
	};

	norace uint16_t switch_counter;
	norace int8_t max_diff;
	norace int8_t min_diff;
	norace uint8_t display;

	command result_t StdControl.init()
	{
		switch_counter = SWITCH_NUMBER;
		max_diff = 0;
		min_diff = 6;
		display = 0;

		return SUCCESS;
	}

	task void test()
	{
		uint32_t time = call LocalTime.read();

		for(;;)
		{
			uint32_t new_time;
			int32_t diff;

			new_time = call LocalTime.read();

			diff = new_time - time;

			if( diff > max_diff )
				max_diff = diff > 7 ? 7 : diff;
			else if( diff < min_diff )
				min_diff = diff < -1 ? -1 : diff;

			time = new_time;

			// wait a little
			for(diff = 0; diff < 5; ++diff)
				inp(SREG);
		}
	}

	command result_t StdControl.start()
	{
		call Clock.setRate2(INTERRUPT_RATE);
		post test();

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call Clock.setRate2(0);
		return SUCCESS;
	}

	async event result_t Clock.fire()
	{
		if( --switch_counter == 0 )
		{
			switch_counter = SWITCH_NUMBER;

			if( display == 0 )
			{
				call Leds.set(min_diff);

				min_diff = 6;
				display = 1;
			}
			else if( display == 1 )
			{
				call Leds.set(max_diff);

				max_diff = 0;
				display = 2;
			}
			else if( display == 2 )
				display = 0;
		}

		return SUCCESS;
	}
}
