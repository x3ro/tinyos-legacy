/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 *
 * This Clock is internally used by T-MAC. User can specify which hardware
 *   Timer/Counter it is based on by defining the macro TMAC_USE_COUNTER_x.
 *   By default Timer/Counter 0 is used.
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */

module ClockMSM
{
	provides
	{
		interface StdControl;
		interface ClockMS as Clock[uint8_t id];
	}
	//uses interface PowerManagement as Power; // not really, but for consistency
}

implementation
{

#include <PhyConst.h>

	uint16_t wait[uniqueCount("ClockMSM")];
	uint16_t since[uniqueCount("ClockMSM")];

	bool inited = FALSE;

	#define MAX_WAIT 0xFF

	uint8_t inc;

	command result_t StdControl.init(){return SUCCESS;}

	command result_t StdControl.start()
	{
		if (!inited)
		{
			atomic 
			{
				memset(wait,0,sizeof(uint16_t)*uniqueCount("ClockMSM"));
				memset(since,0,sizeof(uint16_t)*uniqueCount("ClockMSM"));
				inc = 1;
				TOSH_clock_set_rate(inc-1,3);
			}
		}
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE2,())
	{
		dbg(DBG_CLOCK,"Fired with %d\n",inc);
		atomic
		{
			uint8_t i,newinc=MAX_WAIT;
			for (i=0;i<uniqueCount("ClockMSM");i++)
			{
				since[i]+=inc;
				if (wait[i]!=0)
				{
					wait[i] -= inc;
					if (wait[i]<(uint16_t)newinc)
						newinc = wait[i];
				}
				if (wait[i]==0)
				{
					signal Clock.fire[i](since[i]);
					since[i] = 0;
					newinc = 1;
				}
			}
			if (newinc!=inc)
			{
				inc = newinc;
				TOSH_clock_set_rate(inc-1,3);
			}
		}
	}

	command uint16_t Clock.BigWait[uint8_t id](uint16_t ms)
	{
		volatile uint16_t _time = inp(TCNT0);
		_time += ms;
		atomic 
		{
			wait[id] = _time;
			if (inc>_time)
			{
				inc = _time;
				outp(inc-1,OCR0);
			}
		}
		return ms;
	}

	command uint16_t Clock.getSince[uint8_t id]()
	{
		return since[id]+inp(TCNT0);
	}

	default event void Clock.fire[uint8_t id](uint16_t ms) {}
}
