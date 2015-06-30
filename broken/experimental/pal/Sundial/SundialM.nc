/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Authors:  Philip Levis
 * Date:     2/19/2003
 */


module SundialM {
  provides interface PhasedTimer[uint8_t id];
  provides interface StdControl;
  uses {
    interface Leds;
    interface Clock;
  }
}

implementation {

  struct SundialEntry;
  
  typedef struct SundialEntry {
    struct SundialEntry* next;
    uint32_t interval; // If zero, timer not active
    uint32_t timeAfterPrev;     // List-relative; ms after previous timer
    PhasedTimerType type;
  } SundialEntry;

  typedef enum {
    CLOCK_1024 = 3,
    CLOCK_512 =  4,
    CLOCK_256 =  5,
    CLOCK_128 =  6,
    CLOCK_32  =  7,
  } ClockRate;

  uint8_t scaling[8];
  
  SundialEntry timers[NUM_PHASED_TIMERS];
  SundialEntry* nextTimer;

  uint32_t clockTicksSinceLast;
  uint32_t clockFiresToNextTimer;
  uint32_t clockTicksOnNextFire;
  
  ClockRate clockRate;
  
  /*
   * Return how much time has elapsed since the last timer.
   * This currently just reads the clock value, could
   * readily use time synchronization instead.
   */
  uint32_t getTimeSinceLastTimer() {
#if !defined(PLATFORM_PC)
    uint32_t counter = call Clock.readCounter();
#else
    uint32_t counter = 0;
#endif
    counter = counter << scaling[clockRate];
    return clockTicksSinceLast + counter;
  }

  result_t recalibrateClock() {
    uint32_t timeToNext = nextTimer->timeAfterPrev;
    timeToNext -= getTimeSinceLastTimer();
    dbg(DBG_TEMP, "SUNDIAL: Recalibrating clock to %u.\n", timeToNext);
    if (timeToNext < 256) {
      clockFiresToNextTimer = 1;
      clockTicksOnNextFire = timeToNext;
      call Clock.setRate(timeToNext, CLOCK_1024);
    }
    else if (timeToNext < 512) {
      clockFiresToNextTimer = 1;
      clockTicksOnNextFire = timeToNext;
      call Clock.setRate((timeToNext >> 1), CLOCK_512);
    }
    else if (timeToNext < 1024) {
      clockFiresToNextTimer = 1;
      clockTicksOnNextFire = timeToNext;
      call Clock.setRate((char)(timeToNext >> 2), CLOCK_256);
    }
    else if (timeToNext < 2048) {
      clockFiresToNextTimer = 1;
      clockTicksOnNextFire = timeToNext;
      call Clock.setRate((char)(timeToNext >> 3), CLOCK_128);
    }
    else if (timeToNext < 8196) {
      clockFiresToNextTimer = 1;
      clockTicksOnNextFire = timeToNext;
      call Clock.setRate((char)(timeToNext >> 5), CLOCK_32);
    }
    else {
      clockFiresToNextTimer = (timeToNext / 4096) + 1;
      clockTicksOnNextFire = 4096;
      call Clock.setRate((char)128, CLOCK_32);
    }
    return SUCCESS;
  }
  
  /*
   * Returns the SundialEntry that precedes the passed time.
   * entryTime tells you when in the future that timer happens
   */
  
  result_t insertTimer(SundialEntry* timer, uint32_t when) {
    SundialEntry* entry = nextTimer;
    SundialEntry* prevTimer = NULL;
    uint32_t entryTimeFromNow = 0; // How far in the future "entry" is
    uint32_t prevTimeFromNow = 0;

    dbg(DBG_TEMP, "SUNDIAL: Inserting a timer for %u\n", when);
    if (entry == NULL) {
      timer->timeAfterPrev = when;
      nextTimer = timer; // Well, that was easy
    }
    else {
      // First timer special case; necessary because its
      // timeAfterPrev value is inaccurate, as it does not consider
      // time passed since last timer
      uint32_t timeElapsed = getTimeSinceLastTimer();
      entryTimeFromNow += entry->timeAfterPrev;
      entryTimeFromNow -= timeElapsed;
      
      if (when <= entryTimeFromNow) {
	SundialEntry* tmp = entry;
	dbg_clear(DBG_TEMP, "  before first timer, twiddle numbers some\n");
	nextTimer = timer;
	timer->timeAfterPrev = when;
	timer->next = tmp;
	tmp->timeAfterPrev = (entryTimeFromNow - when);
      }
      else {
	dbg_clear(DBG_TEMP, "  looking for straddling timers");
	// Find the two timers that would straddle this timer
	// (prevTimer, timer, entry)
	while ((entry != NULL) && (entryTimeFromNow < when)) {
	  dbg_clear(DBG_TEMP, ".");
	  prevTimeFromNow = entryTimeFromNow;
	  prevTimer = entry;
	  entry = entry->next;
	  if (entry != NULL) {
	    entryTimeFromNow += entry->timeAfterPrev;
	  }
	}
	if (entry != NULL) {
	  dbg_clear(DBG_TEMP, "\n  found them: (%u, ... , %u)\n", prevTimeFromNow, entryTimeFromNow);
	}
	else {
	  dbg_clear(DBG_TEMP, "\n  found them: (%u, ... , infinity)\n", prevTimeFromNow);
	}
	// Insert the new timer, adjusting the time of the later
	// to be relative to the new one
	prevTimer->next = timer;
	timer->timeAfterPrev = (when - prevTimeFromNow);
	timer->next = entry;
	dbg_clear(DBG_TEMP, "  timer inserted.\n");
	if (entry != NULL) {
	  entry->timeAfterPrev -= timer->timeAfterPrev;
	}
      }
    }

    if (nextTimer == timer) {
      recalibrateClock();
    }
    return SUCCESS;
  }
  
  command result_t StdControl.init() {
    int i;
    result_t result = SUCCESS;
    dbg(DBG_BOOT, "SUNDIAL: Initializing.\n");
    nextTimer = NULL;
    clockFiresToNextTimer = 0;
    clockTicksOnNextFire = 0;
    clockTicksSinceLast = 0;
    for (i = 0; i < NUM_PHASED_TIMERS; i++) {
      timers[i].interval = 0;
    }

    scaling[0] = 0;
    scaling[1] = 0;
    scaling[2] = 0;
    scaling[3] = 0;
    scaling[4] = 1;
    scaling[5] = 2;
    scaling[6] = 3;
    scaling[7] = 5;

    call Clock.setRate(TOS_I0PS, TOS_S0PS);
    return result;
  }
  
  command result_t StdControl.start() {
    result_t result = SUCCESS;
    dbg(DBG_BOOT, "SUNDIAL: Initializing.\n");
    return result;
  }
  
  command result_t StdControl.stop() {
    result_t result = SUCCESS;
    dbg(DBG_BOOT, "SUNDIAL: Initializing.\n");
    return result;
  }

  command result_t PhasedTimer.start[uint8_t id](PhasedTimerType type, uint32_t interval, uint32_t phase) {
    uint32_t timeToFirst;
    result_t result;

    dbg(DBG_TEMP, "SUNDIAL: Starting Timer %i, as %s, with interval %u and phase %u.\n", (int)id, (type == TIMER_ONE_SHOT)?"one-shot":"repeating", interval, phase);
    
    if (id >= NUM_PHASED_TIMERS) {return FAIL;} // No such timer
    if (timers[id].interval != 0) {return FAIL;} // Timer already running

    timers[id].type = type;
    timers[id].interval = interval;
    timeToFirst = interval + phase;
    
    result = insertTimer(&timers[id], timeToFirst);
    return result;
  }

  command result_t PhasedTimer.stop[uint8_t id]() {
    if (id >= NUM_PHASED_TIMERS) {return FAIL;}
    return FAIL;
  }

  task void TimerTask() {
    SundialEntry* timer = nextTimer;
    uint8_t id = (timer - timers);
    
    dbg(DBG_TEMP, "SUNDIAL: Timer 0x%x - 0x%x / %i = %i\n", timer, timers, sizeof(SundialEntry), (int)id);
    nextTimer = timer->next;
    clockTicksSinceLast = 0;
    if (nextTimer->timeAfterPrev == 0) {
      dbg(DBG_TEMP, "SUNDIAL: Identical timers, pause clock and re-post.\n");
      call Clock.setRate(TOS_I0PS, TOS_S0PS);
      post TimerTask();
    }
    else {
      recalibrateClock();
    }
    if (timer->type == TIMER_REPEAT) {
      insertTimer(timer, timer->interval);
    }
    dbg(DBG_TEMP, "SUNDIAL: Firing timer %i.\n", (int)id);
    signal PhasedTimer.fired[id]();
  }
  
  event result_t Clock.fire() {
    dbg(DBG_TEMP, "SUNDIAL: Clock fired, enqueuing TimerTask.\n");
    // need an atomic section here
    clockFiresToNextTimer--;
    clockTicksSinceLast += clockTicksOnNextFire;
    if (clockFiresToNextTimer == 0) {
      call Clock.setRate(TOS_I0PS, TOS_S0PS);
      post TimerTask();
    }
    return SUCCESS;
  }

  default event result_t PhasedTimer.fired[uint8_t id]() {
    return SUCCESS;
  }
  
}
