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

includes TosTime;

module LogicalTimeM {
    provides {
        interface StdControl;
        interface Time;
        interface TimeSet;
        interface TimeUtil;
        interface AbsoluteTimer;
    }
    uses {
        interface Clock;
        interface StdControl as ClockControl;
        interface Leds;
        interface SysTime;
    }
}

implementation
{
    tos_time_t time; // logic time counter
    int16_t adjustment; // in us;
    uint32_t t16; // 16 bit timer reading, unit is 1/4 microsecond
    uint8_t shifts[8] ; // index is scale
    uint8_t scale ;
    uint8_t timerFlag, setFlag ;
    tos_time_t expireTime;
    enum {
	AUTO_CORRECT,
    };
    
    command result_t StdControl.init() {
	time.high32=0; 
	time.low32 =0;
	timerFlag = 0;
	setFlag=0;

	call ClockControl.init();
	scale = DEFAULT_SCALE;
        call SysTime.init();
	adjustment = 0;
	shifts[0]=shifts[1]=5;
	shifts[2]=8; shifts[3]=10; shifts[4]=11;shifts[5]=12;
	shifts[6]=13;shifts[7]=15;
	return SUCCESS;
    }

    command result_t StdControl.start() {
	call ClockControl.start();
        call SysTime.get(&t16);
	return SUCCESS ;
    }

    command result_t StdControl.stop() {
	call ClockControl.stop();
	timerFlag = 0;
	setFlag   = 0;
	adjustment= 0;
	return SUCCESS;
    }
   /**
    * Time.getUs command returns clock phase offset from last clock counter 
    * change. If the scale level is 3, it gives the remaining microseconds
   **/
    command uint16_t Time.getUs() {
        uint32_t t1;
        uint16_t retval;

        call SysTime.get(&t1);
        t1 -= t16; 
       
        // convert the unit into microsecond
        retval = (t1 & 0xFFFF ) >> 2;

        // we don't need the full units of ms, we care only the remaining us
        // for current scale level
        //return (retval%(0x1<<shifts[scale])); // this is computationaly heavy
        return (retval & 0x3FF); // this is only true when scale =3
    }

    command tos_time_t Time.get() {
        uint8_t temp;
        uint32_t delta;
        tos_time_t retval;
       /*
        delta = call Clock.readCounter();
        delta <<=shifts[scale];
        delta += call Time.getUs();
        */
        //dbg(DBG_USR1, "Time.get: delta =\%x \n", delta);
        temp = TOSH_interrupt_disable();
        retval = time;
        if (temp) TOSH_interrupt_enable();
        call SysTime.get(&delta);
        delta >>= 2;
        if ((retval.low32 + delta) < retval.low32) {
           retval.high32 ++;
        }       
        retval.low32 += delta ;
        return retval;
    }

    command uint32_t Time.getHigh32()  {
       return time.high32;
    }

    command uint32_t Time.getLow32() {
       return time.low32;
    }

    command uint16_t  Time.getMs() {
       uint32_t retval;     
       retval = call Time.getLow32();
       return (uint16_t)((time.low32+512) >>10);
    }

    command uint16_t Time.getSeconds() {
       uint16_t temp, t;

       t = time.low32 >>20;
       temp = (uint16_t)(time.high32 & 0x000F) <<12;
       return t|=temp ;
    }
       
    command void TimeSet.set( tos_time_t t) {
        uint8_t temp;
        //call Leds.yellowToggle();
        temp = TOSH_interrupt_disable();
        time = t;
        if(temp) TOSH_interrupt_enable();
        call Clock.setCounter(0);
        call SysTime.get(&t16);
    }

    command void TimeSet.adjust(int16_t us) {     
        adjustment = us; // do it at next interrupt
    }

    command void TimeSet.adjustNow(int16_t us) {
        bool temp;
        temp = TOSH_interrupt_disable();
        time.low32 += us;  
        if (us>0 && ((time.low32 + us) <time.low32)) {
            time.high32 ++;
        } else if (us<0 && ((time.low32+us) > time.low32)) {
            time.high32--;
        } 
        if (temp) TOSH_interrupt_enable();
    }	

    // utility function 
    // compare a and b. If a>b return 1 a==b return 0 a< b return -1
    command char TimeUtil.compare(tos_time_t a, tos_time_t b){
       if (a.high32>b.high32) return 1;
       if (a.high32 <b.high32) return -1;
       // a.high32 = b.high32
       if (a.low32 > b.low32 ) return 1;
       if (a.low32 < b.low32 ) return -1;
       return 0;
    }

    // subtract b from a , return the difference. 
    command tos_time_t TimeUtil.subtract(tos_time_t a, tos_time_t b)  {
       tos_time_t result;
       if (a.low32>b.low32 ) {
           result.low32 = a.low32 - b.low32;
           result.high32 = a.high32 - b.high32;
       } else {
           result.low32  =  a.low32 - b.low32 ;
           result.high32 = a.high32 - b.high32 -1;
       }
       return result;
    }
     

    // add a and b return the sum. 
    command tos_time_t TimeUtil.add( tos_time_t a, tos_time_t b){
        tos_time_t result;
        result.low32 = a.low32 + b.low32 ;
        if ( result.low32 < a.low32) {
            result.high32 = a.high32 + b.high32 +1;
        } else {
            result.high32 = a.high32 + b.high32;
        }
        return result;
    }

  
   /** increase tos_time_t a by a specified unmber of binary micro-seconds
    *  return the new time 
    **/
    command tos_time_t TimeUtil.addUint32(tos_time_t a, uint32_t us) {
        tos_time_t result;
	result.low32 = a.low32 + us ;
	if ( result.low32 < a.low32) {
	    result.high32 = a.high32 +1;
	} else {
	    result.high32 = a.high32 ;
	}
	//dbg(DBG_USR1, "result: \%x , \%x\n", result.high32, result.low32);
	return result;
    }  
  
  /** substrct tos_time_t a by a specified unmber of binary micro-seconds
   *  return the new time 
   **/
    command tos_time_t TimeUtil.subtractUint32(tos_time_t a, uint32_t us)  {
	tos_time_t result;

	if ( result.low32 < us) {
	    result.high32 = a.high32-1;
	} else {
	    result.high32 = a.high32 ;
	}
	result.low32  = a.low32 - us;
	//dbg(DBG_USR1, "result: \%x , \%x\n", result.high32, result.low32);
	return result;
    }

    command tos_time_t TimeUtil.create(uint32_t high, uint32_t low) {
	tos_time_t result;
	result.high32 = high;
	result.low32 = low;
	return result;
    }

    command uint32_t TimeUtil.low32(tos_time_t lt) {
        return lt.low32;
    }

    command  uint32_t TimeUtil.high32(tos_time_t lt) {
        return lt.high32;
    }

    void adjustInterval() {
	uint32_t ticks; 
        uint8_t TH, temp;
	tos_time_t td;
	
	dbg(DBG_USR1, "adjustInterval time=\%x, \%x\n ", time.high32, time.low32);
	temp = TOSH_interrupt_disable();
	td = call TimeUtil.subtract(expireTime, time);
	if (temp) TOSH_interrupt_enable();

	dbg(DBG_USR1, "adjustInterval td=\%x, current Interval=\%x\n ", td.low32, call Clock.getInterval());

	if (td.high32>0) { 
            call Clock.setInterval(DEFAULT_INTERVAL);
            return ;
        }
        TH = call Clock.readCounter(); // current HW counter  
        TH = call Clock.getInterval() - TH; // how many ticks away from next clock interrupt
        if (TH<=1) return;
	ticks = td.low32 >>shifts[scale] ; // convert time-to-fire to ticks.
        if (ticks< (TH-1)) {
            // leave 1 tick margin
            call Clock.setInterval((uint8_t)ticks);
	    dbg(DBG_USR1, "adjustInterval: Set interval to \%d \n", ticks);
        } else if ( ticks>DEFAULT_INTERVAL ) {
            call Clock.setInterval(DEFAULT_INTERVAL);
        }
    }

    // start a timer that expired when logic time is equal to "in"
    command result_t AbsoluteTimer.set(tos_time_t in ) {
	uint8_t temp;
	// allow user to change expireTime
	temp = TOSH_interrupt_disable();
	expireTime = in;
	timerFlag =1 ;
	if(temp) TOSH_interrupt_enable();
	dbg(DBG_USR1, "LogicalTimeM:ATimer.set expireTime=\%x,  current time = \%x\n", expireTime.low32, time.low32);
	adjustInterval();
	return SUCCESS;
    }


    command result_t AbsoluteTimer.cancel() {
	dbg(DBG_USR1, "stop baseTimer\n");
	timerFlag= 0;
	call Clock.setNextInterval(DEFAULT_INTERVAL);

	return SUCCESS;
    }

    default event result_t AbsoluteTimer.fired() {
	return SUCCESS ;
    }


    event result_t Clock.fire() { 
	int8_t temp, retval;
        bool timerEvent = FALSE;
	uint32_t delta;
	//call Leds.greenToggle();

	// update 4MHz sysTime reading
        call SysTime.resetOverflowCounter();
        call SysTime.get(&t16); 
	delta = call Clock.getInterval()+1;   // for 128L
	delta <<= shifts[scale];
	
	if (adjustment!=0) {
	    delta = delta  + adjustment ; 
	    adjustment =0;
	}
	// update logical time
	temp = TOSH_interrupt_disable();
	if ((delta + time.low32) < time.low32) time.high32++;
	time.low32+=delta;
	if (temp) TOSH_interrupt_enable();

	//dbg(DBG_USR1, "Clock.fire: timerFlag =\%d time=\%x, \%x \n",timerFlag,time.high32, time.low32);
	if (timerFlag) {// if base timer running
	    temp = TOSH_interrupt_disable();
	    retval = call TimeUtil.compare(time,  expireTime);
	    if (temp) TOSH_interrupt_enable();
	    if (retval>=0) {
	        dbg(DBG_USR1, "LogicalTimeM: base timer expired \n");
	        timerFlag=0;
                call Clock.setInterval(DEFAULT_INTERVAL);
                timerEvent= TRUE;
            }
        }
        if (timerEvent) {
            signal AbsoluteTimer.fired();
        }        
	return SUCCESS;
    }
    

}
