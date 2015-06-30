// $Id: LogicalTimeM.nc,v 1.2 2003/10/07 21:45:29 idgay Exp $

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

/*
 *
 * Authors:		Su Ping  (sping@intel-research.net)

 * Date last modified:  9/25/02
 *
 */

includes TosTime;
includes Timer;
includes AbsoluteTimer;

module LogicalTimeM {
    provides {
        interface StdControl;
        interface Time;
        interface TimeSet;
        interface Timer[uint8_t id];
	interface AbsoluteTimer[uint8_t id];
    }
    uses {
        interface Clock;
        interface StdControl as ClockControl;
        interface Leds;
	interface TimeUtil;
        //interface PowerManagement;
    }
}

implementation
{
    tos_time_t time; // logic time counter
    int16_t adjustment; // in us;
    
    uint32_t mState;            // each bit represent a timer state
    uint8_t  setIntervalFlag;
    
    struct timer_s {
        uint8_t type;           // one-short or repeat timer
        int32_t ticks;          // clock ticks for a repeat timer
        int32_t ticksLeft;      // ticks left before the timer expires
    } mTimerList[NUM_TIMERS + 1];

	// module variables for absolute timer
    uint8_t useBit;
    int8_t baseTimerIndex; 
    tos_time_t aTimer[MAX_NUM_TIMERS];
    

    void selectBaseTimer(); 
    void resetBaseTimer();
    task void processTimersTask();
	          
    command result_t StdControl.init() {
	// initialize logical time
      atomic {
	time.high32=0; 
	time.low32 =0;
	// initialize other module variables
	setIntervalFlag=0;
	useBit = 0; mState = 0;
	baseTimerIndex= -1;
	call ClockControl.init();	
	adjustment = 0;
      }
      return SUCCESS;
    }

    command result_t StdControl.start() {
	call ClockControl.start();
        //dbg(DBG_TIME, "LogicalTime.StdControl.start \n");
	return SUCCESS ;
    }

    command result_t StdControl.stop() {
      call ClockControl.stop();
      atomic {
	setIntervalFlag   = 0;
	adjustment= 0;
        mState=0;
        useBit=0;
    	baseTimerIndex=-1;
      }
      return SUCCESS;
    }
   /**
    * Time.getUs command returns clock phase offset 
   **/
    async command uint16_t Time.getUs() {
	return 0;
	//return (phaseOffset&0xffff);
    }

    async command tos_time_t Time.get() {
      tos_time_t rval;
      atomic {
	rval = call TimeUtil.addUint32(time, call Clock.readCounter());
      }
      return rval;
    }

    async command uint32_t Time.getHigh32()  {
      uint32_t rval;
      atomic {
        rval = time.high32;
      }
      return rval;
    }

    async command uint32_t Time.getLow32() {
      uint32_t rval;
      atomic {
        rval = time.low32;
      }
      return rval;
    }

    command void TimeSet.set( tos_time_t t) {
        atomic {
          time = t;
        }
        call Clock.setCounter(0);
        //call SysTime.get(&t16);
        // if baseTimer running, stop it and restart it based on the new time
        if (baseTimerIndex!=-1) resetBaseTimer();
    }

    command void TimeSet.adjust(int16_t n) { 
      atomic {    
        adjustment +=n ;
      }
    }	

    command void TimeSet.adjustNow(int32_t ms) {
      atomic {
	time.low32 += ms; 
        if (baseTimerIndex!=-1) {
            // adjust baseTimer ticksLeft by ms
            mTimerList[NUM_TIMERS].ticksLeft += ms ; 
        }
      }
    }

    void resetBaseTimer() {
        tos_time_t td = call Time.get();
        atomic {
            td = call TimeUtil.subtract(aTimer[baseTimerIndex], td);   
        } 
        call Timer.start[NUM_TIMERS](TIMER_ONE_SHOT, td.low32 );
	dbg(DBG_TIME, "resetBaseTimer: baseTimerIndex=%d ticksLeft=%d\n", baseTimerIndex, td.low32);
    }

    command result_t AbsoluteTimer.set[uint8_t id](tos_time_t in ) {
        dbg(DBG_TIME, "Atimer.set: add Atimer %d  expire at %d\n", id, in.low32);
        if ( id>=MAX_NUM_TIMERS ) {
            dbg(DBG_TIME, "Atimer.set: Invalid id=\%d max=%d\n", id, MAX_NUM_TIMERS);
            return FAIL;
    	}

    	// by not checking the useBit for this timer id, 
    	// we allow a timer's expire time  being changed 
    	// if required timer expire time is a past time, return fail
    	if ((call TimeUtil.compare(call Time.get(), in))>=0) {
            dbg(DBG_TIME, "Atimer.set: time has passed\n");
            signal AbsoluteTimer.fired[id]();
            return FAIL;
    	}
    	// add this timer
    	atomic {
    	    useBit |= (0x1<<id);
    	    aTimer[id] = in;    	
    	    if (baseTimerIndex==-1) {
                baseTimerIndex = id;
                resetBaseTimer();
            } else {
                //dbg(DBG_TIME, "Atimer.set: base timer running.\n");
                if ( call TimeUtil.compare(aTimer[(int)baseTimerIndex], in)==1) { 
                    baseTimerIndex=id;
                    resetBaseTimer();
                }
            } 
        }
	dbg(DBG_TIME, "Atimer.set: add Atimer %d  end\n", id);  
    	return SUCCESS;
    }


    command result_t AbsoluteTimer.cancel[uint8_t id]() {
        uint8_t running;
        atomic {
            running = useBit&(0x01<<id)  ;
        }
        if ((id>=MAX_NUM_TIMERS)||running == 0 ) {
            dbg(DBG_TIME, "Atimer.cancel: Invalid id\n");
            return FAIL;
        }
        // stop the timer
	atomic {
            useBit &= ~(0x1<<id);
    	    if (baseTimerIndex==id) { // need update base timer
		call Timer.stop[NUM_TIMERS]();
                selectBaseTimer();
    	    }
        }
    	dbg(DBG_TIME, "ATimer.cancel: \%d\n", id);
    	return SUCCESS;
    }

    void selectBaseTimer() {
        uint8_t i, Index=0xff;
        if (useBit) {
            // select a reference
            for (i=0; i<MAX_NUM_TIMERS; i++) {
                if ( useBit&(0x1<<i)) { Index = i; break; }
            }
            //dbg(DBG_TIME, "Atimer.selectBaseTimer i=\%d\n", i);
            atomic {
            while (++i<MAX_NUM_TIMERS) {
                if (useBit&(0x1<<i))            
                if ( call TimeUtil.compare( aTimer[Index], aTimer[i])==1) 
                    Index = i;
            } 
            }
            baseTimerIndex=Index;
            dbg(DBG_TIME, "Atimer.selectBaseTimer baseTimerIndex=\%d\n", baseTimerIndex);
            resetBaseTimer(); 
        }
    }

    default event result_t AbsoluteTimer.fired[uint8_t id]() {
	return SUCCESS ;
    }

    // at least one of our timer has expired
    void  timeout() {
    	int i=0; 
        bool doSignal;
    	tos_time_t now = call Time.get();
        for (i=0; i<MAX_NUM_TIMERS; i++) {
            //dbg(DBG_TIME, "Atimer.timeout: \%d \%x \n", i, aTimer[i].low32);
            atomic {
                doSignal = (useBit&(0x1<<i)) && ((call TimeUtil.compare(now, aTimer[i]))>=0);
            }
            if (doSignal)  {
                atomic {
                useBit &= ~(0x1<<i);
                }
                signal AbsoluteTimer.fired[i]();
            }            
        } 
	
    	if (useBit) { 
            selectBaseTimer();
        }
        dbg(DBG_TIME, "Atimer.timeout end: usrBit \%x \n", useBit);
    }

    static void adjustInterval() {
        uint8_t i, val, mInterval;
        val = mInterval = call Clock.getInterval();
        dbg(DBG_TIME, "LogicalTime.adjustInterval called\n");
        atomic {
          if ( mState) {
            for (i=0;i<NUM_TIMERS;i++) {
                if ((mState&(0x1<<i)) && (mTimerList[i].ticksLeft <(int32_t)val )) {
                    val = mTimerList[i].ticksLeft;
                }
            }
            if (val < mInterval) {
                call Clock.setInterval(val);
                dbg(DBG_TIME, "LogicalTime.adjustInterval set to %d\n", val);
            } 
          } else {
            call Clock.setInterval(255);  
	    dbg(DBG_TIME, "LogicalTime.adjustInterval set to 255\n");
          } 
          setIntervalFlag = 0;
        }
        //call PowerManagement.adjustPower();  
    }

    command result_t Timer.stop[uint8_t id]() {
        result_t rval = FAIL;
        if (id>=NUM_TIMERS) return FAIL;
        atomic {
          if (mState&(0x1<<id)) { // if the timer is running
            mState &= ~(0x1<<id);
            if (!mState) {	
                setIntervalFlag = 1;				
            }
            dbg(DBG_TIME, "LogicalTime.Timer.stop ok \n");
            rval = SUCCESS;
          }
        }
        dbg(DBG_TIME, "LogicalTime.Timer.stop failed \n");
        return rval; //timer not running
    }

    command result_t Timer.start[uint8_t id](char type,
                                   uint32_t interval) {
        uint8_t mInterval = call Clock.getInterval();
        dbg(DBG_TIME, "Timer.start id=%d interval=%d\n", id, interval);
        if (id > NUM_TIMERS) {
            dbg(DBG_TIME, "LogicalTime.Timer.start failed id = %d \n", id);
            return FAIL;
	} 
        if (type>1) {
            dbg(DBG_TIME, "LogicalTime.Timer.start failed id = %d \n", id);
            return FAIL;
        }
	atomic {
          mTimerList[id].ticksLeft= --interval;
          mTimerList[id].ticks = interval ;
          mTimerList[id].type = type;

          mState|=(0x1<<id);
          if (interval < mInterval) {
            call Clock.setInterval(interval);
            dbg(DBG_TIME, "LogicalTime.Timer.start set interval to %d\n", interval);
          }
        }
        dbg(DBG_TIME, "LogicalTime.Timer %d start ok \n", id);
        return SUCCESS;
    }

    default event result_t Timer.fired[uint8_t id]() {
        return SUCCESS;
    }

    task void timerHandlingTask() {
        int i;
        bool fireTimer;
        uint32_t mStateCopy;
        uint8_t mInterval = call Clock.getInterval();
        atomic {
            mStateCopy = mState;
	}
        //dbg(DBG_TIME, "timerHandlingTask: mInterval=%d\n", mInterval);
        if (mStateCopy) {
            //dbg(DBG_TIME, "timerHandlingTask: mInterval=%d\n", mInterval);
            for (i=NUM_TIMERS;i>=0; i--)  {
                if (mStateCopy&(0x1<<i)) {
                    fireTimer = FALSE;
                    //dbg(DBG_TIME, "Timer %d tickeLeft=%d\n", i, mTimerList[i].ticksLeft);
                    atomic {
                        mTimerList[i].ticksLeft -= (mInterval+1) ;
                        if (mTimerList[i].ticksLeft<=0) {
                            if (mTimerList[i].type==TIMER_REPEAT) {
                                mTimerList[i].ticksLeft= mTimerList[i].ticks;
                                if (mTimerList[i].ticksLeft<(int32_t)mInterval)
                                    setIntervalFlag =1;
                            } else {// one shot timer
                                mState &=~(0x1<<i);
                                if (!mState) {
                                    call Clock.setInterval(255);
                                    dbg(DBG_TIME, "TimerHandling: set interval to 255\n");
                                } else {
                                    setIntervalFlag = 1; 
                                }
                            }
                            dbg(DBG_TIME, "LogicalTime timer %d fired\n", i);
                            if (i== NUM_TIMERS) timeout();
                            else fireTimer = TRUE;
                        }
                    }
                    if (fireTimer) {
                        signal Timer.fired[i]();
		    }
		}
            }
        }
		
        if (setIntervalFlag) {
            adjustInterval();
        }
        return ;
    }

    async event result_t Clock.fire() { 
     
	int32_t delta;
	uint8_t mInterval = call Clock.getInterval(); 
	//dbg(DBG_TIME, "Clock fired: interval = %d\n", mInterval);
	atomic {
        delta = mInterval+1 + adjustment;
        time = call TimeUtil.addint32(time, delta ); 
            if (adjustment!=0) {
                // adjust base timer
                mTimerList[NUM_TIMERS].ticksLeft+= adjustment ;
                adjustment =0;
            }	
        }
	// handle timer
	post timerHandlingTask();
        return SUCCESS;
    }

}
