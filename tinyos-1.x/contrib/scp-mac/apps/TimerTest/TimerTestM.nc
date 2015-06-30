/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * TimerTest tests the basic functions of the timer with CPU sleep
 */

module TimerTestM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as PhyControl;
    interface StdControl as TimerControl;
    interface Timer as TimerRepeat;  // single timer
    interface TimerAsync as TimerAsyncRepeat;
    interface Timer as TimerAry[uint8_t id];  // array of timers
    interface TimerAsync as TimerAsyncAry[uint8_t id];
    interface GetSetU32 as LocalTime;
    interface Random;
    interface Leds;
  }
}

implementation
{
#include "../tstUartDebug.h"

#define TIMER_NUM_UNIQUE_TIMERS uniqueCount("Timer")
#define MIN_TASK_ARRAY_ID TIMER_NUM_UNIQUE_TIMERS
#define MAX_TASK_ARRAY_ID (TIMER_NUM_UNIQUE_TIMERS + NUM_TASK_TIMERS - 1)
#define MIN_ASYNC_ARRAY_ID (TIMER_NUM_UNIQUE_TIMERS + NUM_TASK_TIMERS)
#define MAX_ASYNC_ARRAY_ID (MIN_ASYNC_ARRAY_ID + NUM_ASYNC_TIMERS - 1)

  typedef struct {
    uint32_t tNextFiring;
  } TimerVar;
  
  TimerVar timerAry[NUM_TASK_TIMERS];
  TimerVar timerAsyncAry[NUM_ASYNC_TIMERS];
  uint32_t tTimerRepeat;
  uint32_t tTimerAsyncRepeat;
  uint8_t numAryTimers;
  uint8_t numAsyncAryTimers;
  
  static inline uint32_t diff(uint32_t a, uint32_t b)
  {
    if (a >= b) return a - b;
    else return b - a;
  }

   command result_t StdControl.init()
   {
      call Leds.init();
      call PhyControl.init();
      call TimerControl.init();  // timer
      call Random.init(); // random number generator
      tstUartDebug_init();// initialize UART debugging
      return SUCCESS;
   }


  void startTimerAry()
  {
    // start the array of random one-shot timers
    // random time are from 1 -- 0x4000ms (16384ms)
    // random time are from 1 -- 0x2000ms (8192ms)
    
    uint8_t i;
    uint32_t interval;
    uint32_t now;
    
    now = call LocalTime.get(); // get current time
    numAryTimers = 0;
    for (i = 0; i < NUM_TASK_TIMERS; i++) {
      interval = (uint32_t)(call Random.rand() & 0x3ff) + 1; 
      if (call TimerAry.start[i + MIN_TASK_ARRAY_ID](TIMER_ONE_SHOT, interval)) {
        numAryTimers++;
        timerAry[i].tNextFiring = now + interval;  // remember firing time
      }
    }
  }


  void startAsyncTimerAry()
  {
    // start the array of random one-shot async timers
    // random time are from 1 -- 0x4000ms (16384ms)
    // random time are from 1 -- 0x2000ms (8192ms)
    
    uint8_t i;
    uint32_t interval;
    uint32_t now;
    
    now = call LocalTime.get(); // get current time
/*
      tstUartDebug_byte((uint8_t)(0x64));
      tstUartDebug_byte((uint8_t)(now & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 8) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 16) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 24) & 0xff));
*/
    numAsyncAryTimers = 0;
    for (i = 0; i < NUM_ASYNC_TIMERS; i++) {
      interval = (uint32_t)(call Random.rand() & 0x3ff) + 1;
      if (call TimerAsyncAry.start[i + MIN_ASYNC_ARRAY_ID](TIMER_ONE_SHOT, interval)) {
        numAsyncAryTimers++;
        timerAsyncAry[i].tNextFiring = now + interval;  // remember firing time
      }
    }
  }


   command result_t StdControl.start()
   {
      uint32_t now;
      
      call PhyControl.stop();  // stop radio
      call TimerControl.start();  // start timer
      
      now = call LocalTime.get(); // get current time
      
      // start two individual repeat timers first
//      if (call TimerRepeat.start(TIMER_REPEAT, TIMER_REPEAT_INTERVAL)) {
//        call Leds.yellowOn();
//      }
      if (call TimerAsyncRepeat.start(TIMER_REPEAT, TIMER_ASYNC_REPEAT_INTERVAL)) {
//        call Leds.greenOn();
      }
      // remember when they are going to fire
      tTimerRepeat = now + TIMER_REPEAT_INTERVAL;
      tTimerAsyncRepeat = now + TIMER_ASYNC_REPEAT_INTERVAL;
      
      // start the array of random short timers
      startTimerAry();
      startAsyncTimerAry();
      return SUCCESS;
   }


   command result_t StdControl.stop()
   {
      return SUCCESS;
   }


  event result_t TimerRepeat.fired()
  {
    // single repeat timer fired in task
    
    uint32_t now, timeDiff;
    
    now = call LocalTime.get();
    timeDiff = diff(tTimerRepeat, now);
    if (timeDiff <= 1) {
//      call Leds.yellowToggle();
    }
    tTimerRepeat = now + TIMER_REPEAT_INTERVAL;
    return SUCCESS;
  }


  async event result_t TimerAsyncRepeat.fired()
  {
    // single repeat timer fired asynchronous
    uint32_t now, timeDiff;
    
    now = call LocalTime.get();
    timeDiff = diff(tTimerAsyncRepeat, now);
    if (timeDiff < 1) {
      call Leds.greenToggle();
      tTimerAsyncRepeat = now + TIMER_ASYNC_REPEAT_INTERVAL;
    } else {
      // error happend
      call TimerAsyncRepeat.stop();
      tstUartDebug_byte(100);
      tstUartDebug_byte((uint8_t)(tTimerAsyncRepeat & 0xff));
      tstUartDebug_byte((uint8_t)((tTimerAsyncRepeat >> 8) & 0xff));
      tstUartDebug_byte((uint8_t)((tTimerAsyncRepeat >> 16) & 0xff));
      tstUartDebug_byte((uint8_t)((tTimerAsyncRepeat >> 24) & 0xff));
      tstUartDebug_byte((uint8_t)(now & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 8) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 16) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 24) & 0xff));
    }
    return SUCCESS;
  }
   

  event result_t TimerAry.fired[uint8_t id]()
  {
    // timer array fired in task

    uint32_t now, timeDiff;
    
    // if timer not in range, don't handle it
    if (id < MIN_TASK_ARRAY_ID || id > MAX_TASK_ARRAY_ID)
      return SUCCESS;
    
    //tstUartDebug_byte(id);

    now = call LocalTime.get();
    // check difference
    timeDiff = diff(timerAry[id - MIN_TASK_ARRAY_ID].tNextFiring, now);
    
    if (timeDiff <= 1) {
      numAryTimers--;
      if (numAryTimers == 0) {
        call Leds.redToggle();  // display the results
        // restart the array timers
        startTimerAry();
      }
    } else {
      tstUartDebug_byte(100);
      tstUartDebug_byte((uint8_t)
        (timerAsyncAry[id - MIN_TASK_ARRAY_ID].tNextFiring & 0xff));
      tstUartDebug_byte((uint8_t)
        ((timerAsyncAry[id - MIN_TASK_ARRAY_ID].tNextFiring >> 8) & 0xff));
      tstUartDebug_byte((uint8_t)
        ((timerAsyncAry[id - MIN_TASK_ARRAY_ID].tNextFiring >> 16) & 0xff));
      tstUartDebug_byte((uint8_t)
        ((timerAsyncAry[id - MIN_TASK_ARRAY_ID].tNextFiring >> 24) & 0xff));
      tstUartDebug_byte((uint8_t)(now & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 8) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 16) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 24) & 0xff));
    }
    return SUCCESS;
  }


  async event result_t TimerAsyncAry.fired[uint8_t id]()
  {
    // timer array fired in task
    
    uint32_t now, timeDiff;
    
    // if timer not in range, don't handle it
    if (id < MIN_ASYNC_ARRAY_ID || id > MAX_ASYNC_ARRAY_ID)
      return SUCCESS;
    
    //tstUartDebug_byte(id);

    now = call LocalTime.get();
    // check difference
    timeDiff = diff(timerAsyncAry[id - MIN_ASYNC_ARRAY_ID].tNextFiring, now);
    
    if (timeDiff <= 1) {
      numAsyncAryTimers--;
      if (numAsyncAryTimers == 0) {
        call Leds.yellowToggle();  // display the results
        // restart the array timers
        startAsyncTimerAry();
      }
    } else {
      tstUartDebug_byte(100);
      tstUartDebug_byte((uint8_t)
        (timerAsyncAry[id - MIN_ASYNC_ARRAY_ID].tNextFiring & 0xff));
      tstUartDebug_byte((uint8_t)
        ((timerAsyncAry[id - MIN_ASYNC_ARRAY_ID].tNextFiring >> 8) & 0xff));
      tstUartDebug_byte((uint8_t)
        ((timerAsyncAry[id - MIN_ASYNC_ARRAY_ID].tNextFiring >> 16) & 0xff));
      tstUartDebug_byte((uint8_t)
        ((timerAsyncAry[id - MIN_ASYNC_ARRAY_ID].tNextFiring >> 24) & 0xff));
      tstUartDebug_byte((uint8_t)(now & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 8) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 16) & 0xff));
      tstUartDebug_byte((uint8_t)((now >> 24) & 0xff));
    }
    return SUCCESS;
  }

}


