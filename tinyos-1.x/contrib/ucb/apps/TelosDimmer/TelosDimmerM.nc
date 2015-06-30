// $Id: TelosDimmerM.nc,v 1.2 2004/10/21 16:32:19 jwhui Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module TelosDimmerM {
  provides {
    interface StdControl;
    interface DimmerControl;
  }
  uses {
    interface Leds;
    interface MSP430Compare as HighAlarm;
    interface MSP430TimerControl as HighAlarmControl;
    interface MSP430Interrupt as ZeroCross;
    interface MSP430GeneralIO as PWM;
    interface StdControl as SubControl;
  }
}

implementation {

  enum { 
    // In microseconds. Rounded down a bit to ensure cut-off before
    // the next zero-crossing.
    AC_HALF_PERIOD = 7500,
    MAX_LEVEL = 0xff,
  };

  enum {
    S_LOW = 0,
    S_HIGH = 1,
  };

  uint16_t onDelay;
  uint16_t newOnDelay;
  bool state;
  
  // debugging
  uint8_t count;

  command result_t StdControl.init() {
    atomic {
      count = 0;
      newOnDelay = onDelay = AC_HALF_PERIOD;
      state = S_HIGH;
      call DimmerControl.setLevel(MAX_LEVEL);
      call PWM.setHigh();
      call PWM.makeOutput();
      call PWM.selectIOFunc();
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    atomic {
      // set interrupt for low to high edge transistion
      call ZeroCross.disable();
      call ZeroCross.clear();
      call ZeroCross.edge(TRUE);
      call ZeroCross.enable();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void DimmerControl.setLevel(uint8_t level) {
    atomic {
      // may not be a linear function
      newOnDelay = (uint16_t)((uint32_t)((uint32_t)AC_HALF_PERIOD*(uint32_t)level)/(uint32_t)MAX_LEVEL);
      newOnDelay = AC_HALF_PERIOD - newOnDelay;
      newOnDelay += 10;
    }
  }
  
  async event void ZeroCross.fired() {

    atomic {
      if (++count >= 120) {
	call Leds.yellowToggle();
	count = 0;
      }

      if (newOnDelay != onDelay)
	onDelay = newOnDelay;

      call PWM.setHigh();

      if (onDelay != AC_HALF_PERIOD) {
	// setup delay to turn on
	call HighAlarm.setEventFromNow(onDelay);
	call HighAlarmControl.clearPendingInterrupt();
	call HighAlarmControl.enableEvents();
      }

      call ZeroCross.clear();
    }
    
  }

  async event void HighAlarm.fired() {

    atomic {
      if (state == S_HIGH) {
	// turn on triac
	call PWM.setLow();
	call HighAlarm.setEventFromPrev(AC_HALF_PERIOD - onDelay);
	state = S_LOW;
      }
      else {
	// turn off triac just before AC zero-cross
	call PWM.setHigh();
	call HighAlarmControl.disableEvents();
	state = S_HIGH;
      }
    }

  }

}
