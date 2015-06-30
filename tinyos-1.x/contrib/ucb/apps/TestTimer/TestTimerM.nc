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

/* Authors:		Su Ping, ported to nesC by Sam Madden
 * Date last modified:  
 */
/*
Expected Behavior:

Time:              Event:                 Timer:
100 ms             RED light on           0    It toggles every 100ms forever
200 ms             Green Light On         3
1s                 Yellow Light On        1
2s                 Y off, G off           1,2
3s                 Y on                   1
4s                 Y off, G on            1,2
5s                 Y on                   1
6s                 Y off, G off           1,2
7s                 Y on                   1
8s                 Y off                  1
9s                 Y on                   1
10s                Y off                  1
10.5s              R on                   0
11s                R off                  0
11.5s              R on                   0
11.6s              R off                  0
11.7s              R on                   0
11.8s              R off                  0
...
(Timer 0 repeats every 100ms forever)

 *
 */


/** 
 * Implementation for TestTimer module. 
 **/ 

module TestTimerM {
    uses {
        interface StdControl as TimerControl;
	interface Leds;
	interface Timer as Timer0;
	interface Timer as Timer1;
	interface Timer as Timer2;
	interface Timer as Timer3;
    }
    provides interface StdControl;
}

implementation {
    long counter1;
    long counter2;

/** 
 *  module Initialization. Turn all the LEDs off and initlize module variables
 **/

    command result_t StdControl.init(){
    	call Leds.init();
    	call TimerControl.init();
    	// init counters
    	//atomic {
    	    counter1=14;
    	    counter2=14;
    	//}    
    	return SUCCESS;
    }
 /**
  * start 4 timers: a one shot timer fires at 100 ms ater it is started, 
  * a repeat timer, which fires every 1000 ms
  * another repeat timer, which fires every 2000 ms
  * and 1 single-shot timer at 200 ms
  * @return Always return <code>SUCCESS</code>
  **/ 
    command result_t StdControl.start() {
	call TimerControl.start();
	call Timer0.start(TIMER_REPEAT, 30);
	call Timer1.start(TIMER_REPEAT, 1000);
        //call Timer1.start(TIMER_ONE_SHOT, 100);
    	call Timer2.start(TIMER_REPEAT, 3000);
        //call Timer3.start(TIMER_ONE_SHOT, 200);

	return SUCCESS;
  }

/** 
 *  Stop all timers
 *  @return Always return <code>SUCCESS</code>
 **/
    command result_t StdControl.stop() {
	call Timer0.stop();
	call Timer1.stop();
	call Timer2.stop();
	call Timer3.stop();
	return SUCCESS;
    }

/** 
 *  Timer0 Event Handler 
 *  Toggle red LED . 
 *  @return Alway return <code>SUCCESS</code>
 **/

    event result_t Timer0.fired() {
    	dbg(DBG_USR1, "TestTimer: timer0 evet \n");
    	call Leds.redToggle();
    	return SUCCESS;	
    }

/** 
  * Timer1 event handler : timer 1 is a repeat timer
  * Toggle yellow LED . decrement counter1
  * if counter1 is 0, stop the timer
  * @return Always return <code>SUCCESS</code>
  **/
    event result_t Timer1.fired() {
	//bool temp, stop = FALSE;
    	call Leds.yellowToggle();
    	dbg(DBG_USR1, "TestTimer: timer1 evet \n");
/**
	//atomic {
        temp = TOSH_interrupt_disable();
    	counter1--;
    	if (!counter1) stop = TRUE;
	if (temp) TOSH_interrupt_enable();
	if (stop) {
      	    call Timer1.stop();
    	}
**/
    	return SUCCESS;
    }

/** 
  * Timer2 event handler : timer 2 is a repeat timer
  * It toggles GREEN LED, decrement counter2
  * When counter2 becomes 0, stop the timer
  * @return Always return <code>SUCCESS</code>
  **/
    event result_t Timer2.fired() {
	bool temp , stop=FALSE;
    	call Leds.greenToggle();
    	dbg(DBG_USR1, "TestTimer: timer2 evet \n");
/**
        //atomic {
	temp = TOSH_interrupt_disable();
    	counter2--;
    	if (!counter2) stop = TRUE;
        if (temp) TOSH_interrupt_enable();

  	if (stop) {
      	    call Timer2.stop();
	}
*/
    	return SUCCESS;
}

/**  
  * Timer3 event handler : timer 3 is a one-shot timer
  * Toggle Green LED . 
  * @return Always return <code>SUCCESS</code>
  **/
    event result_t Timer3.fired() {
    	call Leds.greenToggle();
	dbg(DBG_USR1, "TestTimer: timer3 evet \n");
    	return SUCCESS;

    }

  
}
