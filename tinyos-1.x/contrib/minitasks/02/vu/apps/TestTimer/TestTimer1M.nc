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
 * Date last modified: 11/19/02
 */

includes Timer;

module TestTimer1M
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface StdControl as TimerControl;
		interface Timer as Timer1;
		interface Timer as Timer2;
		interface Leds;
	}
}

implementation
{
	enum
	{
		TIMER1_RATE = 16384,
		TIMER2_RATE = 3,
		TIMER2_BLINK = 16384,
		TIMER2_NUM = TIMER2_BLINK / TIMER2_RATE,
	};

	uint16_t timer2_cnt;

	command result_t StdControl.init()
	{
		call Leds.init();

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		timer2_cnt = TIMER2_NUM;

		call Timer1.start2(TIMER_REPEAT, TIMER1_RATE);
		call Timer2.start2(TIMER_REPEAT, TIMER2_RATE);

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call Timer1.stop();
		call Timer2.stop();

		return SUCCESS;
	}

	event result_t Timer1.fired()
	{
		call Leds.redToggle();
		return SUCCESS;
	}

	event result_t Timer2.fired()
	{
		if( --timer2_cnt == 0 )
		{
			timer2_cnt = TIMER2_NUM;
			call Leds.yellowToggle();
		}

		return SUCCESS;
	}
}
