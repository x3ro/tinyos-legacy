//$Id: AsyncTimerM.nc,v 1.1 2006/01/16 18:43:17 janflora Exp $

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

module AsyncTimerM
{
  provides interface StdControl;
  provides interface AsyncTimer as Timer[uint8_t timer];
  uses interface HCS08Timer1 as ClockFast;
}
implementation
{
  enum
  {
    NUM_TIMERS = uniqueCount("AsyncTimer"),
  };

  typedef struct
  {
    bool isset;
    bool _reserved; //to get a 4-byte struct
    uint16_t auticks;
  } Timer_t;

  uint16_t m_now;
  Timer_t m_timers[NUM_TIMERS];

  command result_t StdControl.init()
  {
    m_now = 0;
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

  void timerCheck(uint16_t t_now)
  {
    uint8_t i;

    for(i=0; i<NUM_TIMERS; i++)
    {
      Timer_t* tt = m_timers+i;
      if( tt->isset && (tt->auticks == t_now) )
      {
	tt->isset = FALSE;
	signal Timer.fired[i]();
      }
    }

    atomic m_now++;
  }

  task void taskTimerCheck()
  {
    timerCheck(m_now);
  }

  async event void ClockFast.fired()
  {
    uint16_t t_now;
    atomic t_now = m_now;
    //post taskTimerCheck(); //delayed in task context
    timerCheck(t_now); //immediately in interrupt context
  }

  async command result_t Timer.setOneShot[uint8_t timer]( uint16_t auticks )
  {
    atomic {
      m_timers[timer].auticks = m_now + auticks;
      m_timers[timer].isset = TRUE;
    }
    return SUCCESS;
  }

  async command result_t Timer.stop[uint8_t timer]() {
    atomic m_timers[timer].isset = FALSE;
    return SUCCESS;
  }

  async command result_t Timer.setPeriodic[uint8_t timer]( TimerTicks_t millis ) {
    return FAIL;
  }

  async command result_t Timer.start[uint8_t timer]( uint8_t type, TimerTicks_t millis ) {
    if (type == TIMER_ONE_SHOT)
	return call Timer.setOneShot[timer](millis);
    return FAIL;
  }

  command bool Timer.isSet[uint8_t timer]() {
    return m_timers[timer].isset;
  }

  command bool Timer.isPeriodic[uint8_t timer]() {
    return FALSE;
  }

  command bool Timer.isOneShot[uint8_t timer]() {
    return TRUE;
  }

  command TimerTicks_t Timer.getPeriod[uint8_t timer]() {
    return m_timers[timer].auticks;
  }

  default async event result_t Timer.fired[uint8_t timer]()
  {
  }
}

