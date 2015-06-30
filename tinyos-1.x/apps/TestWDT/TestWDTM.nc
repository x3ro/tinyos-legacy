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

module TestWDTM {
    provides interface StdControl;
    uses interface Leds;
    uses interface Timer;
    uses interface StdControl as TimerControl;
    uses interface StdControl as DogControl;
    uses interface WDT;
}

implementation { 
    
    enum {
	mode = WDTTEST
    };
    
    uint8_t firstTime;

    result_t command StdControl.init() {
        result_t ok1, ok2, ok3;
	firstTime = 1;
	ok1 = call DogControl.init();
        ok2 = call Leds.init();
        ok3 = call TimerControl.init();
	return rcombine3(ok1, ok2, ok3);
    }

    

    result_t command StdControl.start() {
	result_t ok = call TimerControl.start();
	call DogControl.start();
	if (ok) {
	    call Leds.redOn();
	    call Leds.greenOn();
	    if (mode == 1) {
		return call Timer.start(TIMER_ONE_SHOT, 2000);
	    } else {
		return call Timer.start(TIMER_REPEAT, 2000);
	    }
	} 
	return ok;
    }

    result_t command StdControl.stop() {
	call DogControl.stop();
	return call TimerControl.stop();
    }

    task void  crashMote() {
	while (1) {
	    call Leds.yellowOn();
	}
    }

    event result_t Timer.fired() {
	call Leds.greenOff();
	if (firstTime) {
	    firstTime = 0;
	    call WDT.start(2500);
	} else {
	    call WDT.reset();
	}
	if (mode == 2) {
	    post crashMote();
	}
	return SUCCESS;
    }

}
