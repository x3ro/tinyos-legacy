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
 * History:   Dec 10 2004         Inception.
 *
 */

/**
 * @author Phil Levis
 */

/* 
 * Knowledge of hardware clocks is useful for understanding this part
 * of the code
 */

includes AM;
includes Mate;
includes MateConstants;

module SynchTimerContextM {
  provides {
    interface StdControl;
    interface MateBytecode as StartTimer;
    interface MateBytecode as StopTimer;
    interface MateBytecode as DumpState;
    interface MateEngineControl as EngineControl;
  }
  
  uses {
    interface StdControl as SubControlTimer;
    interface GlobalTime;
    //interface Timer;
    interface TimerMilli;
    interface SendMsg as Send;
    //interface SendMsg as SendX;

    interface MateContextSynch as Synch;
    interface MateHandlerStore as HandlerStore;
    interface MateEngineStatus as EngineStatus;
    interface MateTypes        as TypeCheck;
    interface MateStacks       as Stacks;
    interface MateError        as Error;
    interface Leds;
  }
}


implementation {

  enum {
    SYNCH_TIMER_DEFAULT_S            = 1,
    SYNCH_TIMER_DEFAULT_MS           = 15000,
    SYNCH_TIMER_DEFAULT_TIMER_TICKS  = 15360,
    //SYNCH_TIMER_DEFAULT_MS           = 1000,
    //SYNCH_TIMER_DEFAULT_TIMER_TICKS  = 1360,
    SYNCH_TICKS_PER_S_L2             = 15,
    SYNCH_TIMER_PADDING              = 10,
    SYNCH_TIMER_MINIMUM_TICKS        = 5,
    //SYNCH_TIMER_ERROR_TOLERANCE      = 0xFFFFFFL,
    SYNCH_TIMER_ERROR_TOLERANCE      = 1000000L,
    MAX_OCCURANCES_OF_NO_HALT        = 5,
  }; 
  
  void sendUpdate(uint32_t *);
  //void sendDbg(uint32_t, uint32_t, uint32_t);
  MateContext timerContext;
  TOS_Msg msg;
  //TOS_Msg msg2;
  
  uint32_t intervalMilliseconds = 0;
  uint32_t intervalTicks = 0;
  uint32_t lastTime = 0;
  uint32_t offset = 0;
  uint32_t offsetIncrement = 0;
  uint32_t lastRemaining = 0;
  uint32_t count = 0;
  uint32_t timerRate = 0;
  uint32_t notHaltedCounter = 0;

  uint32_t dirtyTime = 0xFFFFFFFF;
  bool newstart;
  bool submitted;

  /* Calculates if the current time is within reason of the previous time.
   * If it is, within some error, then it should be correct. Otherwise,
   * save it and ignore. If we get another bogus reading, maybe we are really
   * out of synch. Otherwise, revert back to normal. The assumption is we will
   * not get two bogus readings in a row.
   */
  bool isReasonable(uint32_t allegedTime) {
    //sendDbg(allegedTime, lastTime, dirtyTime);
    // check if you're starting the timer for the first time
    if(newstart) {
      newstart = FALSE;
      return TRUE;
    }
    // check if this is a reasonable value
    if((allegedTime >= lastTime) &&
       (allegedTime - lastTime) < SYNCH_TIMER_ERROR_TOLERANCE) {
      dirtyTime = 0xFFFFFFFF;
      return TRUE;
    }
    // check if you wrapped around
    if((0xFFFFFFFF - lastTime + allegedTime) < SYNCH_TIMER_ERROR_TOLERANCE) {
      dirtyTime = 0xFFFFFFFF;
      return TRUE;
    }
    // check for two consecutive bad reads... might really be out of sync
    if(allegedTime >= dirtyTime) {
      if((allegedTime - dirtyTime) < SYNCH_TIMER_ERROR_TOLERANCE) {
	lastTime = dirtyTime;
	dirtyTime = 0xFFFFFFFF;
	return TRUE;
      }
    }
    dirtyTime = allegedTime;
    return FALSE;
  }

  /*
   * Convert hardware clock ticks to milliseconds. 
   */
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
  
  /*
   * Convert milliseconds to hardware clock ticks. 
   */
  // Assumes 32KHz clock: different than Timer ticks (1024HZ)
  void msToTicks(uint32_t* time) {
    uint32_t sec = *time / 1000;
    uint32_t msec = (*time % 1000);
    *time = (msec << 15) / 1000;
    *time += (sec << 15);
    *time -= offset;
    dbg(DBG_TEMP, "SynchTimerContextM: Turned %u.%u ms into %u ticks\n", (int)sec, (int)msec, *time);
  }

  /*
   * Sets the rate you want to fire the timer. offsetIncrement is in case
   * there is a wrap-around? A wrap-around is when you overflow the number.
   */
  void setInterval(uint32_t ms) {
    intervalMilliseconds = ms;
    intervalTicks = ms;
    msToTicks(&intervalTicks);
    offsetIncrement = (0x7fffffff % intervalTicks);
    offsetIncrement++;
    offsetIncrement *= 2;
    offsetIncrement %= intervalTicks;
  }
  
  /*
   * Computes the millisecondsRemaining until we should submit a context
   * for execution. It works by adjusting the offset if we have wrapped
   * around (e.g. the current time has A LOT lower than our past time.
   * Then calculates how much time is left from this point on.
   */
  result_t millisecondsRemaining(uint32_t* time) {
    result_t rval = call GlobalTime.getGlobalTime(time);
    if (rval == FAIL) {
      dbg(DBG_TEMP, "SynchTimerContextM: Not synchronized.\n");
      *time = -1;
      return FAIL;
    }

    /* It's possible here, GlobalTime will give us a spurious reading
     * even when it thinks it is synchronized. To resolve this, we don't
     * actually set an offset unless it is within the expected range. (I.e.
     * we check if the slope is reasonable). We assume that we will not
     * get two consecutive bad readings. This has not happened empirically.
     */
    if(!isReasonable(*time)) {
      dbg(DBG_TEMP, "SynchTimerContextM: Bad Reading.\n");
      *time = -1;
      return FAIL;
    }

    // adjust the offset in case we wrap around.
    if (*time < lastTime && ((*time + 0x7fffffff) < lastTime)) {
      offset += (0xffffffff % intervalTicks);
      offset %= intervalTicks;
      dbg(DBG_TEMP, "SynchTimerContextM: Adjusting offset to %i\n", (int)offset);
    }
    
    lastTime = *time;
    ticksToMs(time);
    *time %= intervalMilliseconds;
    *time = intervalMilliseconds - *time;
    dbg(DBG_TEMP, "SynchTimerContextM: %u ms remaining\n", (int)*time);
    return SUCCESS;
  }  
  
  /*
   * Given a new context firing rate, schedules the underlying timer. If it
   * is too small, just set the DEFAULT rate.
   */
  void setTimer(int32_t newRate) {
    result_t rval;
    if (newRate == timerRate) {
      dbg(DBG_TEMP, "VM: Setting timer to %i, already there, do nothing.\n", (int)newRate);
      //sendDbg(timerRate, call TimerMilli.getPeriod(), 0);
      return;
    }
    dbg(DBG_TEMP, "VM: Setting timer to %i.\n", (int)newRate);
    timerRate = newRate;
    call TimerMilli.stop();
    //rval = call Timer.start(TIMER_REPEAT, timerRate);
    rval = call TimerMilli.setPeriodic(timerRate);

    //sendDbg(timerRate, call TimerMilli.getPeriod(), 0);

    if (rval == FAIL) {
      //call Timer.start(TIMER_REPEAT, SYNCH_TIMER_DEFAULT_MS);
      call TimerMilli.setPeriodic(SYNCH_TIMER_DEFAULT_MS);
    }
  }
  
  /*
   * Computes the next time the underlying timer should fire. Schedule
   * it a little early if we are close to it. If we are far away, schedule
   * the DEFAULT time.
   */
 void rescheduleTimer(uint32_t* msRemaining) {
   int32_t timerTicksRemaining;
    // Timer is far away, schedule to max time
    if (*msRemaining > (SYNCH_TIMER_DEFAULT_MS + SYNCH_TIMER_PADDING)) {
      if (timerRate != SYNCH_TIMER_DEFAULT_MS) {
	dbg(DBG_TEMP, "VM: In general case..\n");
	setTimer(SYNCH_TIMER_DEFAULT_MS);
      }
    }
    else  {
      timerTicksRemaining = (*msRemaining * 1024) / 1000;
      // We schedule the timer to go off a little early
      if (timerTicksRemaining > SYNCH_TIMER_PADDING) {
	timerTicksRemaining -= (SYNCH_TIMER_PADDING / 2);
      }
      if (timerTicksRemaining < SYNCH_TIMER_MINIMUM_TICKS) {
	timerTicksRemaining = SYNCH_TIMER_MINIMUM_TICKS;
      }
      dbg(DBG_TEMP, "VM: In epsilon case\n");
      setTimer(timerTicksRemaining);
    }
  }

  // Note that this limits the max frequency; after a timer expires,
  // we reset the timer to this rate. If the timer interval is <
  // DEFAULT, it will be passed over.
 
  void resetTimer() {
    dbg(DBG_TEMP, "VM: Resetting timer.\n");
    if (intervalMilliseconds > 0) {
      setTimer(SYNCH_TIMER_DEFAULT_MS);
    }
    else {
      call TimerMilli.stop();
    }
  }
 
  /*
   * Used for debugging and dumping out information through the UART.
   */
  
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
    call Send.send(TOS_UART_ADDR, sizeof(TimeTestMsg), buf);
  }
  
  /*
  void sendDbg(uint32_t val1, uint32_t val2, uint32_t val3) {
    TOS_MsgPtr buf = &msg2;
    DbgMsg* dbgMsg = (DbgMsg*)buf->data;
    dbgMsg->myInterval = val1;
    dbgMsg->timerInterval = val2;
    //dbgMsg->allegedTime = val1;
    //dbgMsg->lastTime = val2;
    dbgMsg->dirtyTime = count;
    call SendX.send(TOS_UART_ADDR, sizeof(DbgMsg), buf);
  }
  */
  /* Split phase operation, see NesC documentation for more details */
  event result_t Send.sendDone(TOS_MsgPtr m, result_t val) {
    return SUCCESS;
  }
  /*
  event result_t SendX.sendDone(TOS_MsgPtr m, result_t val) {
    return SUCCESS;
  }
  */
  /*
   * The brains of whether we should run the context. Check if we are
   * even close. If we are not precise enough on when we should fire,
   * reschedule the timer. Otherwise, submit the Mate context for execution
   * and reset our interval information.
   */  
  task void ClockEventTask() {
    uint32_t remaining;
    if (millisecondsRemaining(&remaining) == FAIL) {
      sendUpdate(&remaining);
      return;
    }
    sendUpdate(&remaining);

    dbg(DBG_USR1, "VM: SynchTimerContext has %i ms remaining\n", remaining);
    if (remaining > SYNCH_TIMER_PADDING && remaining <= lastRemaining) {
      lastRemaining = remaining;
      submitted = FALSE;
      rescheduleTimer(&remaining);
    }
    else {
      /* WARNING: Due to a problem with the timer, we need to set a bit
       * here to prevent it from firing out of control.
       */
      if(submitted) {
	return;
      }
      submitted = TRUE;

      lastRemaining = intervalMilliseconds;

      resetTimer();
      if (timerContext.state == MATE_STATE_HALT) {
	count++;
	dbg(DBG_USR1, "VM: Synch timer context running.\n");
	call Synch.initializeContext(&timerContext);
	call Synch.resumeContext(&timerContext, &timerContext);
	notHaltedCounter = 0;
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, "VM: Synch timer context cannot run, it isn't halted.\n");
	/* WARNING: Occasionally the context will get stuck (possibly
	 * something weird in the InternalFlash). Assuming you are setting
	 * timer rates at 5+ min, contexts should never run for that long.
	 * Therefore if something happens here, we shoot the context and hope
	 * it recovers gracefully.
	 */
	// doesn't really work though :(
	//call Synch.haltContext(&timerContext);
	notHaltedCounter++;
	if (notHaltedCounter >= MAX_OCCURANCES_OF_NO_HALT) {
	  signal EngineControl.reboot();
	  notHaltedCounter = 0;
	}
      }
    }
  }

  /*
   * The following functions are used to initialize Mate information. See
   * http://www.cs.berkeley.edu/~pal/mate-web for more details about this.
   */
  command result_t StdControl.init() {
    result_t rval = call SubControlTimer.init();
    timerContext.which = MATE_CONTEXT_SYNCHTIMER;
    timerContext.rootHandler = MATE_HANDLER_SYNCHTIMER; 
    rval &= call HandlerStore.initializeHandler();
    call Synch.initializeContext(&timerContext);
    return rval;
  }

  command result_t StdControl.start() {
    call SubControlTimer.start();
    resetTimer();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call TimerMilli.stop();
    return call SubControlTimer.stop();
  }

  event void HandlerStore.handlerChanged() {
    dbg(DBG_USR3, "SynchTimerContext: Handler changed.\n");
    if (timerContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&timerContext);
    }
  }

  event void EngineStatus.rebooted() {
    dbg(DBG_USR1, "SynchTimerContext: VM rebooted.\n");
    if (timerContext.state != MATE_STATE_HALT) {
      call Synch.haltContext(&timerContext);
    }
  } 

  /*
   * When the clock timers, schedule a task because it's not super high
   * priority. For information about tasks, see the NesC documentation.
   */
  event result_t TimerMilli.fired() {
    post ClockEventTask();
    return SUCCESS;
  }

  /*
   * Pull off the variables and compute it into milliseconds using some
   * fancy math. Typecheck to make sure these are integers.
   */ 
  command result_t StartTimer.execute(uint8_t instr, MateContext* context) {
    uint32_t timeVal = 0;
    uint32_t minVal = 0;
    uint32_t secVal = 0;
    MateStackVariable* sec = call Stacks.popOperand(context);
    MateStackVariable* min = call Stacks.popOperand(context);
    if (!call TypeCheck.checkInteger(context, sec) ||
	!call TypeCheck.checkInteger(context, min)) {
      return FAIL;
    }
    //    timeVal = min->value.var;
    //    timeVal *= 60;
    //    timeVal += sec->value.var;
    //    timeVal *= 1000;

    //timeVal = ((min->value.var * 60) * 1000) + (1000 * sec->value.var);

    // WARNING: We use this form because the previous two, although
    //   mathematically correct, can't be compiled properly.
    minVal = min->value.var;
    minVal = minVal * 60;
    minVal = minVal * 1000;
    secVal = sec->value.var;
    secVal = secVal * 1000;
    timeVal = minVal + secVal;

    newstart = TRUE;
    setInterval(timeVal);
    resetTimer();
    dbg(DBG_USR1, "VM (%i): Setting SynchTimer interval to %i:%i (%i)\n", (int)context->which, (int)min->value.var, (int)sec->value.var, timeVal);
  }

  command result_t StopTimer.execute(uint8_t instr, MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Halting SynchTimer interval.\n" (int)context->which);
    setInterval(0);
    timerRate = 0;
    call TimerMilli.stop();
    return SUCCESS;
  }

  command result_t DumpState.execute(uint8_t instr, MateContext* context) {
    uint32_t remaining;
    millisecondsRemaining(&remaining);
    sendUpdate(&remaining);
    return SUCCESS;
  }
  
  command result_t StopTimer.byteLength() {return 1;}
  command result_t StartTimer.byteLength() {return 1;}
  command result_t DumpState.byteLength() {return 1;}
    
}
