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
 */
/**
 * Check TimerStampClockC.nc for documentation on overall functionality.
 * 
 * @author Phoebus Chen 
 * @modified 9/13/2004 First Implementation
 */

module TimeStampClockM {
  provides {
    interface StdControl;
    interface TimeStamp;
    interface ConfigTimeStamp;
  }
  uses {
    interface StdControl as TimerControl;
    interface Timer;
  }
}

implementation {
  enum {
    DEFAULT_TIMESTAMPCLOCK_FIRE_INTERVAL = 25,
    COUNTER_END = 0xffffffff,
    COUNTER_HALF = 0x7fffffff,
  };

  uint32_t clockCounter;
  uint32_t clockFireInterval;



  command result_t StdControl.init() {
    clockCounter = 0;
    clockFireInterval = DEFAULT_TIMESTAMPCLOCK_FIRE_INTERVAL;
    return call TimerControl.init();
  }


  command result_t StdControl.start() {
    return rcombine(call TimerControl.start(),
		    call Timer.start(TIMER_REPEAT, clockFireInterval));
  }


  command result_t StdControl.stop() {
    return call TimerControl.stop();
  }
  

  command uint32_t TimeStamp.getTimeStamp() {
    return clockCounter;
  }


  command result_t ConfigTimeStamp.setCountInterval(uint32_t newCountInt) {
    clockFireInterval = newCountInt;
    if (call Timer.stop()) {
      return call Timer.start(TIMER_REPEAT, clockFireInterval);
    } else {
      return FAIL;
    }
  }


  command uint32_t ConfigTimeStamp.queryCountInterval() {
    return clockFireInterval;
  }


  event result_t Timer.fired() {
    clockCounter++;
    if ((clockCounter == COUNTER_END) || (clockCounter == COUNTER_HALF)) {
      signal TimeStamp.signalHalfCycle(clockCounter);
    }
    return SUCCESS;
  }
} //implementation
