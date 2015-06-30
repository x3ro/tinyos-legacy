//$Id: CaptureM.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */

generic module CaptureM() {
  provides interface Capture;
  uses interface MSP430TimerControl;
  uses interface MSP430Capture;
  uses interface MSP430GeneralIO;
  uses interface LocalTime<T32khz> as LocalTime;
}
implementation {
  typedef result_t error_t;

  uint32_t adjustTime(uint16_t t) {
    uint32_t time = call LocalTime.get();
    if ((time & 0xFFFF) < t) {
      time -= 0x10000;
    }
    time &= 0xFFFF0000;
    time |= t;
    return time;
  }

  async command error_t Capture.enableCapture(bool low_to_high) {
    atomic {
      call MSP430GeneralIO.selectModuleFunc();
      call MSP430TimerControl.disableEvents();
      call MSP430TimerControl.setControlAsCapture( low_to_high ? MSP430TIMER_CM_RISING : MSP430TIMER_CM_FALLING );
      call MSP430Capture.clearOverflow();
      call MSP430TimerControl.clearPendingInterrupt();
      call MSP430TimerControl.enableEvents();
    }
    return SUCCESS;
  }

  async command error_t Capture.disable() {
    atomic {
      call MSP430TimerControl.disableEvents();
      call MSP430TimerControl.clearPendingInterrupt();
      call MSP430GeneralIO.selectIOFunc();
    }
    return SUCCESS;
  }

  async event void MSP430Capture.captured(uint16_t time) {
    error_t val = SUCCESS;
    call MSP430TimerControl.clearPendingInterrupt();
    val = signal Capture.captured(adjustTime(time));
    if (val == FAIL) {
      call MSP430TimerControl.disableEvents();
      call MSP430TimerControl.clearPendingInterrupt();
    }
    else {
      if (call MSP430Capture.isOverflowPending())
        call MSP430Capture.clearOverflow();
    }
  }

  // stop the timer if no one is wired to it
  default async event error_t Capture.captured(uint32_t val) { return FAIL; }
}
