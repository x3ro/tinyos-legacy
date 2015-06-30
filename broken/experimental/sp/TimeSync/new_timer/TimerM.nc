/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Su Ping  (converted to nesC by Sam Madden)
 *           David Gay
 *           Intel Research Berkeley Lab
 * Date:     4/12/2002
 * NesC conversion: 6/28/2002
 * interface cleanup: 7/16/2002
 *
 */


module TimerM {
	provides interface Timer[uint8_t id];
	provides interface StdControl;
	uses {
		interface Leds;
		interface Clock;
                interface LogicTime;
	}
}

implementation {
  enum {
    TIMER_HIGHEST_RATE = 12,	// highest clock rate 
    TIMER_MIN_TICKS = 10, 
    TIMER_THRESHOLD = 20,
    NUM_TIMERS = 12,
  };

  uint8_t mClockRate;		// current clock setting. see notes below for detail 
  uint8_t mMinTimer;		// the index of the shortest timer
  long mMinTicks;		// shortest timer interval in ticks
  uint32_t mState;		// each bit represent a timer state, 1 for running, 0 for stopped 
  struct timer_s {
    uint8_t type;		// one-short or repeat
    long ticks;			// 0 for repeat timer,  clock ticks for a repeat timer 
    long ticksLeft;		// ticks left before the timer expires
  } mTimerList[NUM_TIMERS];
  

  command result_t StdControl.init() {
    mState=0;
	mMinTimer=0;
	mMinTicks=0xffffffff;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    mState=0;
	mMinTimer=0;
	mMinTicks=0xffffffff;
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    call Clock.init(TOS_CLOCK_STOP);
    return SUCCESS;
  }

  /*
    convert time interval in milliseocnds to clock ticks at 32768 ticks per seconds.
    =================================================================
    input:     interval, clockrate 
    algorithm: ticks = clockRate(in ticks/sec)*interval/1000 
    return:    ticks for this rate
  *******************************************************************/
  static inline long msToTicks(long  interval) {
    return (((interval<<TOS_FAST_CLOCK)+500)/1000);
  }

  static inline long ticksToMs( long ticks ) {
	return (ticks >>5 );
  }


  /*
    algorithm to adjust clock rate or change clock rate upwards (faster)
    ==============================
    input argument : ticks
    return new clock rate 
  */
  static uint8_t  scaleUp(  long ticks) {
    long temp = 0;
    uint8_t new_rate = mClockRate +1;
    while ((ticks >>(TOS_FAST_CLOCK -new_rate)) < 0 ) {
      new_rate++;
    }
    return new_rate;
  }

  /*
     change clock rate downward (slower)
    ============================================================
    return new clock rate 
    algorithm decription: 
    find the minimum timer ticks 
    save its value and index 
    calculate the number of levels we need to scale down 
    ( thresthold set at 20 ticks )
    return new_rate 
  ********************************************************************/
  static uint8_t  scaleDown() {
    long temp=0xffffffff;
    long state = mState;
	char new_rate;
    uint8_t i,diff=0, min_timer = 0;
    dbg(DBG_CLOCK, "scale down\n");

    for(i=0; i<NUM_TIMERS; i++) {
      if ((state&(0x1<<i)) &&(temp>mTimerList[i].ticksLeft)) {
			temp =mTimerList[i].ticksLeft; 
			min_timer=i;
      }
	}
    if (temp==0xffffffff) {
      // no timer left
      new_rate =TOS_1s_CLOCK;
      mMinTicks=temp;
      dbg(DBG_CLOCK, "no timer left\n");
    }
    else {
      mMinTicks = temp;
      mMinTimer=min_timer;
      // calculate new clock rate
	  for (i=0; i++; i<12 )
	     if ((mMinTicks >> (3 + mClockRate +i ))>=0 ) break;
	  new_rate = mClockRate -i;
    }
    dbg(DBG_CLOCK, "scaleDown %d levels min ticks=%d id=%d\n", diff, mMinTicks, min_timer);

    return new_rate;
  }


    // start an absolute timer, exprired at "time" represented by ticks
    // for now. It should be seconds since xxxx
    command result_t Timer.startAbsolute[uint8_t id](uint32_t time) 
    {
      long ticks;   
      char rate;
      if (call Clock.getRate()==TOS_CLOCK_STOP)   {
         call Clock.init(TOS_1s_CLOCK);
      }
      mTimerList[id].ticksLeft= time - call LogicTime.currentTime() ; 
      // mTimerList[id].ticks = time ; don't care
      mTimerList[id].type = TIMER_ABSOLUTE;
      mState|=(0x1<<id);
      return SUCCESS ;
    }
  
  /*
    Description of logic for Timer.start(timer_id, ticks, interval):
    ===============================================================

    if timer_id > 31 return FAIL
    if type is not 0 or 1 return FAIL
    if the timer is running return SUCCESS

    convert interval to clock ticks 
    if ticks < TIMER_MIN_TICKS 
    change rate (output: new_rate, ticks)
    adjust ticksLeft for all running timers
    set rate = new_rate // can not do this before adjust ticksLeft
  
    set ticksLeft for this timer to ticks
    set this timer's runing bit to 1
    set this timer's.type bit to type argument
    return SUCCESS
  **************************************************************/
  command result_t Timer.start[uint8_t id](char type, 
					   uint32_t interval) // in ms
    {
      long ticks, ticksLeft;  
      char i, rate,  new_rate;

      if (id > NUM_TIMERS) return FAIL;
      if (type>TIMER_ABSOLUTE|!interval) return FAIL;
      if (mState&(0x1<<id)) return FAIL; // timer in use
	  ticks = msToTicks(interval);
	  ticksLeft = ticks; // + current time in timer0 register ; 
	  if (ticksLeft < mMinTicks) {
	      mMinTicks = ticksLeft;
	      mMinTimer = id;
	  }
	  mTimerList[id].ticksLeft= ticksLeft ;
      mTimerList[id].ticks = ticks ;
      mTimerList[id].type = type;
      mState|=(0x1<<id);
      rate = call Clock.getRate();
	  if (rate == TOS_CLOCK_STOP) {
	      i=0;
	      while (ticks >> (3+i) ) i++;
		  rate = TIMER_HIGHEST_RATE -i;
		  call Clock.init(rate);
          
	  } 
	  if ((ticksLeft >>(TOS_FAST_CLOCK-rate))<0)  {
		// need to adjust the clock rate 
    	  new_rate = scaleUp( ticks);	
	    // change clock setting
		call Clock.init(new_rate);
		mClockRate=new_rate;
      }

      return SUCCESS;
    }

    static void stopTimer( uint8_t i) // i is timer id
    {
      char new_rate;
      mState -= (0x1<<i);
      dbg(DBG_CLOCK, "stop timer %d\n", i);
      if (i==mMinTimer) // we have just stopped our shortest timer 
	  {
	    // scale down clock rate 
	    new_rate = scaleDown( );
	    if (new_rate!=mClockRate) {
	      call Clock.init(new_rate);
	    }
	  }
    }   
  /*
    Description of logic for Timer.stop[uint8_t id]()
    =============================================

    if timer_id >=NUM_TIMERS  return FAIL;
    if timer with id=timer_id is running 
    set the state bit representing this timer to 0 
    return the number of ms left in this timer if success
    else return FAIL
  ***************************************************************/

  command uint32_t Timer.stop[uint8_t id]() {
    if (id>=NUM_TIMERS) return FAIL;
    if (mState&(0x1<<id)) { // if the timer is running 
      stopTimer(id); // stop the timer

      return ticksToMs(mTimerList[id].ticksLeft) ;
    } 
    return FAIL; //timer not running
  }


  static void timerEvent(uint8_t id) 
    {
      //call Leds.greenToggle();
      signal Timer.fired[id]();
    }

  default event result_t Timer.fired[uint8_t id]() {
    return SUCCESS;
  }

  /*
    Description of logic for Clock Interrup handler 
    ===============================================
    loop  from i=0 to NUM_TIMERS
    if timer i is running and ticksLeft[i] is non-zero
    decrement ticksLeft by 1 
    if timer i expires now       
    call user timer event handler 
    if the timer is one-shot timer   
    stop the timer 
    else reset ticketLeft 
  **************************************************************/
  event result_t Clock.fire() {
    uint8_t i=0; 
    uint32_t state = mState;

    for (i=0;i<NUM_TIMERS;i++) {
      if (state&(0x1<<i)) { // if the timer is running
	    mTimerList[i].ticksLeft -= 1<<mClockRate ;
	    if (mTimerList[i].ticksLeft <=0) {
			// reset the ticksLeft if this is a repeat timer 
			if (mTimerList[i].type==TIMER_REPEAT)
				mTimerList[i].ticksLeft= mTimerList[i].ticks;
			else // one shot timer {
				stopTimer(i);
			timerEvent(i);
		}
      }
	}
    return SUCCESS;
  }
}
