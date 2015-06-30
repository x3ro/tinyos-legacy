/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *									
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2004 Intel Corporation 
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
 * Authors:   Phil Levis
 * History:   Dec 6 2004         Inception.
 *
 */

/**
 * @author Phil Levis
 */


includes AM;
//includes Mate;
//includes MateConstants;

module SynchTimerContextM {
  provides {
    interface StdControl;
    //interface MateBytecode as StartTimer;
    //interface MateBytecode as StopTimer;
  }
  
  uses {
    interface StdControl as SubControlTimer;
    interface GlobalTime;
    interface Timer as ClockTimer;
    interface SendMsg as Send;
    interface Leds as Leds;
    //interface MateContextSynch as Synch;
    //interface MateHandlerStore as HandlerStore;
    //interface MateEngineStatus as EngineStatus;
  }
}


implementation {

  enum {
    SYNCH_TIMER_DEFAULT_S            = 1,
    SYNCH_TIMER_DEFAULT_MS           = 2000,
    SYNCH_TIMER_DEFAULT_TIMER_TICKS  = 2048,
    SYNCH_TICKS_PER_S_L2             = 15,
    SYNCH_TIMER_PADDING              = 50,
    SYNCH_TIMER_MINIMUM_TICKS        = 5,
  }; 
  
  //MateContext timerContext;
  uint32_t intervalMilliseconds;
  uint32_t intervalTicks;
  uint32_t lastTime;
  uint32_t offset;
  uint32_t offsetIncrement;
  uint16_t timerRate;
  uint32_t lastRemaining;
  uint32_t count = 0;
  
  TOS_Msg msg;

  // Set the triggering interval
  void setInterval(uint32_t ms) {
    intervalMilliseconds = ms;
    intervalTicks = ms;
    msToTicks(&intervalTicks);
  }
   
  // Assumes 32KHz clock: different than Timer ticks (1024Hz)
  void ticksToMs(uint32_t* time) {
    uint32_t sec = *time >>  15;
    uint32_t msec = (*time & 0x7fff) + offset;
    msec = msec >> 5;
    msec = msec * 1000 + 1023;
    msec = msec / 1024;
    sec  += msec / 1000;
    msec %= 1000;
    
    dbg(DBG_TEMP, "SynchTimerContextM: Turned %u ticks into %u.%u\n", *time, (int)sec, (int)msec);
    *time = (sec * 1000) + msec;
  }
  
  // Assumes 32KHz clock: different than Timer ticks (1024HZ)
  void msToTicks(uint32_t* time) {
    uint32_t sec = *time / 1000;
    uint32_t msec = (*time % 1000);
    *time = (msec << 15) / 1000;
    *time += (sec << 15);
    *time -= offset;
    dbg(DBG_TEMP, "SynchTimerContextM: Turned %u.%u ms into %u ticks\n", (int)sec, (int)msec, *time);
  }
  
  void millisecondsRemaining(uint32_t* time) {
    result_t rval = call GlobalTime.getGlobalTime(time);
    if (rval == FAIL) {
      dbg(DBG_TEMP, "SynchTimerContextM: Not synchronized.\n");
      *time = -1;
      return;
    }

    if (*time < lastTime) {
      offset += offsetIncrement;
      offset %= intervalTicks;
      dbg(DBG_TEMP, "SynchTimerContextM: Adjusting offset to %i\n", (int)offset);
    }
    
    lastTime = *time;
    ticksToMs(time);
    *time %= intervalMilliseconds;
    *time = intervalMilliseconds - *time;
    dbg(DBG_TEMP, "SynchTimerContextM: %u ms remaining\n", (int)*time);
  }  

  void setTimer(uint16_t newRate) {
    result_t rval;
    if (newRate == timerRate) {
      dbg(DBG_TEMP, "VM: Setting timer to %i, already there, do nothing.\n", (int)newRate);
      return;
    }
    dbg(DBG_TEMP, "VM: Setting timer to %i.\n", (int)newRate);
    timerRate = newRate;
    call ClockTimer.stop();
    rval = call ClockTimer.start(TIMER_REPEAT, timerRate);
    if (rval == FAIL) {
      // call an error condition
    }

  }
  
  void rescheduleTimer(uint32_t* msRemaining) {
   uint32_t timerTicksRemaining;
    // Timer is far away, schedule to max time
    if (*msRemaining > (SYNCH_TIMER_DEFAULT_MS + SYNCH_TIMER_PADDING)) {
      if (timerRate != SYNCH_TIMER_DEFAULT_TIMER_TICKS) {
	dbg(DBG_TEMP, "VM: In general case..\n");
	setTimer(SYNCH_TIMER_DEFAULT_TIMER_TICKS);
      }
    }
    else  {
      timerTicksRemaining = (*msRemaining * 1024) / 1000;
      if (timerTicksRemaining > SYNCH_TIMER_PADDING) {
	timerTicksRemaining -= (SYNCH_TIMER_PADDING / 2); 
      }
      if (timerTicksRemaining < SYNCH_TIMER_MINIMUM_TICKS) {
	timerTicksRemaining = SYNCH_TIMER_MINIMUM_TICKS;
      }
      dbg(DBG_TEMP, "VM: In epsilon case\n");
      // We schedule the timer to go off a little early
      setTimer(timerTicksRemaining);
    }
  }

  // Note that this limits the max frequency
  void resetTimer() {
   dbg(DBG_TEMP, "VM: Resetting timer.\n");
    if (intervalMilliseconds > 0) {
      setTimer(SYNCH_TIMER_DEFAULT_TIMER_TICKS);
    }
    else {
      call ClockTimer.stop();
    }
  }

  
  void sendUpdate(uint32_t* msRemaining) {
    TOS_MsgPtr buf = &msg;
    TimeTestMsg* timeMsg = (TimeTestMsg*)buf->data;
    uint32_t tval;
    result_t rval;
    
    rval = call GlobalTime.getGlobalTime(&tval);
    timeMsg->ticks = tval;
    ticksToMs(&tval);
    timeMsg->ms = tval;
    timeMsg->remaining = *msRemaining;
    timeMsg->count = count;
    timeMsg->offset = offset;
    timeMsg->synchronized = (rval == SUCCESS);
    call Leds.redToggle();
    call Send.send(TOS_UART_ADDR, sizeof(TimeTestMsg), buf);
  }

  event result_t Send.sendDone(TOS_MsgPtr m, result_t val) {
    return SUCCESS;
  }
  
  task void ClockEventTask() {
    uint32_t remaining;
    dbg_clear(DBG_TEMP,"\n");
    millisecondsRemaining(&remaining);
    dbg(DBG_USR1|DBG_TEMP, "VM: SynchTimerContext has %u ms remaining\n", remaining);
    if (remaining > SYNCH_TIMER_PADDING && remaining < lastRemaining) {
      lastRemaining = remaining;
      rescheduleTimer(&remaining);
      //sendUpdate(&remaining);
    }
    else {
      lastRemaining = intervalMilliseconds;
      if (1) {
	/*      if (timerContext.state == MATE_STATE_HALT) {*/
	dbg(DBG_USR1|DBG_TEMP, "VM: Synch timer context running.\n");
	//call Synch.initializeContext(&timerContext);
	//call Synch.resumeContext(&timerContext, &timerContext);
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, "VM: Synch timer context cannot run, it isn't halted.\n");
      }
      count++;
      sendUpdate(&remaining);
      resetTimer();
    }
  }
  
  command result_t StdControl.init() {
    result_t rval = call SubControlTimer.init();
    /*    timerContext.which = MATE_CONTEXT_SYNCHTIMER;
	  timerContext.rootHandler = MATE_HANDLER_SYNCHTIMER; */
    intervalMilliseconds =  (uint32_t) 10000;
    //    intervalMilliseconds *= (uint32_t) 30;
    intervalTicks = intervalMilliseconds;
    msToTicks(&intervalTicks);

    offsetIncrement = (0x7fffffff % intervalTicks);
    offsetIncrement++;
    offsetIncrement *= 2;
    offsetIncrement %= intervalTicks;
    
    call Leds.init();
    call Leds.yellowOn();
    //rval &= call HandlerStore.initializeHandler();
    //call Synch.initializeContext(&timerContext);
    
    return rval;
  }

  command result_t StdControl.start() {
    call SubControlTimer.start();
    resetTimer();
    call Leds.greenOn();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call ClockTimer.stop();
    return call SubControlTimer.stop();
  }
  
  event result_t ClockTimer.fired() {
    post ClockEventTask();
    call Leds.greenToggle();
    return SUCCESS;
  }

  /*  event void HandlerStore.handlerChanged() {
    dbg(DBG_USR3, "SynchTimerContext: Handler changed.\n");
        if (timerContext.state != MATE_STATE_HALT) {
      //call Synch.haltContext(&timerContext);
      }
      }*/

  /*  event void EngineStatus.rebooted() {
    dbg(DBG_USR1, "SynchTimerContext: VM rebooted.\n");
    call ClockTimer.stop();
        if (timerContext.state != MATE_STATE_HALT) {
      //call Synch.haltContext(&timerContext);
      }
  }*/ 

  /*  command result_t StartTimer.execute(MateContext* context) {
    return SUCCESS;
  }

  command result_t StopTimer.execute(MateContext* context) {
    return SUCCESS;
  }

  command result_t StopTimer.byteWidth() {
    return 1;
  }

  command result_t StartTimer.byteWidth() {
    return 1;
  }
  */

#ifdef PLATFORM_PC
  default command result_t Send.send(uint16_t addr, uint8_t len, TOS_MsgPtr msg) {
    uint32_t currentMs;
    uint32_t currentTicks;
    call GlobalTime.getGlobalTime(&currentTicks);
    currentMs = currentTicks;
    ticksToMs(&currentMs);
    printf("%s: Timer firing. Mote ms: %u Mote ticks: %u Offset: %u .\n", currentTime(), currentMs, currentTicks, offset);
    return FAIL;
  }
#endif
}
