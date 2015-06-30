//$Id: TimerM.nc,v 1.1 2006/01/16 18:43:17 janflora Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>
// @author Jan Flora <janflora@diku.dk>

includes Timer;

module TimerM
{
	provides
	{
		interface StdControl;
		interface Timer[uint8_t timer];
	}
	uses
	{
		interface HCS08Timer1 as ClockSlow;
	}
}
implementation
{	
	enum {
		NUM_TIMERS = uniqueCount("Timer"),
	};

	typedef struct {
		bool isset;
		bool isperiodic;
		TimerTicks_t millis;
	} Timer_t;

	// Keep m_period separate from m_timers so that Timer_t can be 4 bytes.
	// If TimerTicks_t ever becomes 32-bits, we can roll everything back into
	// Timer_t for an 8-byte structure.  Good times.
	Timer_t m_timers[NUM_TIMERS];
	TimerTicks_t m_period[NUM_TIMERS];
	TimerTicks_t m_now;

	bool timerCheckPosted = FALSE;

	command result_t StdControl.init()
	{
		atomic m_now = 0;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	void timerCheck()
	{
		uint8_t i;
		TimerTicks_t timeNow;

		atomic timeNow = m_now;
		for(i=0; i<NUM_TIMERS; i++) {
			Timer_t* tt = m_timers+i;
			if( tt->isset && (tt->millis <= timeNow) ) {
				if( tt->isperiodic ) {
					tt->millis = timeNow + m_period[i];
				} else {
					tt->isset = FALSE;
				}
				signal Timer.fired[i]();
			}
		}
	}

	task void taskTimerCheck()
	{
		timerCheck();
		atomic timerCheckPosted = FALSE;
	}

	async event void ClockSlow.fired()
	{
		atomic {
			m_now++;
		  	if (!timerCheckPosted) {
				timerCheckPosted = post taskTimerCheck(); //delayed in task context
			}
		}
	}

	command result_t Timer.setOneShot[uint8_t timer]( TimerTicks_t millis )
	{
		atomic m_timers[timer].millis = m_now + millis;
		m_timers[timer].isset = TRUE;
		m_timers[timer].isperiodic = FALSE;
		return SUCCESS;
	}

	command result_t Timer.setPeriodic[uint8_t timer]( TimerTicks_t millis )
	{
		// tell me if this is wrong, but we'd rather have the first event of a
		// Periodic timer to happen asap, not in millis seconds.
		atomic m_timers[timer].millis = m_now + 1;
		m_timers[timer].isset = TRUE;
		m_timers[timer].isperiodic = TRUE;
		m_period[timer] = millis;
		return SUCCESS;
	}

	command result_t Timer.stop[uint8_t timer]()
	{
		m_timers[timer].isset = FALSE;
		return SUCCESS;
	}

	command bool Timer.isSet[uint8_t timer]()
	{
		return m_timers[timer].isset;
	}

	command bool Timer.isPeriodic[uint8_t timer]()
	{
		return m_timers[timer].isperiodic;
	}

	command bool Timer.isOneShot[uint8_t timer]()
	{
		return !m_timers[timer].isperiodic;
	}

	command TimerTicks_t Timer.getPeriod[uint8_t timer]()
	{
		return m_period[timer];
	}

	command result_t Timer.start[uint8_t timer]( uint8_t type, TimerTicks_t millis )
	{
		switch( type ) {
			case TIMER_REPEAT:
				return call Timer.setPeriodic[timer]( millis );
			case TIMER_ONE_SHOT:
				return call Timer.setOneShot[timer]( millis );
		}
		return FAIL;
	}

	default event result_t Timer.fired[uint8_t timer]()
	{
		dbg("Timer %d fired but not connected",timer);
		return SUCCESS;
	}
}
