//$Id: C55xxTimerM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

includes C55xxTimer;

module C55xxTimerM
{
  provides interface C55xxTimer as TimerA;

  provides interface C55xxTimer as TimerB;

  provides interface C55xxAlarm as Alarm;
}
implementation
{

  typedef C55xxCompareControl_t CC_t;

  uint16_t CC2int( CC_t cc )
  {
    typedef union { CC_t x; uint16_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }

  uint16_t timerControl()
  {
    CC_t x = {
      cm : 1,    // capture on rising edge
      ccis : 0,  // capture/compare input select
      clld : 0,  // TBCL1 loads on write to TBCCR1
      cap : 0,   // compare mode
      ccie : 0,  // capture compare interrupt enable 
    };
    return CC2int(x);
  }

  default async event void TimerA.overflow() { }

  async command uint16_t TimerA.read() { return 0; }
  async command uint16_t TimerB.read() { return 0; }

  async command bool TimerA.isOverflowPending() { return 0; }
  async command bool TimerB.isOverflowPending() { return 0; }

  async command void TimerA.clearOverflow() {  }
  async command void TimerB.clearOverflow() {  }

  default async event void TimerB.overflow() { }


  async command bool Alarm.isInterruptPending() { return 0; };
  async command void Alarm.clearPendingInterrupt() { };

  async command void Alarm.enableEvents() { };
  async command void Alarm.disableEvents() { };
  async command bool Alarm.areEventsEnabled() { return 0; };

  async command uint16_t Alarm.getEvent() { return 0; };
  async command void Alarm.setEvent( uint16_t time ) { };
  async command void Alarm.setEventFromPrev( uint16_t delta ) { };
  async command void Alarm.setEventFromNow( uint16_t delta ) { 
    atomic {
      clock_time = delta;
      clock_event = 1;
    };    
  };

  void c55xx_timer_clock_callback() __attribute__((C))
  {
    DEBUG_puts("c55xx_timer_clock_callback\r\n");
    signal Alarm.fired();
  }

  default async event void Alarm.fired() { };

}

