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

includes TosTime;
includes NewTimer;
module NewTimerM {
	provides interface Timer[uint8_t id];
        provides interface StdControl;
	uses {
		interface Leds;
		interface AbsoluteTimer as AbsoluteTimer1;
                interface Time;
                interface StdControl as TimeControl;
                interface StdControl as ATimerControl;
	}
}

implementation {
  struct tos_time_t nextEventTime; 
  uint32_t nextToFire;  // each bit represent a timer. If a bit is set, 
                        // the correspondent timer fires at next event
  uint32_t mState;	// each bit represent a timer state, 1 is running,
  struct timer_s {
    uint8_t type;	// bit0: one-short or repeat bit2
    unsigned long interval;	// in ms 
    struct tos_time_t intTime;	// timer expiration time
  } mTimerList[NUM_TIMERS];
 

 /*===========================================================
    Command NewTimer.init:
    Initialize module static variables 
    Initialize LogicTime interface
    Return VOID
  ************************************************************/ 

  command result_t StdControl.init() {
    mState =0;
    //nextToFire =0;
    nextEventTime.high32 = 0xFFFFFFFF ;
    nextEventTime.low32  = 0xFFFFFFFF ;
    call ATimerControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (! call Time.running() ) {
        call TimeControl.init();
        call TimeControl.start();
    }
    return SUCCESS ;
  }
 
  command result_t StdControl.stop() {
    mState =0;
    //nextToFire =0;
    nextEventTime.high32 = 0xFFFFFFFF ;
    nextEventTime.low32  = 0xFFFFFFFF ;
    // stop the absolute timer
    call AbsoluteTimer1.stop();
    call ATimerControl.stop();
    return SUCCESS;
  }

  /*
    Description of logic for Timer.start[timer_id](type, interval):
    ===============================================================

    if timer_id > NUM_TIMERS return FAIL
    if type is not TIMER_REPEAT or TIMER_ONE_SHORT return FAIL
    if the timer is running return FAIL
    interruptTime = now + interval(us) ; 
    if interruptTime < nextEventTime; 
        nextEventTime = interruptTime 
	nextToFire = 0x1<<timer_id ;
        start absoluteTimer (nextEventTime);         
    indicate timer n=id is running
    //interrupt Time for this timer = interval + now - nextEventTime 
    set this timer's type to type argument
    return SUCCESS

  **************************************************************/

  command result_t Timer.start[uint8_t id](char type, 
					   uint32_t interval) // in ms
    {
      char retval;
      dbg(DBG_USR1, "Timer.start: id=\%d mstate=\%x\n", id, mState);
      if (id > NUM_TIMERS) return FAIL;
      if (type!=TIMER_REPEAT && type!=TIMER_ONE_SHOT) return FAIL;
      if (mState&(0x1<<id)) return FAIL; // timer in use
      
      mState |=(0x1<<id); // mark this timer as running
      mTimerList[id].intTime = call Time.int64addint32(call Time.get(), interval<<10);
      //dbg(DBG_USR1, "Timer.start: intTime = \%x , \%x\n", mTimerList[id].intTime.high32, mTimerList[id].intTime.low32);

      retval = call Time.int64compare(nextEventTime, mTimerList[id].intTime);
      if (retval==1) {
           //nextToFire = 0x1<<id ;
           nextEventTime.high32 = mTimerList[id].intTime.high32;
           nextEventTime.low32 = mTimerList[id].intTime.low32;
           // tos_time_t format 
           call AbsoluteTimer1.start(mTimerList[id].intTime);
       } else if (retval==0 ) {
           //nextToFire |= (0x1<<id);
       }
       mTimerList[id].type = type;
       mTimerList[id].interval = interval;
       dbg(DBG_USR1, "Timer.start:id=\%d mState= \%x \n", id, mState);
       return SUCCESS;
    }

  /*
    Description of logic for Timer.stop[uint8_t id]()
    =============================================

    if timer_id >=NUM_TIMERS  return FAIL;
    if timer with id=timer_id is running 
       set the state bit representing this timer to 0 
    return the number of ms left in this timer 
    else return FAIL
  ***************************************************************/

  command result_t Timer.stop[uint8_t id]() {
    if (id>=NUM_TIMERS) return FAIL;
    if (mState&(0x1<<id)) { // if the timer is running 
      mState &=~(0x1<<id); // stop the timer
      dbg(DBG_USR1, "Timer.stop: \%d \n", id);
      return SUCCESS ;
    } 
    return FAIL; //timer not running
  }

  // 
  inline void whenToFire (uint8_t i) {
        if ((call Time.int64compare(mTimerList[i].intTime, nextEventTime))==-1)
        {
          nextEventTime.high32 = mTimerList[i].intTime.high32 ;
          nextEventTime.low32 = mTimerList[i].intTime.low32 ;
	}
  }

  default event result_t Timer.fired[uint8_t id]() {
    return SUCCESS;
  }

  /* =======================================================
      timeout event handler. Check each running timer, 
	  if it expires  
	  signal a timer event
          calculate next timer expire event time
          restart absolute Timer to make it fire at next timer event
   ********************************************************/
  void task timeoutHandler() {
    int i;
    struct tos_time_t tt;
    nextEventTime.high32 = 0xFFFFFFFF ; 
    nextEventTime.low32 =  0xFFFFFFFF ;
    dbg(DBG_USR1, "Timer.timeoutHandler: mstate=\%d \n", mState);
    tt = call Time.get();
    for (i=0;i<NUM_TIMERS;i++) {
      if (mState&(0x1<<i)) { // timer running
        if ((call Time.int64compare(mTimerList[i].intTime, tt))==-1) {
          dbg(DBG_USR1, "Timer.timeoutHandler: \%d expired\n", i);
          if (mTimerList[i].type == TIMER_ONE_SHOT) // one shot timer  
          {
            mState &= ~(0x1<<i); // stop it
	  } else { // repeat timer
	     mTimerList[i].intTime = call Time.int64addint32(mTimerList[i].intTime, mTimerList[i].interval<<10);
	     whenToFire(i);
	  }	
	  signal Timer.fired[i]();
	} else {
	    whenToFire(i);
	}
      } // end if (state ...
    } // end for
    if (mState) call AbsoluteTimer1.start(nextEventTime);
    dbg(DBG_USR1, "Timer.timeoutHandler: mstate=\%d\n", mState);
  }

  event result_t AbsoluteTimer1.expired() {
      //dbg(DBG_USR2, "Atimer 1 expired");
      post timeoutHandler();
      return SUCCESS;
  }


}
