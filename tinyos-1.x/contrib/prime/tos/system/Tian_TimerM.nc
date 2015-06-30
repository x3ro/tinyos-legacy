/*                                                                      tab:4
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
 *      Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *      Redistributions in binary form must reproduce the above copyright
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
 * Authors:             Su Ping <sping@intel-research.net>
 *
 * This implementation assumes that DEFAULT_SCALE is 3.
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
    uint32_t mState;		// each bit represent a timer state 
    uint8_t  setIntervalFlag; 
    uint8_t mScale, mInterval;
    struct timer_s {
        uint8_t type;		// one-short or repeat timer
        int32_t ticks;		// clock ticks for a repeat timer 
        int32_t ticksLeft;	// ticks left before the timer expires
    } mTimerList[NUM_TIMERS];
  
    command result_t StdControl.init() {
        mState=0;
        setIntervalFlag = 0;
        mScale = 3;
        mInterval = DEFAULT_INTERVAL;
        return call Clock.setRate(mInterval, mScale) ;
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        mState=0;
        mInterval = DEFAULT_INTERVAL;
        setIntervalFlag = 0;
        return SUCCESS;
    }

    command result_t Timer.start[uint8_t id](char type, 
				   uint32_t interval) {
        char temp;

        if (id > NUM_TIMERS) return FAIL;
        if (type>1) return FAIL;
        mTimerList[id].ticksLeft= interval; 
        mTimerList[id].ticks = interval ;
        mTimerList[id].type = type;

        temp = TOSH_interrupt_disable();
        mState|=(0x1<<id);
	if (interval < mInterval) {
	    mInterval=interval;
	    call Clock.setInterval(mInterval);
            setIntervalFlag = 0;
        }
	if (temp) TOSH_interrupt_enable();
        return SUCCESS;
    }

    static void adjustInterval() {
        uint8_t temp, i, val = mInterval;
        if ( mState) {
            for (i=0;i<NUM_TIMERS;i++) {
                if ((mState&(0x1<<i)) && (mTimerList[i].ticksLeft <val )) {
                    val = mTimerList[i].ticksLeft;
		}
            }
            if (val <mInterval) {
                temp = TOSH_interrupt_disable();
                mInterval =  val;
                call Clock.setInterval(mInterval);
                setIntervalFlag = 0;
                if(temp) TOSH_interrupt_enable();
            } else {
                setIntervalFlag = 0;
            }
        } else if (mInterval!=DEFAULT_INTERVAL)  {
            temp = TOSH_interrupt_disable();
            mInterval=DEFAULT_INTERVAL;
            call Clock.setInterval(mInterval);
            setIntervalFlag = 0;
            if(temp) TOSH_interrupt_enable();
        }
    }

    command result_t Timer.stop[uint8_t id]() {
        char temp;
        if (id>=NUM_TIMERS) return FAIL;
        if (mState&(0x1<<id)) { // if the timer is running 
	    temp = TOSH_interrupt_disable();
	    mState &= ~(0x1<<id);
            if(temp) TOSH_interrupt_enable();
	    if (!mState) {
	        setIntervalFlag = 1;
	    } 	
            return SUCCESS;
        }
        return FAIL; //timer not running
    }


    default event result_t Timer.fired[uint8_t id]() {
        return SUCCESS;
    }

    task void HandleFire() {
        uint8_t i; 
        if (mState) {
            for (i=0;i<NUM_TIMERS;i++)  {
                if (mState&(0x1<<i)) {
                    mTimerList[i].ticksLeft -= (mInterval+1) ; 
                    if (mTimerList[i].ticksLeft<=0) {
                        if (mTimerList[i].type==TIMER_REPEAT) {
                            mTimerList[i].ticksLeft= mTimerList[i].ticks;
                            if (mTimerList[i].ticks<mInterval)
                                setIntervalFlag =1;
                        } else {// one shot timer 
                            mState &=~(0x1<<i); 
                        }
                        signal Timer.fired[i]();
                    }
                }
            }
        }
        if (setIntervalFlag) {
            adjustInterval();
        }
    }

    event result_t Clock.fire() {
#if 0      
        uint8_t i; 
        if (mState) {
            for (i=0;i<NUM_TIMERS;i++)  {
                if (mState&(0x1<<i)) {
                    mTimerList[i].ticksLeft -= (mInterval+1) ; 
                    if (mTimerList[i].ticksLeft<=0) {
                        if (mTimerList[i].type==TIMER_REPEAT) {
                            mTimerList[i].ticksLeft= mTimerList[i].ticks;
                            if (mTimerList[i].ticks<mInterval)
                                setIntervalFlag =1;
                        } else {// one shot timer 
                            mState &=~(0x1<<i); 
                        }
                        signal Timer.fired[i]();
                    }
                }
            }
        }
        if (setIntervalFlag) {
            adjustInterval();
        }
#endif
	post HandleFire();
        return SUCCESS;
    }
}
