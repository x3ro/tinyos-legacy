// $Id: TimerM.nc,v 1.1 2005/05/25 10:04:02 hjkoerber Exp $

/*								
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
 * Authors: Su Ping <sping@intel-research.net>
 * @author: Hans-Joerg Koerber 
 *          <hj.koerber@hsu-hh.de>
 *	    (+49)40-6541-2638/2627
 * 
 * $Date: 2005/05/25 10:04:02 $
 * $Revision: 1.1 $
 *
 */ 


// The underlying hardware clock runs with ticks = 1/32.768 us


module TimerM {
    provides interface Timer[uint8_t id];
    provides interface StdControl;
    uses {
	interface Leds;
	interface Clock;
        interface StdControl as ClockControl;  
    }
}
implementation {
 
  norace uint16_t minInterval;            // changed only during init or in interrupt context
    uint8_t Scale;

    norace uint32_t State;		  // each bit represent a timer state, changed only in  

    int8_t queue_head;
    int8_t queue_tail;
    uint8_t queue_size;
    uint8_t queue[NUM_TIMERS];
  
    norace struct timer_s {
        uint8_t type;		  // one-short or repeat timer
        int32_t ticks;		  // clock ticks for a repeat timer 
        int32_t ticksLeft;	  // ticks left before the timer expires
    } TimerList[NUM_TIMERS];      // norace 'cause we change this struct only in atomic statements or interrupt context
  
    enum {
      maxTimerInterval = 0xffff   // 16-bit overflow timer
    };
  
  command result_t StdControl.init() {
    State = 0;                    // now timer is active
    Scale = 0;                    // prescale value 1:1           
    minInterval = maxTimerInterval;
    queue_head = queue_tail = -1;
    queue_size = 0;
    call ClockControl.init();
    return call Clock.setRate(minInterval, Scale) ;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    State=0;
    minInterval = maxTimerInterval;
    return SUCCESS;
    }

    command result_t Timer.start[uint8_t id]( char type, 
				   uint32_t interval) {
	uint16_t CounterValue;
        uint16_t ticksCounted;
        uint8_t i;

        if (id >= NUM_TIMERS) return FAIL;
        if (type > TIMER_ONE_SHOT)  return FAIL;

	atomic {	
	 
	  TimerList[id].ticks = interval<<5 ;          //// one tick = 1/32.768us thus if we want an interval of 1/1.024 ms we have to count 1*32 ticks
	  TimerList[id].type = type;
	  TimerList[id].ticksLeft = interval<<5;
       
	  CounterValue = call Clock.readCounter();  
	  ticksCounted = minInterval-(maxTimerInterval-CounterValue);
	  minInterval = maxTimerInterval-CounterValue;
	  
	  if(State!=0){
	    for (i=0;i<NUM_TIMERS;i++){
	      if(State & (0x1<<i)){
		TimerList[i].ticksLeft -= ticksCounted;
	      }
	    }

	    if(TimerList[id].ticksLeft <= minInterval){
	      minInterval = TimerList[id].ticksLeft;
	    }
	 
	  }
	  else {
	    minInterval = TimerList[id].ticksLeft;
	  }
	
	  State|=(0x1<<id);

	  if(TimerList[id].ticksLeft > maxTimerInterval)
	    minInterval=maxTimerInterval;

	  call Clock.setInterval(minInterval);
	}
	return SUCCESS;
    }

 
    command result_t Timer.stop[uint8_t id]() {

      if (id>=NUM_TIMERS) return FAIL;
      if (State&(0x1<<id)) { // if the timer is running 
	atomic State &= ~(0x1<<id);	
	return SUCCESS;
      }
      return FAIL;          //timer not running
    }


    default event result_t Timer.fired[uint8_t id]() {
      return SUCCESS;
    }

    void enqueue(uint8_t value) {
      atomic{
	if (queue_tail == NUM_TIMERS - 1)
	  queue_tail = -1;
	queue_tail++;
	queue_size++;
	queue[(uint8_t)queue_tail] = value;
      }
    }

    uint8_t dequeue() {    
      if (queue_size == 0)
	return NUM_TIMERS;
      atomic{ 
	if (queue_head == NUM_TIMERS - 1)
	  queue_head = -1;
	queue_head++;
	queue_size--;
      }
      return queue[(uint8_t)queue_head];
    }

    task void signalOneTimer() {
      uint8_t itimer = dequeue();
      if (itimer < NUM_TIMERS)
        signal Timer.fired[itimer]();
    }



    async event result_t Clock.fire() {
      uint8_t i;       
      uint16_t newInterval;     
 
      if (State) {
	newInterval = maxTimerInterval;
	for (i=0;i<NUM_TIMERS;i++)  {
	  if (State&(0x1<<i)) {
	    if(overflow_flag){
	      TimerList[i].ticksLeft -= (lostTicks);
	    }
	    else{
	      TimerList[i].ticksLeft -= minInterval;	    
	    }
	    if(TimerList[i].ticksLeft<=0){
	      if (TimerList[i].type==TIMER_REPEAT) {
		TimerList[i].ticksLeft = TimerList[i].ticks;
	      }
	      else {//one shot timer
		State &=~(0x1<<i);
	      }
	      enqueue(i);	
	      post signalOneTimer();
	    }

	    if(TimerList[i].ticksLeft<=newInterval)
	      newInterval = TimerList[i].ticksLeft;
	  }	      
	}
	minInterval = newInterval;
	call Clock.setInterval(minInterval);
	}
	return SUCCESS;
    }
}


