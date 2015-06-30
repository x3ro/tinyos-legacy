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

/* Authors:		Su Ping
 * Date last modified:  3/26/2003
 */

/** expected behavior:
 *  Yellow light toggles every 500 ms 
 *  Green LED toggles every 5 seconds
 *  At t=5 seconds, Red led starts to toggle every 40 ms
 **/    


/** 
 * Implementation for TestTimer module. 
 **/ 

module TestTimerAndRadioM {
	uses {
	  interface StdControl as TimerControl;
	  interface Leds;
	  interface Timer as Timer1;
	  interface Timer as Timer3;
	  interface Timer as Timer2;
	  interface SendMsg as Send;
	}

	provides interface StdControl;
}

implementation {
  long counter1;
  long counter2;
  TOS_Msg routeMsg;
/** 
 *  module Initialization. Turn all the LEDs off and initlize module variables
 **/

  command result_t StdControl.init(){
    call Leds.init();
    // init counters
    counter1=10;
    counter2=3;
    
  // start a few timers
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
    call Timer1.start(TIMER_REPEAT, 500);
    call Send.send(TOS_BCAST_ADDR, 4, &routeMsg);
    return SUCCESS;
  }

/** 
 *  Stop all timers
 *  @return Always return <code>SUCCESS</code>
 **/
  command result_t StdControl.stop() {
    call Timer1.stop();
    return SUCCESS;
  }


/** 
  * Timer1 event handler : timer 1 is a repeat timer
  * Toggle yellow LED . decrement counter1
  * if counter1 is 0, stop the timer
  * @return Always return <code>SUCCESS</code>
  **/
  event result_t Timer1.fired() {
    call Leds.yellowToggle();
    counter1 = (counter1 + 1) % 10;
    if (counter1 == 0) {
      call Timer3.start(TIMER_ONE_SHOT, 50);
    }

    return SUCCESS;
  }

  event result_t Timer2.fired() {
    call Leds.redToggle();
    call Send.send(TOS_BCAST_ADDR, 4, &routeMsg);
    return SUCCESS;
  }
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    call Timer2.start(TIMER_ONE_SHOT, 40);
  }

/**  
  * Timer3 event handler : timer 3 is a one-shot timer
  * Toggle Green LED . 
  * @return Always return <code>SUCCESS</code>
  **/
  event result_t Timer3.fired() {
    call Leds.greenToggle();
    return SUCCESS;
    
  }

  
}
