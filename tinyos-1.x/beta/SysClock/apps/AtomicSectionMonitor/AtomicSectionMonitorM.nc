/*
 * Copyright (c) 2004, Vanderbilt University
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
 * Date last modified: 2/23/04
 */

includes AtomicSectionMonitor;
includes Timer;

module AtomicSectionMonitorM
{
	provides interface StdControl;
	uses 
	{
		interface DiagMsg;
		interface Timer;
	}
}

implementation
{
	task void initMonitors()
	{
		uint8_t i;

		for(i = 0; i < ATOMICSECTIONMONITOR_MAXID; ++i)
		{
			struct atomicSectionMonitor *p = atomicSectionMonitors + i;

			atomic
			{
				p->startTime = 0;
				p->maxDuration = 0;
				p->nested = 0;
			}
		}

		startSectionTimer();

		call Timer.start(TIMER_REPEAT, 2000);
	}

	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return post initMonitors();
	}

	command result_t StdControl.stop()
	{
		return call Timer.stop();
	}

	task void reportMonitors()
	{
		if( call DiagMsg.record() )
		{
			uint16_t maxs[ATOMICSECTIONMONITOR_MAXID];
			uint8_t i;

			for(i = 0; i < ATOMICSECTIONMONITOR_MAXID; ++i)
				atomic maxs[i] = atomicSectionMonitors[i].maxDuration;

			call DiagMsg.str("AS");
			call DiagMsg.uint16s(maxs, ATOMICSECTIONMONITOR_MAXID);
			call DiagMsg.send();
		}
	}

	event result_t Timer.fired()
	{
		post reportMonitors();
		return SUCCESS;
	}
}
