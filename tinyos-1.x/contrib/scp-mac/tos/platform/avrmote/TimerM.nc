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
 * This timer component has a resolution of 1ms. It is based on the
 * asynchronous counter 0 (8-bit). The timer provides a 32-bit system time
 * as well as normal timer functions. It supports CPU deep sleep mode when
 * there is no scheduled timer events.
 */
 
module TimerM
{
  provides {
    interface StdControl as TimerControl;
    interface Timer[uint8_t id];
    interface TimerAsync[uint8_t id];
  }
  
  uses {
    interface StdControl as TimeControl;
    interface GetSetU32 as LocalTime;
    interface GetSetU8 as CntrValue;
    interface Cntr8bCompInt as CntrCompInt;
    interface UartDebug;
  }
}

implementation
{
#include "timerEvents.h"

// The following constants are specific to AVR MCU
// There's a hardware delay of 1 clock cycle on setting compare interrupt
#define COMP_INT_DELAY 1
// There's a compare interrupt block time of 1 clock cycle when TCNT0 is written
#define START_UP_DELAY 1

  // bit positions for flags in the status byte
  // bit 0 indicates whether the timer has just fired
  // bit 1 indicates if use async signal when firing
  enum {FIRED = 0, ASYNC = 1};

  typedef struct {
    uint8_t status;  // different bits for different flags
    uint32_t remainingTime;  // the remaning time to fire in miliseconds
    uint32_t period;  // the period of the timer in miliseconds
  } timer_t;
  
  timer_t timer[TIMER_NUM_TIMERS];  // TIMER_NUM_TIMERS < 255
  uint8_t numActive;  // number of active timers
  uint32_t decrement;  // the value to decrement from all timers
  uint8_t timeInt;  // time when compare interrupt happens or first timer starts
  uint8_t compRegVal;  // compare register value
  uint8_t togglePin;
  uint8_t togglePin2;
  uint8_t eventdetected;
  uint32_t time1;
  uint32_t time2;
  uint32_t previousdecrement;
  
  // bit manipulation functions
  
  inline uint8_t setBit(uint8_t byte, uint8_t bitPosition)
  {
    // set a bit in a byte, bitPosition is from 0 to 8
    return (byte | (0x01 << bitPosition));
  }
  
  inline uint8_t clearBit(uint8_t byte, uint8_t bitPosition)
  {
    // clear a bit in a byte, bitPosition is from 0 to 8
    return (byte & (~(0x01 << bitPosition)));
  }
  
  inline uint8_t isBitSet(uint8_t byte, uint8_t bitPosition)
  {
    // check if a but is set in a byte, bitPosition is from 0 to 8
    // return 0 if not set, and 1 if set
    return ((byte >> bitPosition) & 0x01);
  }


  command result_t TimerControl.init()
  {
    // initialize timer component
    
    numActive = 0;
    call TimeControl.init(); // initialize hardware counter (via LocalTime)
    call UartDebug.init(); // initialize UART debugging
    return SUCCESS;
  }


  command result_t TimerControl.start()
  {
    // start timer component
    
    uint8_t i;
    for (i = 0; i < TIMER_NUM_TIMERS; i++) {
       timer[i].remainingTime = 0;
    }
    togglePin = 1;
    togglePin2 = 1;
    eventdetected = 0 ;
    time1 = 0;
    time2 = 0;
    previousdecrement  = 0;
    call TimeControl.start(); // start counter for local time
    call Timer.start[TIMER_NUM_TIMERS - 1](TIMER_ONE_SHOT, 2);  // dummy timer
    return SUCCESS;
  }


  command result_t TimerControl.stop()
  {
    // stop all timers, and disable output compare interrupt

    uint8_t i;
    call CntrCompInt.disable(); // disable interrupt
    for (i = 0; i < TIMER_NUM_TIMERS; i++) {
       timer[i].remainingTime = 0;
    }
    numActive = 0;
    return SUCCESS;
  }


  void adjustRemainingTime(uint8_t id, uint32_t interval)
  {
    // Called when start a new timer or changing the remaining time of a
    // running timer. It adjusts remaining time of timer[id] to be relative
    // to the time of last interrupt instead of now. Maybe need to reset 
    // compare register.

    uint8_t timeNow;  // current counter value
    uint8_t timeElapse;  // elapsed time since last interrupt
    
    atomic {  // prevenet races by output compare interrupt
      // calculate elapsed time since last interrupt or first timer starts
      timeNow = call CntrValue.get();  // get current counter value
      if (timeNow < timeInt) {  // needs to take care of counter wrap around
        timeElapse = (255 - timeInt) + timeNow + 1;
      } else {
        timeElapse = timeNow - timeInt;
      }
      // adjust remaining time to be relative to last interrupt time
      timer[id].remainingTime = interval + timeElapse;
      // check if need to reset compare register
      if (timer[id].remainingTime < decrement) {  // max decrement value is 256
        // need to reset compare register to a nearer time
        decrement = timer[id].remainingTime;
        compRegVal = timeInt + (uint8_t)decrement - COMP_INT_DELAY;
        call CntrCompInt.setCompReg(compRegVal);
      }
    }
  }


  command result_t Timer.start[uint8_t id](uint8_t type, uint32_t interval)
  {
    // start a timer that will generate a firing signal in a task
    // one-shot timer is a special case of periodic timer with zero period
    
    if (id >= TIMER_NUM_TIMERS) return FAIL;
    
    // can't start timer that is shorter than hardware delay
    if (interval <= COMP_INT_DELAY) interval = COMP_INT_DELAY + 1;

    //call UartDebug.txByte(TIMER_NUM_TIMERS);
    //call UartDebug.txByte(numActive);
    //call UartDebug.txByte(id);
    
    // add the new timer
    if (type == TIMER_ONE_SHOT) {
       timer[id].period = 0;
    } else if (type == TIMER_REPEAT) {
       timer[id].period = interval;
    } else {
       return FAIL;  // unknown type
    }
    // if hardware counter just started, there is a delay for first interrupt
    if (call LocalTime.get() == 0 && interval <= START_UP_DELAY)
      interval = START_UP_DELAY + 1;
    timer[id].status = clearBit(timer[id].status, FIRED); // not fired yet
    timer[id].status = clearBit(timer[id].status, ASYNC); // not async firing

    // check if this is the first timer to start
    if (numActive == 0) {  // no active timer and interrupt is disabled
      // just start the new timer      
      numActive = 1;  // increase number of active timers
      timer[id].remainingTime = interval;
      timeInt = call CntrValue.get();  // record current time
//      call UartDebug.txByte(timeInt);
      if (timer[id].remainingTime < 256) {
        decrement = timer[id].remainingTime;
        compRegVal = timeInt + (uint8_t)decrement - COMP_INT_DELAY;
      } else {
        // next interrupt will take 256 ticks
        decrement = 256;
        compRegVal = timeInt - COMP_INT_DELAY;
      }
      call CntrCompInt.setCompReg(compRegVal);
      call CntrCompInt.enable();  // enable interrupt after everything is done
    } else {  // has running timers
      numActive++;  // increase number of active timers
      // adjust remaining time to be relative to last interrupt time
      adjustRemainingTime(id, interval);
    }
    call UartDebug.txEvent(NEW_TIMER_STARTED);
    //call UartDebug.txByte(numActive);
/*
    call UartDebug.txByte((uint8_t)(timer[id].remainingTime & 0xff));
    call UartDebug.txByte((uint8_t)((timer[id].remainingTime >> 8) & 0xff));
    call UartDebug.txByte((uint8_t)((timer[id].remainingTime >> 16) & 0xff));
    call UartDebug.txByte((uint8_t)((timer[id].remainingTime >> 24) & 0xff));
    call UartDebug.txByte(decrement);
    call UartDebug.txByte(compRegVal);
*/
    return SUCCESS;
  }


  command result_t Timer.stop[uint8_t id]()
  {
    // stop a running timer immediately

    if (id >= TIMER_NUM_TIMERS) return FAIL;
    if (timer[id].remainingTime == 0) return FAIL;
    call UartDebug.txEvent(ONE_TIMER_STOPPED);
    atomic {
      timer[id].remainingTime = 0;
      numActive--;
      if (numActive == 0) {  // no running timer
        call CntrCompInt.disable(); // disable interrupt
        call UartDebug.txEvent(ALL_TIMERS_STOPPED);
      }
    }
    // call UartDebug.txByte(numActive);
    return SUCCESS;
  }


  command uint32_t Timer.getRemainingTime[uint8_t id]()
  {
    // get the remaining time of a timer

    uint8_t timeNow;  // current counter value
    uint32_t remainingTime;
    
    if (id >= TIMER_NUM_TIMERS) return FAIL;
    
    // calculate elapsed time since last interrupt or first timer starts
    atomic {
      if (timer[id].remainingTime == 0) {  // timer stopped
        remainingTime = 0;
      } else {
        timeNow = call CntrValue.get();  // get current counter value
        if (timeNow < timeInt) {  // needs to take care of counter wrap around
          //  timeElapse = (255 - timeInt) + timeNow + 1;
          remainingTime = timer[id].remainingTime + timeInt - timeNow - 256;
        } else if (timeNow > timeInt) {
          //  timeElapse = timeNow - timeInt;
          remainingTime = timer[id].remainingTime + timeInt - timeNow;
        } else {  // timeNow == timeInt
          if (bit_is_set(TIFR, OCF0)) {
            // interrupt just occurred, but has not been handled yet
            remainingTime = timer[id].remainingTime - decrement;
          } else {
            remainingTime = timer[id].remainingTime;
          }
        }
      }
    }
/*
    call UartDebug.txByte(timeInt);
    call UartDebug.txByte(timeNow);
    call UartDebug.txByte((uint8_t)(remainingTime & 0xff));
    call UartDebug.txByte((uint8_t)((remainingTime >> 8) & 0xff));
    call UartDebug.txByte((uint8_t)((remainingTime >> 16) & 0xff));
    call UartDebug.txByte((uint8_t)((remainingTime >> 24) & 0xff));
*/
    return remainingTime;
  }


  command result_t Timer.setRemainingTime[uint8_t id](uint32_t time)
  {
    // Set the remaining time of a running timer before its next firing.
    // Will fail on a timer that is not running -- use Timer.start() instead.
    // Will fail if time is 0 -- use Timer.stop() to stop a timer
    
    if (id >= TIMER_NUM_TIMERS) return FAIL;
    if (timer[id].remainingTime == 0) return FAIL;
    if (time == 0) return FAIL;
    // can't set timer that is shorter than hardware delay
    if (time <= COMP_INT_DELAY) time = COMP_INT_DELAY + 1;
    // change time from relative to now to relative to last interrupt time
    adjustRemainingTime(id, time);
    call UartDebug.txEvent(ONE_TIMER_CHANGED_REMAINING_TIME);
    //call UartDebug.txByte(numActive);
    return SUCCESS;
  }


  command result_t TimerAsync.start[uint8_t id](uint8_t type, uint32_t interval)
  {
    // same as tasked timer, but with different type on async firing

    if (call Timer.start[id](type, interval)) {
      timer[id].status = setBit(timer[id].status, ASYNC);  // async firing
      return SUCCESS;
    }
    return FAIL;
  }


  command result_t TimerAsync.stop[uint8_t id]()
  {
    // the same as a tasked timer

    return call Timer.stop[id]();
  }


  command uint32_t TimerAsync.getRemainingTime[uint8_t id]()
  {
    // the same as a tasked timer
    
    return call Timer.getRemainingTime[id]();
  }


  command result_t TimerAsync.setRemainingTime[uint8_t id](uint32_t time)
  {
    // the same as a tasked timer

    return call Timer.setRemainingTime[id](time);
  }


  task void signalFiring()
  {
    // this task signals all fired timers
    
    uint8_t i;  // loop variable
    for (i = 0; i < TIMER_NUM_TIMERS; i++) {
      if (isBitSet(timer[i].status, FIRED) && 
          !isBitSet(timer[i].status, ASYNC)) {
        timer[i].status = clearBit(timer[i].status, FIRED);
        signal Timer.fired[i]();
        call UartDebug.txEvent(ONE_TASK_TIMER_FIRED);
      }
    }
  }


  async event void CntrCompInt.fire()
  {
    // handler for the output compare interrupt
    // global interrupt is disabled when this handler is called
    // decrement values in all active timers, and signal if any one fires

    uint8_t i, needTask; // temperary variables
    uint32_t nextFireTime = 0xffffffff; // next time to fire
    uint32_t time6;
    uint32_t diff;
    

    if(time1 == 0) {
       time1  = call LocalTime.get();
    } else {

      time6 = call LocalTime.get();
      if(time6 > time2) {
      time2  = time6;
     
      diff = time2 - time1;
      if((diff == decrement + previousdecrement + 256) && (time2 > time1) && (diff <= 280)) {
         eventdetected =  1;
         if(togglePin == 1) {
           TOSH_SET_PW3_PIN();
           togglePin = 0;
         } else {
           TOSH_CLR_PW3_PIN();
           togglePin = 1;
         }

      // call UartDebug.txByte((uint8_t)230);
      // call UartDebug.txByte((uint8_t)240);
       // call UartDebug.txByte((uint8_t)(time & 0xff));
       // call UartDebug.txByte((uint8_t)((time >> 8) & 0xff));
       // call UartDebug.txByte((uint8_t)((time >> 16) & 0xff));
       // call UartDebug.txByte((uint8_t)((time >> 24) & 0xff));

      }
      time1  = time2;
      previousdecrement = 0;
     } else {
       previousdecrement =  decrement;
     }
    }


    // update all running timers
    for (i = 0; i < TIMER_NUM_TIMERS; i++) {
      if (timer[i].remainingTime > 0) {
        timer[i].remainingTime -= decrement;

        if (eventdetected == 1) {
          if (timer[i].remainingTime > 256) {
            timer[i].remainingTime -= 256; 
          } else {
            timer[i].remainingTime = 0;
          }
        } 

        if (timer[i].remainingTime < COMP_INT_DELAY) {
          timer[i].remainingTime = 0;
          // set a flag to signal firing
          timer[i].status = setBit(timer[i].status, FIRED); // set fired flag
          if (timer[i].period > 0) {  // restart periodic timer
            timer[i].remainingTime = timer[i].period;
          } else {
            numActive--; // one shot time stopped
          }
        }
        // find the nearest time that next timer will fire
        if (timer[i].remainingTime > 0 && 
            timer[i].remainingTime < nextFireTime) {
          nextFireTime = timer[i].remainingTime;
        }
      }
    }

    eventdetected = 0;

    //call UartDebug.txByte(numActive);

    // prepare for next timer to be fired

    // record current counter value
    // don't read counter immediately after wakeup from sleep
    // since the value may be wrong
    timeInt = call CntrValue.get();
    
    if (numActive > 0) { // have active timers
      if (nextFireTime < 256) { // need to change compare register
        decrement = nextFireTime;
        compRegVal = timeInt + (uint8_t)decrement - COMP_INT_DELAY;
        call CntrCompInt.setCompReg(compRegVal);
      } else { // keep the register value and wait for another round
        decrement = 256;
      }
    } else {
      call CntrCompInt.disable(); // disable interrupt
      call UartDebug.txEvent(ALL_TIMERS_STOPPED);
    }
    
    __nesc_enable_interrupt();  // enable global interrupt
    
    // signal fired timers
    needTask = 0;
    for (i = 0; i < TIMER_NUM_TIMERS; i++) {
      if (isBitSet(timer[i].status, FIRED)) {  // timer fired
        // check type of firing
        if (isBitSet(timer[i].status, ASYNC)) {  // async firing
          timer[i].status = clearBit(timer[i].status, FIRED);
          signal TimerAsync.fired[i]();  // signal directly
          call UartDebug.txEvent(ONE_ASYNC_TIMER_FIRED);
        } else {  // normal firing
          needTask = 1;  // will post task later
        }
      }
    }
    
    // post a task for timers signaled by task
    if (needTask) {
      // post a task to signal all fired timers
      if (!post signalFiring()) { // if task queue is full
        call UartDebug.txEvent(TIMER_FIRED_TASK_QUEUE_FULL);
        decrement = COMP_INT_DELAY; // try again after 1 tick
        compRegVal = timeInt; // will interrupt at COMP_INT_DELAY time
        call CntrCompInt.setCompReg(compRegVal);
      }
    }
    
  }
    

  // default signal handlers
  
  default async event result_t TimerAsync.fired[uint8_t id]() {
    return SUCCESS;
  }


  default event result_t Timer.fired[uint8_t id]() {
    return SUCCESS;
  }

}
   
