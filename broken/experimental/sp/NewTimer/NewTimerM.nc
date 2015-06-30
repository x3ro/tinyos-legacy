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
includes TosTime;
includes Timer;
module NewTimerM {
    provides interface Timer[uint8_t id];
    provides interface StdControl;
    uses {
	interface Leds;
	interface AbsoluteTimer as AbsoluteTimer1;
        interface Time;
	interface TimeUtil;
        interface StdControl as TimeControl;
        interface StdControl as ATimerControl;
    }
}

implementation {
    tos_time_t nextEventTime; 
    uint32_t nextToFire;  // each bit represent a timer. If a bit is set, 
                          // the correspondent timer fires at next event
    uint32_t mState;	  // each bit represent a timer state, 1 is running,
    struct timer_s {
    	uint8_t type;	  // bit0: one-short or repeat bit2
    	unsigned long interval;	// in ms 
    	tos_time_t intTime;	// timer expiration time
    } mTimerList[NUM_TIMERS];
 

 /*===========================================================
    Command NewTimer.init:
    Initialize module static variables 
    Initialize LogicTime interface
    Return VOID
  ************************************************************/ 

    command result_t StdControl.init() {
      	bool retval;
      	mState =0;
      	//nextToFire =0;
      	nextEventTime.high32 = 0xFFFFFFFF ;
      	nextEventTime.low32  = 0xFFFFFFFF ;
      	retval = call ATimerControl.init();
      	if (!retval) call Leds.redToggle();
    	return SUCCESS;
    }

    command result_t StdControl.start() {
	bool retval;
	retval=call ATimerControl.start();
	if (!retval) call Leds.redToggle();
	return SUCCESS ;
    }
 
    command result_t StdControl.stop() {
	bool temp;
	temp = TOSH_interrupt_disable();
	mState =0;
	nextEventTime.high32 = 0xFFFFFFFF ;
	nextEventTime.low32  = 0xFFFFFFFF ;
	if(temp) TOSH_interrupt_enable();
	// stop the absolute timer
	call AbsoluteTimer1.cancel();
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

    command result_t Timer.start[uint8_t id](char type, uint32_t interval) { 
      	char retval;
	bool temp;
 	tos_time_t tt;
      	dbg(DBG_USR1, "Timer.start: id=\%d mstate=\%x\n", id, mState);
      	if (id > NUM_TIMERS) return FAIL;
      	if (type!=TIMER_REPEAT && type!=TIMER_ONE_SHOT) return FAIL;
      	if (mState&(0x1<<id)) return FAIL; // timer in use
	tt = call TimeUtil.addUint32(call Time.get(), interval<<10);
        
      	temp = TOSH_interrupt_disable();
      	mState |=(0x1<<id); // mark this timer as running
        mTimerList[id].intTime = tt;
        //dbg(DBG_USR1, "Timer.start: intTime = \%x , \%x\n", mTimerList[id].intTime.high32, mTimerList[id].intTime.low32);
        retval = call TimeUtil.compare(nextEventTime, tt);
        if (temp) TOSH_interrupt_enable();
        if (retval==1) {
            temp = TOSH_interrupt_disable();
            nextEventTime.high32 = mTimerList[id].intTime.high32;
            nextEventTime.low32 = mTimerList[id].intTime.low32;
	    if (temp) TOSH_interrupt_enable();
            call AbsoluteTimer1.set(mTimerList[id].intTime);
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
        bool temp;
    	if (id>=NUM_TIMERS) return FAIL;
	temp = TOSH_interrupt_disable();
      	mState &=~(0x1<<id); // stop the timer
        if (temp) TOSH_interrupt_enable();
    	return SUCCESS;
    }


    inline void whenToFire (uint8_t i) {
        if ((call TimeUtil.compare(mTimerList[i].intTime, nextEventTime))==-1)
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
	bool temp;
    	tos_time_t tt;
        temp = TOSH_interrupt_disable();
    	nextEventTime.high32 = 0xFFFFFFFF ; 
    	nextEventTime.low32 =  0xFFFFFFFF ;
        if(temp) TOSH_interrupt_enable();
    	dbg(DBG_USR1, "Timer.timeoutHandler: mstate=\%d \n", mState);
    	tt = call Time.get();
    	for (i=0;i<NUM_TIMERS;i++) {
      	    if (mState&(0x1<<i)) { // timer running
                if ((call TimeUtil.compare(mTimerList[i].intTime, tt))==-1) {
            	    dbg(DBG_USR1, "Timer.timeoutHandler: \%d expired\n", i);
            	    if (mTimerList[i].type == TIMER_ONE_SHOT)  {
            		mState &= ~(0x1<<i); // stop it
	    	    } else { // repeat timer
                        temp = TOSH_interrupt_disable();
	                mTimerList[i].intTime = call TimeUtil.addUint32(mTimerList[i].intTime, mTimerList[i].interval<<10);
	                whenToFire(i);
                        if(temp) TOSH_interrupt_enable();
	            }	
	            signal Timer.fired[i]();
	        } else {
                    temp = TOSH_interrupt_disable();
	            whenToFire(i);
	            if (temp) TOSH_interrupt_enable();
	        }
	    }
    	} 
    	if (mState) call AbsoluteTimer1.set(nextEventTime);
    	dbg(DBG_USR1, "Timer.timeoutHandler: mstate=\%d\n", mState);
    }

    event result_t AbsoluteTimer1.fired() {
        post timeoutHandler();
        return SUCCESS;
    }
}
