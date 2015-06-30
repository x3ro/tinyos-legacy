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
		int32_t left;		// the remaning time to fire in jiffies, range = [0,period-1]
		uint32_t period;	// the period of the timer in jiffies
		int8_t next;		// the id of the next timer, range = [-1,TIMER_NUM_TIMERS-1]
		uint8_t state;		// the state of the timer
	} timers[TIMER_NUM_TIMERS];

	int8_t first;			// the id of the first timer, range = [-1,TIMER_NUM_TIMERS-1]
	uint16_t requestedRate;		// the requested clock interrupt rate
	uint16_t clockRate;		// the actual clock rate in jiffies

	enum
	{
		STATE_OFFLIST,
		STATE_STOPPED,
		STATE_REPEAT,
		STATE_ONESHOT,
	};

	/*
	 * The running timers are in a linked list (first, timers[first].next, ...)
	 * A timer is active if it is on the linked list and its period is NOT zero.
	 */

	task void rescanTimers();

	command result_t StdControl.init()
	{
		int8_t i;

		call Clock.setRate2(0);

		first = -1;		// no running timers
		requestedRate = 0;
		clockRate = 0;

		i = TIMER_NUM_TIMERS;
		while( --i >= 0 )
			timers[i].state = STATE_OFFLIST;

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

		requestedRate = 0;
		clockRate = 0;

		return SUCCESS;
	}

	static inline void changeRate(uint16_t rate)
	{
		requestedRate = rate;
		call Clock.setRate2(rate);
		clockRate = call Clock.getRate2();
	}

	command result_t Timer.start2[uint8_t id](uint32_t jiffies)
	{
		if( id < TIMER_NUM_TIMERS && TIMER_RATE_MIN <= jiffies )
		{
			struct timer_s *timer = timers + id;

			atomic
			{
				timer->left = jiffies - 1;
				timer->period = jiffies;

				if( timer->state == STATE_OFFLIST )
				{
					timer->next = first;
					first = id;
				}

				timer->state = STATE_REPEAT;
			}

			if( clockRate == 0 || jiffies < clockRate )
				changeRate(jiffies);

			return SUCCESS;
		}

		return FAIL;
	}

	command result_t Timer.start[uint8_t id](char type, uint32_t interval)
	{
		// change it to jiffies (1/32768 secs)
		uint64_t jiffies = interval;

		jiffies <<= 12;
		jiffies += 63;
		jiffies /= 125;

		if( jiffies <= TIMER_RATE_MAX && call Timer.start2[id](jiffies) == SUCCESS )
		{
			if( type == TIMER_ONE_SHOT )
				timers[id].state = STATE_ONESHOT;

			return SUCCESS;
		}

		return FAIL;
	}

	command result_t Timer.stop[uint8_t id]()
	{
		if( id < TIMER_NUM_TIMERS )
		{
			struct timer_s *timer = timers + id;

			atomic
			{
				if( timer->state != STATE_OFFLIST && timer->state != STATE_STOPPED )
				{
					timer->state = STATE_STOPPED;
					post rescanTimers();
				}
			}

			return SUCCESS;
		}

		return FAIL;
	}

	event result_t Clock.fire()
	{
		int8_t id = first;
		while( id >= 0 )
		{
			struct timer_s *timer = timers + id;

			switch( timer->state )
			{
			case STATE_REPEAT:
				if( (timer->left -= clockRate) < 0 )
				{
					timer->left += timer->period;
					signal Timer.fired[id]();
				}
				break;

			case STATE_ONESHOT:
				if( (timer->left -= clockRate) < 0 )
				{
					timer->state = STATE_STOPPED;
					signal Timer.fired[id]();
					post rescanTimers();
				}
				break;
			}

			id = timer->next;
		}

		return SUCCESS;
	}

	default event result_t Timer.fired[uint8_t id]() 
	{
		return SUCCESS;
	}

	task void rescanTimers()
	{
		uint16_t rate = CLOCK_RATE_MAX;
		int8_t *id = &first;

		// remove non-running timers and calculate lowest period
		while( *id >= 0 )
		{
			struct timer_s *timer = timers + *id;

			atomic
			{
				if( timer->state != STATE_STOPPED )
				{
					if( timer->period < rate )
						rate = timer->period;

					id = &timer->next;
				}
				else
				{
					timer->state = STATE_OFFLIST;
					*id = timer->next;
				}
			}
		}

		// stop if there is no timer left
		if( first < 0 )
			rate = 0;

		// we need to reset the clock rate
		if( rate < clockRate || rate > requestedRate )
			changeRate(rate);
	}
}
