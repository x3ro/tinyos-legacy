// $Id: TimerM.nc,v 1.1 2005/09/23 12:59:40 palfrey Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 *
 * Authors:             Joe Polastre <polastre@cs.berkeley.edu>
 *                      Rob Szewczyk <szewczyk@cs.berkeley.edu>
 *                      David Gay <dgay@intel-research.net>
 *                      David Moore
 *						Tom Parker <T.E.V.Parker@ewi.tudelft.nl> (TNOde modifications)
 *
 * Revision:            $Id: TimerM.nc,v 1.1 2005/09/23 12:59:40 palfrey Exp $
 */

/**
 * @author Su Ping <sping@intel-research.net>
 */


module TimerM
{
	provides 
	{
		interface Timer[uint8_t id];
		interface StdControl;
	}
	uses
	{
		interface ClockMS;
		interface StdControl as ClockControl;
	}
}

implementation
{
	uint32_t mState;			// each bit represent a timer state 
	uint16_t mInterval;
	int8_t queue_head;
	int8_t queue_tail;
	uint8_t queue_size;
	uint8_t queue[NUM_TIMERS];
#ifndef PLATFORM_PC
	volatile uint16_t interval_outstanding;
#else
	uint16_t interval_outstanding;
#endif
	bool HandleFirePending = FALSE;

	struct timer_s
	{
		uint8_t type;			// one-short or repeat timer
		int32_t ticks;			// clock ticks for a repeat timer 
		int32_t ticksLeft;		// ticks left before the timer expires
	} mTimerList[NUM_TIMERS];

	enum
	{
		maxTimerInterval = 65535U
	};
	command result_t StdControl.init()
	{
		mState = 0;
		queue_head = queue_tail = -1;
		queue_size = 0;
		mInterval = maxTimerInterval;
		return call ClockControl.init();
	}

	command result_t StdControl.start()
	{
		return call ClockControl.start();
	}

	command result_t StdControl.stop()
	{
		mState = 0;
		mInterval = maxTimerInterval;
		call ClockControl.stop();
		return SUCCESS;
	}

	command result_t Timer.start[uint8_t id] (char type, uint32_t interval)
	{
		if (id >= NUM_TIMERS)
			return FAIL;
		if (type > TIMER_ONE_SHOT)
			return FAIL;
		// PAL:
		// The current implementation of TimerM cannot support
		// continuous timers that fire faster than every 3 ticks (3ms).
		// The problem is due to the possibility that the hardware clock
		// could increment while setting the compare value, which would lead
		// to 256 ms until it fires, instead of 1-2.
		if ((type == TIMER_REPEAT) && interval <= 2)
			return FAIL;

		mTimerList[id].ticks = interval;
		mTimerList[id].type = type;

		atomic
		{
			mTimerList[id].ticksLeft = interval+call ClockMS.getSince();
			mState |= (0x1L << id);
			if (mTimerList[id].ticksLeft < mInterval)
			{
				mInterval = interval;
				call ClockMS.BigWait(mInterval);
			}
		}
		dbg(DBG_ERROR,"TimerM: init'ed timer %d set to %d\n",id,interval);
		return SUCCESS;
	}

	static void adjustInterval()
	{
		uint8_t i;
		uint16_t val = maxTimerInterval;
		if (mState)
		{
			for (i = 0; i < NUM_TIMERS; i++)
			{
				if ((mState & (0x1L << i)) && (mTimerList[i].ticksLeft < val))
				{
					val = mTimerList[i].ticksLeft;
				}
			}

			/* DCM: If the interval is set to be less than the current
			 * counter value, the timer will count an extra 256 ticks before
			 * hitting the interrupt.  Thus, we check for this condition
			 * and avoid it. */
			/* PAL: This piece of code sets a maximum interrupt rate
			 * that TimerM will request for continuous timers. TimerM
			 * will never request an interrupt less than 3ms from the
			 * current time; it therefore returns FAIL on continuous
			 * timers with an interval <= 2 (see Timer.start()). */

			atomic
			{
				uint16_t curr = call ClockMS.getSince()+3; // should be equal to the processing time for this last event
				if (val < curr)
				{
					val = curr;
				}
				mInterval = val;
				call ClockMS.BigWait(mInterval);
			}
		}
		else
		{
			atomic
			{
				mInterval = maxTimerInterval;
				call ClockMS.BigWait(mInterval);
			}
		}
	}

	command result_t Timer.stop[uint8_t id] ()
	{
		if (id >= NUM_TIMERS)
			return FAIL;
		if (mState & (0x1L << id))
		{						// if the timer is running 
			atomic mState &= ~(0x1L << id);
			return SUCCESS;
		}
		return FAIL;			//timer not running
	}


	default event result_t Timer.fired[uint8_t id] ()
	{
		return SUCCESS;
	}

	void enqueue(uint8_t value)
	{
		if (queue_tail == NUM_TIMERS - 1)
			queue_tail = -1;
		queue_tail++;
		queue_size++;
		queue[(uint8_t) queue_tail] = value;
	}

	uint8_t dequeue()
	{
		if (queue_size == 0)
			return NUM_TIMERS;
		if (queue_head == NUM_TIMERS - 1)
			queue_head = -1;
		queue_head++;
		queue_size--;
		return queue[(uint8_t) queue_head];
	}

	task void signalOneTimer()
	{
		uint8_t itimer = dequeue();
		if (itimer < NUM_TIMERS)
		{
			dbg(DBG_ERROR,"TimerM: signaled %d\n",itimer);
			signal Timer.fired[itimer] ();
		}
	}


	task void HandleFire()
	{
		uint8_t i;
		uint16_t int_out;
		/* DCM: read the number of ticks elapsed since the last firing
		 * was handled. */
		atomic
		{
			int_out = interval_outstanding;
			interval_outstanding = 0;
		}
		if (mState)
		{
			for (i = 0; i < NUM_TIMERS; i++)
			{
				if (mState & (0x1L << i))
				{
					mTimerList[i].ticksLeft -= (int32_t)int_out;
					if (mTimerList[i].ticksLeft <= 2)
					{
						/* DCM: only update the timer structure if the
						 * signalOneTimer() task was able to be posted. */
						if (post signalOneTimer())
						{
							if (mTimerList[i].type == TIMER_REPEAT)
							{
								mTimerList[i].ticksLeft += mTimerList[i].ticks;
							}
							else
							{	// one shot timer 
								mState &= ~(0x1L << i);
							}
							enqueue(i);
						}
						else
						{
							dbg(DBG_ERROR, "TimerM: Have to wait another timer interval.\n");
							/* DCM: wait another interval in hopes that
							 * the task queue will clear out. */
							mTimerList[i].ticksLeft = 4; // minor skew to help clear the task queue
						}
					}
				}
			}
		}
		/* DCM: don't bother adjusting the interval if another interrupt
		 * is hot on our tail. */
		atomic int_out = interval_outstanding;
		if (int_out == 0)
			adjustInterval();
		atomic HandleFirePending = FALSE;
	}

	event void ClockMS.fire(uint16_t ms)
	{
		atomic
		{
			/* DCM: Once we've posted HandleFire(), don't post it again until
			 * the original one is handled.  This prevents the task queue
			 * from getting flooded when mInterval is small. */
			if (HandleFirePending == FALSE)
			{
				if (post HandleFire())
					HandleFirePending = TRUE;
			}
			else
				dbg(DBG_ERROR, "Don't post handle fire, we're not ready\n");
			/* DCM: Keep track of the interval since the last interrupt */
			interval_outstanding += ms;
		}
	}
}
