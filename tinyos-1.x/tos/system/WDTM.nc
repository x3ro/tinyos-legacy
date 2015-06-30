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

/* The WDTM module implements the watchdog service for TinyOS.  It currently
   provides a single watchdog operating at fairly large scales -- from .5 to
   2M seconds, and it provides a single watchdog.   The watchdog has the
   standard semantics:  unless a component resets the watchdog within a
   specified period, the watchdog will reboot the mote.  Current
   implementation catches the application problems as well as some of the
   possible underlying Timer or task bugs. Additional work will be
   required to turn this into multiclient component, but that will happen in
   the near future. 

   .5 second latency is fairly arbitrary -- it ultimately boils down to power
   consumption devoted to kicking the HW watchdog.  Depending on the app
   characteristics, it can be extended up to 4 seconds, or shortened to a few
   ms.

*/

module WDTM {
    provides interface StdControl;
    provides interface WDT;
    uses command void reset();
    uses interface StdControl as TimerControl;
    uses interface StdControl as WDTControl;
    uses interface Timer;
}

implementation {
    int32_t increment;
    int32_t remaining;

    enum {
	WDT_LATENCY = 500 // note that the HW watchdog is set to expire every
			  // second; to be safe, we should kick it at least
			  // twice  per expiration period
    };

    command result_t StdControl.init() {
	result_t ok1 = call TimerControl.init();
	result_t ok2 = call WDTControl.init();
	increment = 0; remaining = 1;
	return rcombine(ok1, ok2);
    }

    command result_t StdControl.start() {
	result_t ok1 = call TimerControl.start();
	result_t ok2 = call Timer.start(TIMER_REPEAT, WDT_LATENCY);
	if (rcombine(ok1, ok2) == SUCCESS) {
	    return call WDTControl.start();
	}
	return FAIL;
    }

    command result_t StdControl.stop() {
	increment = 0;
	return call WDTControl.stop();
    }

    event result_t Timer.fired() {
	if (increment != 0) { // Watchdog is active
	    atomic {
		remaining = remaining - WDT_LATENCY;
	    }
	}
	if (remaining > 0) // the time has not yet passed. kick the dog
	    call reset();
	return SUCCESS;
    }

    // for starters, only one watchdog per node, settable only once
    command result_t WDT.start(int32_t interval) {
	if (increment == 0) {
	    increment = interval;
	    remaining = increment;
	    return SUCCESS;
	}
	return FAIL;
    }

    command void WDT.reset() {
	atomic {
	    remaining = increment;
	}
    }

}
