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

module NewTimerM {
	provides interface Timer[uint8_t id];
	uses {
		interface Leds;
		interface AbsoluteTimer;
                interface LogicTime;
	}
}

implementation {
  uint32_t nextEventTime; 
  uint32_t nextTofire;  // each bit represent a timer. If a bit is set, 
                        // the correspondent timer fires at next event
  uint32_t mState;	// each bit represent a timer state, 1 is running,
  struct timer_s {
    uint8_t type;	// bit0: one-short or repeat bit2
    unsigned long interval;	// in ms 
    unsigned long intTime;	// time left before the timer expires
  } mTimerList[NUM_TIMERS];
 
 /*===========================================================
    Command NewTimer.init:
    Initialize module static variables 
    Initialize LogicTime interface
    Return VOID
  ************************************************************/ 

 command void NewTimer.init() {
    mState =0;
    nextToFire =0;
    nextEventTime = 0xFFFFFFFF ;
    LogicTime.init();
 }

  /*
    Description of logic for NewTimer.start(timer_id, ticks, interval):
    ===============================================================

    if timer_id > NUM_TIMERS return FAIL
    if type is not TIMER_REPEAT or TIMER_ONE_SHORT return FAIL
    if the timer is running return FAIL
    interruptTime = now + interval ; // if interrupt time < now
	                                 // logicTtime wrapped around
    if interruptTime < nextEventTime; 
    {
        
        nextEventTime = interruptTime 
		nextToFire = 0x1<<timer_id ;
        call absoluteTimer.start(nextEventTime);         
    } 
	else nextToFire |= (0x1<<timer_id) ;
    indicate timer n=id is running
	intTime for this timer = interval + now - nextEventTime 
    set this timer's type to type argument
    return SUCCESS

	// bug: when logic time wrap around
  **************************************************************/

  command result_t NewTimer.start[uint8_t id](char type, 
					   uint32_t interval) // in ms
    {
      unsigned long interruptTime;
      
      if (id > NUM_TIMERS) return FAIL;
      if (type!=TIMER_REPEAT && type!=TIMER_ONE_SHOT) return FAIL;
      if (mState&(0x1<<id)) return FAIL; // timer in use
      mstate !=(0x1<<id);
      interruptTime = interval + call LogicTime.get(); 
      if (interruptTime< nextEventTime) {
           nextToFire = 0x1<<timer_id ;
           nextEventTime = interruptTime;
           call absoluteTimer.start(nextEventTime);
       } else  {
	       nextToFire |= (0x1<<timer_id) ;
	}
        mstate !=(0x1<<id);
	mTimerList[id].type = type;
	mTimerList[id].intTime = interruptTime;
        return SUCCESS;
    }

  /*
    Description of logic for NewTimer.stop[uint8_t id]()
    =============================================

    if timer_id >=NUM_TIMERS  return FAIL;
    if timer with id=timer_id is running 
       set the state bit representing this timer to 0 
    return the number of ms left in this timer 
    else return FAIL
  ***************************************************************/

  command uint32_t NewTimer.stop[uint8_t id]() {
    uint32_t timer
    if (id>=NUM_TIMERS) return FAIL;
    if (mState&(0x1<<id)) { // if the timer is running 
      mState -= (0x1<<i); // stop the timer
      return (mTimerList[id].intTime - call LogicTime.get()) ;
    } 
    return FAIL; //timer not running
  }


  static void inline whenTofire (uint8_t i) {
	if (mTimerList[i].intTime<nextEventTime) {
		nextToFire = 0x1<<i; nextEventTime = mTimerList[i].intTime ;
	} else if (mTimerList[i].intTime==nextEventTime) {
		nextToFire|=(0x1<<i);
	}
  }

  default event result_t NewTimer.fired[uint8_t id]() {
    return SUCCESS;
  }

  /* =======================================================
      event handler. Check each running running timer, 
	  if it is running and next to EXPIRE bit is on
	  signal a timer event
   ********************************************************/
  event AbsoluteTimer.expired() {
    nextEventTime = 0xFFFFFFFF ; 
    for (i=0;i<NUM_TIMERS;i++) {
      if (state&(0x1<<i) {
        if  (nextToFire &(0x1<<i)) {
          if (type = TIMER_ONE_SHOT) // one shot timer 
            mState -= (0x1<<i); // stop it
	  else { // repeat timer
		mTimerList[i].intTime= += mTimerList[i].interval;
		whenToFire(i);
	  }	
	  signal NewTimer.fired[id]();
	  }	else {
	    whenTofire( i);
	  }
	} 
      }
    }
    if (nextToFire) AbsoluteTimer.start(nextEventTime);
    return SUCCESS;
  }

}
