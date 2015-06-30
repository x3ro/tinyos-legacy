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


 * Modified by Mads Bondo Dydensborg, who was totally unable to grasp
 * the complicated schema below. Now simply fires 500 ms, 1 ms, 2 ms.
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

  /** 
   *  module Initialization. Turn all the LEDs off and initlize module variables
   **/
  
  command result_t StdControl.init(){
    call Leds.init();
    call TimerControl.init();
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
    call Timer0.start(TIMER_REPEAT, 500);
    call Timer1.start(TIMER_REPEAT, 2500);
    //call Timer1.start(TIMER_ONE_SHOT, 100);
    call Timer2.start(TIMER_REPEAT, 25);
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
    call Leds.greenToggle();
    dbg(DBG_USR1, "TestTimer: timer1 evet \n");
    return SUCCESS;
  }
  
  /** 
   * Timer2 event handler : timer 2 is a repeat timer
   * It toggles GREEN LED, decrement counter2
   * When counter2 becomes 0, stop the timer
   * @return Always return <code>SUCCESS</code>
   **/
  event result_t Timer2.fired() {
    call Leds.yellowToggle();
    dbg(DBG_USR1, "TestTimer: timer2 evet \n");
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
