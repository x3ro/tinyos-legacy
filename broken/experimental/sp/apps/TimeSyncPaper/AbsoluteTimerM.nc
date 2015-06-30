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
 *
 * Authors:		Su Ping  (sping@intel-research.net)

 * Date last modified:  9/25/02
 *
 */

includes AbsoluteTimer;
includes TosTime;

module AbsoluteTimerM {
    provides interface AbsoluteTimer[uint8_t id];
    provides interface StdControl; 
    uses {   
        interface Leds;
        interface AbsoluteTimer as BaseTimer;
        interface Time;
        interface TimeUtil;
        interface StdControl as TimeControl;
    }
}
implementation
{
    uint8_t useBit;
    int8_t baseTimerIndex; 
    struct timer_s {
       tos_time_t expireTime;
    } aTimer[MAX_NUM_TIMERS];

    void selectBaseTimer();       

    command result_t StdControl.init() {
	useBit = 0;
	baseTimerIndex= -1;
	call TimeControl.init();
	return SUCCESS;
    }

    command result_t StdControl.start() {
    	call TimeControl.start();
   	return SUCCESS;
    }  

    command result_t StdControl.stop() {
    	useBit=0;
    	baseTimerIndex=-1;
    	call TimeControl.stop();
    }

    // start a timer that expired when logic time high32 is equal to "in"
  
    command result_t AbsoluteTimer.set[uint8_t id](tos_time_t in ) {
    	char temp;
    	if ( id>=MAX_NUM_TIMERS ) {
            dbg(DBG_USR1, "Atimer.set: Invalid id=\%d max=%d\n", id, MAX_NUM_TIMERS);
            return FAIL;
    	}

    	// by not checking the useBit for this timer id, 
    	// we allow a timer being started more than once without stopping it first
    	// if required timer expire time is a past time, return fail
    	if ((call TimeUtil.compare(call Time.get(), in))==1) {
            dbg(DBG_USR1, "Atimer.set: time has passed\n");
            signal AbsoluteTimer.fired[id]();
            return FAIL;
    	}
    	// add this timer
        call Leds.greenToggle();
    	temp = TOSH_interrupt_disable();
    	useBit |= (0x1<<id);
    	aTimer[id].expireTime = in;
    	if (temp) TOSH_interrupt_enable();
    	dbg(DBG_USR1, "Atimer.set: baseTimerIndex =\%d \n", baseTimerIndex);
    	if (baseTimerIndex==-1) {
            // re-start base timer
	    dbg(DBG_USR1, "Atimer.set: base timer not running. call BaseTimer.set()\n");
            baseTimerIndex = id;
            call BaseTimer.set(in);
        } else {
            dbg(DBG_USR1, "Atimer.set: base timer running.\n");
            if ( call TimeUtil.compare(aTimer[(int)baseTimerIndex].expireTime,  in)==1) {
                baseTimerIndex=id;
	        dbg(DBG_USR1, "Atimer.set:change basetimer expireTime by call BaseTimer.set()\n");
                call BaseTimer.set(in);
            }
        }    
    	return SUCCESS;
    }


    command result_t AbsoluteTimer.cancel[uint8_t id]() {
        char temp;
        
        if ((id>=MAX_NUM_TIMERS)||!(useBit&(0x01<<id)) ) {
            dbg(DBG_USR1, "Atimer.cancel: Invalid id\n");
            return FAIL;
        }
        // stop the timer
        temp = TOSH_interrupt_disable();
        useBit &= ~(0x1<<id);
        if(temp) TOSH_interrupt_enable();
    	if (baseTimerIndex==id) { // need update base timer
            selectBaseTimer();
    	}
    	dbg(DBG_USR1, "ATimer.cancel: \%d\n", id);
    	return SUCCESS;
    }

    void selectBaseTimer() {
        int i;
        if (useBit) {
        // select a reference
        for (i=0; i<MAX_NUM_TIMERS; i++) {
            if ( useBit&(0x1<<i)) { baseTimerIndex = i; break; }
        }
        dbg(DBG_USR1, "Atimer.selectBaseTimer i=\%d\n", i);
	while (++i<MAX_NUM_TIMERS) {
            if (useBit&(0x1<<i))            
            if ( call TimeUtil.compare( aTimer[baseTimerIndex].expireTime, aTimer[i].expireTime)==1) 
                baseTimerIndex = i;
        } // end of while
        dbg(DBG_USR1, "Atimer.selectBaseTimer baseTimerIndex=\%d\n", baseTimerIndex);
        call BaseTimer.set(aTimer[baseTimerIndex].expireTime);     
        dbg(DBG_USR1, "Atimer.selectBaseTimer baseTimerIndex=\%d\n", baseTimerIndex);
        }
    }

    default event result_t AbsoluteTimer.fired[uint8_t id]() {
	return SUCCESS ;
    }

    // at least one of our timer has expired
    void  task timeout() {
    	int i; 
    	tos_time_t now= call Time.get();
    	dbg(DBG_USR1, "Atimer.timeout: usrBit \%x time \%x\n", useBit, now.low32);
    	for (i=0; i<MAX_NUM_TIMERS; i++) {
            dbg(DBG_USR1, "Atimer.timeout: \%d \%x \n", i, aTimer[i].expireTime.low32);
            if ((useBit&(0x1<<i)) && ((call TimeUtil.compare(now, aTimer[i].expireTime))>=0)) {
                useBit &= ~(0x1<<i);
                signal AbsoluteTimer.fired[i]();
            }            
        } 
    	if (useBit) 
            selectBaseTimer();
    	dbg(DBG_USR1, "Atimer.timeout end: usrBit \%x \n", useBit);
    }

    event result_t BaseTimer.fired() { 
        baseTimerIndex = -1; 
	post timeout();
	return SUCCESS ;
    }
}
