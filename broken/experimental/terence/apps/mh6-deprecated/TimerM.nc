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
	}
}

implementation {
  enum {
    TIMER_HIGHEST_RATE = 12,	// highest clock rate 
    TIMER_MIN_TICKS = 10, 
    TIMER_THRESHOLD = 20
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
  


  /*
    Description of logic for TIMER_Init():
    =======================================
    if (rate) return FAIL // timer already initlized 
    set rate to default value
    if initialize HW timer ok    
    return FAIL
    else 
    return SUCCESS
  ********************************************************************/

  command result_t StdControl.init() {
    if (mClockRate) return FAIL;
    mClockRate=0;
    mState=0;
    mMinTicks=99999999;
    
    call Clock.setRate(TOS_I1PS, TOS_S1PS);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Clock.setRate(TOS_I0PS, TOS_S0PS);
    mClockRate=0;
    mState=0;
    mMinTicks=99999999;
    return SUCCESS;
  }

  // supported clock rates in the powers of 2 so that we can use shift 
  //  clockRate[13]={0,1, 2, 3, 4,5,6,7,8,9,10,11,12};
  // because the value are the same as the array index, I only need to use 
  // one byte to represent clock rate .

  static void initClock(uint8_t setting)
    {
      switch(setting) {
      case 0: call Clock.setRate(TOS_I1PS, TOS_S1PS) ; break;
      case 1: call Clock.setRate(TOS_I2PS, TOS_S2PS) ; break;
      case 2: call Clock.setRate(TOS_I4PS, TOS_S4PS) ; break;
      case 3: call Clock.setRate(TOS_I8PS, TOS_S8PS) ; break;
      case 4: call Clock.setRate(TOS_I16PS, TOS_S16PS) ; break;
      case 5: call Clock.setRate(TOS_I32PS, TOS_S32PS) ; break;
      case 6: call Clock.setRate(TOS_I64PS, TOS_S64PS) ; break;
      case 7: call Clock.setRate(TOS_I128PS, TOS_S128PS) ; break;
      case 8: call Clock.setRate(TOS_I256PS, TOS_S256PS) ; break;
      case 9: call Clock.setRate(TOS_I512PS, TOS_S512PS) ; break;
      case 10: call Clock.setRate(TOS_I1024PS, TOS_S1024PS) ; break;
      }
    }

  /*
    Algorithm to convert time interval in milliseocnds to clock ticks.
    =================================================================
    input:     interval, clockrate 
    algorithm: ticks = clockRate(in ticks/sec)*interval/1000 
    return:    ticks for this rate
  *******************************************************************/
  static inline long convertMStoTicks(long  interval, uint8_t clockRate) {
    return (((interval<<clockRate)+500)/1000);
  }


  /*
    algorithm to adjust clock rate or change clock rate upwards
    ==============================
    input argument : interval in ms
    output argument: ticks under the new clock rate 
    return new clock rate 

    algorithm decription: 
    new_rate = current clockRate +1
    while new_rate <= TIMER_HIGHEST_RATE
    calculate ticks at new_rate 
    if ticks >=TIMER_MIN_TICKS  break 
    else new_rate++
    return new_rate
  ********************************************************************/
  static uint8_t  scaleUp(  long interval, long * ticks) {
    long temp = 0;
    uint8_t new_rate = mClockRate +1;
    while (new_rate<=TIMER_HIGHEST_RATE) {
      temp = convertMStoTicks(interval, new_rate);
      if (temp>=TIMER_MIN_TICKS ) break;
      new_rate++;
    }
    *ticks =  temp ;
    return new_rate;
  }
  /*
    algorithm to adjust clock rate or change clock rate downward
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
    long temp=99999999;
    long state = mState;
    uint8_t i,diff=0, min_timer = 0;
    dbg(DBG_CLOCK, "scale down\n");
    for(i=0; i<NUM_TIMERS; i++)

      //SRM 6/28/02 -- I'm highly skeptical that ticksLeft is the right thing
      //to be comparing against below, though Phil changed it to be this claiming
      //it fixed a bug.
      if ((state&(0x1<<i)) &&(temp>mTimerList[i].ticksLeft)) {
	temp =mTimerList[i].ticksLeft; 
	min_timer=i;
      }
    if (temp==99999999) {
      // no timer left
      mClockRate=0;
      mMinTicks=temp;
      dbg(DBG_CLOCK, "no timer left\n");
    }
    else {
      mMinTicks = temp;
      while (temp>TIMER_THRESHOLD) {
	temp>>=1; diff++;
      }
      mMinTimer=min_timer;
    }
    dbg(DBG_CLOCK, "scaleDown %d levels min ticks=%d id=%d\n", diff, mMinTicks, min_timer);

    return (mClockRate-diff);
  }


  /*
    Algorithm to adjust ticks left for all running timers
    =====================================================
    input argument: new_rate
    return:  none

    Algorithm description: 
    if new_rate is lower
    multiple = new clockRate (tickps)/old clockRate (ticksps);
    for every active timer  
    left shift ticksLeft by "multiple" 
    else
    multiple = old clock rate (ticksps) / new clock rate ( ticksps)
  **********************************************************************/
  static void adjustTicks(char new_rate) 
    {
      short i ; 
      char multiple;

      dbg(DBG_CLOCK, "adjustTicks new rate=%d old rate=%d\n", new_rate, mClockRate);

      if ( new_rate > mClockRate ) {
	multiple = new_rate-mClockRate;
	for (i=0; i<NUM_TIMERS; i++) { 
	  mTimerList[i].ticksLeft<<= multiple;
	  mTimerList[i].ticks<<=multiple;
	}
	mMinTicks<<=multiple;
	dbg(DBG_CLOCK, "multiple=%d min ticks=%d\n", multiple, mMinTicks);
      }
      else {
	multiple = mClockRate- new_rate;	
	for (i=0; i<NUM_TIMERS; i++) {
	  mTimerList[i].ticksLeft>>= multiple;
	  mTimerList[i].ticks>>=multiple;
	}
	mMinTicks>>=multiple;
      }

    }
  
  /*
    Description of logic for TIMER_START(timer_id, ticks, interval):
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
					   uint32_t interval)
    {
      long ticks;  
      uint8_t new_rate=mClockRate;

      //call Leds.redToggle();

      if (id > NUM_TIMERS) return FAIL;
      if (type>1) return FAIL;
      if (mState&(0x1<<id)) return SUCCESS;
      ticks = convertMStoTicks(interval, new_rate);
      if (ticks==0 && new_rate==TIMER_HIGHEST_RATE) return FAIL;
      if (ticks<TIMER_MIN_TICKS && new_rate<TIMER_HIGHEST_RATE ) {
    	new_rate = scaleUp( interval, &ticks);
	dbg(DBG_CLOCK, "scale up to %d\n", new_rate);
	adjustTicks(new_rate);
	// change clock setting
	initClock(new_rate);
	mClockRate=new_rate;
      }
 
      mTimerList[id].ticksLeft= ticks; 
      mTimerList[id].ticks = ticks ;
      mTimerList[id].type = type;
      mState|=(0x1<<id);
      dbg(DBG_CLOCK, "timer %d started rate=%d ticks=%d\n", id, mClockRate, ticks);
      if (ticks <mMinTicks) {
	mMinTicks=ticks;
	mMinTimer=id;
	dbg(DBG_CLOCK,"minTicks=%d id=%d\n", ticks, id);
      }
      return SUCCESS;
    }
  /*
    Description of logic for TIMER_STOP(timer_id)
    =============================================

    if timer_id >=NUM_TIMERS  return FAIL;
    if timer with id=timer_id is running 
    set the state bit representing this timer to 0 
    return SUCCESS
    else
    return FAIL
  ***************************************************************/

  static void stopTimer( uint8_t i) // i is timer id
    {
      uint8_t  new_rate;
      mState -= (0x1<<i);
      dbg(DBG_CLOCK, "stop timer %d\n", i);
      if (i==mMinTimer) // we have just stopped our shortest timer 
	{
	  // scale down clock rate 
	  new_rate = scaleDown();
	  if (new_rate!=mClockRate) {
	    adjustTicks(new_rate);
	    initClock(new_rate);
	  }

	}
    }   

  command result_t Timer.stop[uint8_t id]() {
    if (id>=NUM_TIMERS) return FAIL;
    if (mState&(0x1<<id)) { // if the timer is running 
      stopTimer(id);
      return SUCCESS;
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

    for (i=0;i<NUM_TIMERS;i++) 
      if ((state&(0x1<<i)) && (!(--mTimerList[i].ticksLeft))) {
	// reset the ticksLeft if this is a repeat timer 
	if (mTimerList[i].type==TIMER_REPEAT)
	  mTimerList[i].ticksLeft= mTimerList[i].ticks;
	else // one shot timer 
	  stopTimer(i);
	timerEvent(i);
      }
    return SUCCESS;
  }
}


