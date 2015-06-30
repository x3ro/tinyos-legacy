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

module TimerM
{
	provides
	{
		interface StdControl;
		interface Timer[uint8_t id];
	}
	uses
	{
		interface Clock;
	}
}

implementation
{
	struct timer_s
	{
		uint16_t period;	// the period of the timer in jiffies
		uint16_t left;		// the remaning time to fire in jiffies, range = [0,period-1]
		int8_t next;		// the id of the next timer, range = [-1,TIMER_NUM_TIMERS-1]
	} timers[TIMER_NUM_TIMERS];

	int8_t first;			// the id of the first timer, range = [-1,TIMER_NUM_TIMERS-1]
	uint16_t lowest_period;		// the lowest period of all running timers
	uint16_t tick;			// the time of one clock tick in jiffies

	/*
	 * The running timers are in a linked list (first, timers[first].next, ...)
	 * A timer is active if it is on the linked list and its period is NOT zero.
	 */

	task void rescanTimers();

	command result_t StdControl.init()
	{
		int8_t i;

		first = -1;		// no running timers
		lowest_period = 0;
		tick = 0;

		call Clock.setRate2(0);

		i = TIMER_NUM_TIMERS;
		while( --i >= 0 )
			timers[i].period = 0;

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		post rescanTimers();

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		call Clock.setRate2(0);

		lowest_period = 0;
		tick = 0;

		return SUCCESS;
	}

	static inline void changeRate(uint16_t jiffies)
	{
		lowest_period = jiffies;
		call Clock.setRate2(jiffies);
		tick = call Clock.getRate2();
	}

	command result_t Timer.start2[uint8_t id](uint16_t jiffies)
	{
		if( id < TIMER_NUM_TIMERS && TIMER_RATE_MIN <= jiffies )
		{
			timers[id].left = 0;

			if( timers[id].period == 0 )
			{
				timers[id].period = jiffies;
				timers[id].next = first;
				first = id;

				if( jiffies < lowest_period || lowest_period == 0 )
					changeRate(jiffies);
			}
			else
			{
				timers[id].period = jiffies;
				post rescanTimers();
			}

			return SUCCESS;
		}

		return FAIL;
	}

	command result_t Timer.start[uint8_t id](char type, uint32_t interval)
	{
		if( type == TIMER_REPEAT )
		{
			// change it to jiffies (1/32768 secs)
			interval <<= 12;
			interval += 63;
			interval /= 125;

			if( interval <= TIMER_RATE_MAX )
				return call Timer.start2[id](interval);
		}

		return FAIL;
	}

	command result_t Timer.stop[uint8_t id]()
	{
		if( id < TIMER_NUM_TIMERS && timers[id].period != 0 )
		{
			// this shoubd be enough to prevent the timer from firing
			timers[id].left = TIMER_RATE_MAX;
			timers[id].period = 0;
			post rescanTimers();

			return SUCCESS;
		}

		return FAIL;
	}

	event result_t Clock.fire()
	{
		int8_t id = first;
		while( id >= 0 )
		{
			if( timers[id].left < tick )
			{
				timers[id].left += timers[id].period - tick;
				signal Timer.fired[id]();
			}
			else
				timers[id].left -= tick;

			id = timers[id].next;
		}

		return SUCCESS;
	}

	default event result_t Timer.fired[uint8_t id]() 
	{
		return SUCCESS;
	}

	task void rescanTimers()
	{
		uint16_t period = 32768u;
		int8_t *id = &first;

		// remove non-running timers and calculate lowest period
		while( *id >= 0 )
		{
			struct timer_s *timer = &timers[*id];

			if( timer->period != 0 )
			{
				if( timer->period < period )
					period = timer->period;

				id = &timer->next;
			}
			else
				*id = timer->next;
		}

		// stop if there is no timer left
		if( first < 0 )
			period = 0;

		// we need to reset the clock rate
		if( period != lowest_period )
			changeRate(period);
	}
}
