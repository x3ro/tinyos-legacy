// $Id: HPLCC2420InterruptM.nc,v 1.1.1.1 2007/08/22 00:43:54 konradlorincz Exp $

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
/*
 *
 * Authors: Joe Polastre
 * Date last modified:  $Revision: 1.1.1.1 $
 *
 */

/**
 * @author Joe Polastre
 */

module HPLCC2420InterruptM {
  provides {
    interface HPLCC2420Interrupt as FIFOP;
    interface HPLCC2420Interrupt as FIFO;
    interface HPLCC2420Interrupt as CCA;
    interface HPLCC2420Capture as SFD;
  }
  uses {
    interface MSP430Interrupt as FIFOPInterrupt;
    interface MSP430Interrupt as FIFOInterrupt;
    interface MSP430Interrupt as CCAInterrupt;
    interface MSP430Capture as SFDCapture;
    interface MSP430TimerControl as SFDControl;
  }
}
implementation
{

  // ************* FIFOP Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the FIFOP pin
   */
  async command result_t FIFOP.startWait(bool low_to_high) {
    atomic {
      call FIFOPInterrupt.disable();
      call FIFOPInterrupt.clear();
      call FIFOPInterrupt.edge(low_to_high);
      call FIFOPInterrupt.enable();
    }
    return SUCCESS;
  }

  /**
   * disables FIFOP interrupts
   */
  async command result_t FIFOP.disable() {
    atomic {
      call FIFOPInterrupt.disable();
      call FIFOPInterrupt.clear();
    }
    return SUCCESS;
  }

  /**
   * Event fired by lower level interrupt dispatch for FIFOP
   */
  async event void FIFOPInterrupt.fired() {
    result_t val = SUCCESS;
    call FIFOPInterrupt.clear();
    val = signal FIFOP.fired();
    if (val == FAIL) {
      call FIFOPInterrupt.disable();
      call FIFOPInterrupt.clear();
    }
  }

  default async event result_t FIFOP.fired() { return FAIL; }
  
  // ************* FIFO Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the FIFO pin
   */
  async command result_t FIFO.startWait(bool low_to_high) {
    atomic {
      call FIFOInterrupt.disable();
      call FIFOInterrupt.clear();
      call FIFOInterrupt.edge(low_to_high);
      call FIFOInterrupt.enable();
    }
    return SUCCESS;
  }

  /**
   * disables FIFO interrupts
   */
  async command result_t FIFO.disable() {
    atomic {
      call FIFOInterrupt.disable();
      call FIFOInterrupt.clear();
    }
    return SUCCESS;
  }

  /**
   * Event fired by lower level interrupt dispatch for FIFO
   */
  async event void FIFOInterrupt.fired() {
    result_t val = SUCCESS;
    call FIFOInterrupt.clear();
    val = signal FIFO.fired();
    if (val == FAIL) {
      call FIFOInterrupt.disable();
      call FIFOInterrupt.clear();
    }
  }

  default async event result_t FIFO.fired() { return FAIL; }

  // ************* CCA Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the CCA pin
   */
  async command result_t CCA.startWait(bool low_to_high) {
    atomic {
      call CCAInterrupt.disable();
      call CCAInterrupt.clear();
      call CCAInterrupt.edge(low_to_high);
      call CCAInterrupt.enable();
    }
    return SUCCESS;
  }

  /**
   * disables CCA interrupts
   */
  async command result_t CCA.disable() {
    atomic {
      call CCAInterrupt.disable();
      call CCAInterrupt.clear();
    }
    return SUCCESS;
  }

  /**
   * Event fired by lower level interrupt dispatch for CCA
   */
  async event void CCAInterrupt.fired() {
    result_t val = SUCCESS;
    call CCAInterrupt.clear();
    val = signal CCA.fired();
    if (val == FAIL) {
      call CCAInterrupt.disable();
      call CCAInterrupt.clear();
    }
  }

  default async event result_t CCA.fired() { return FAIL; }

  // ************* SFD Interrupt handlers and dispatch *************

  async command result_t SFD.enableCapture(bool low_to_high) {
    uint8_t _direction;
    atomic {
      TOSH_SEL_CC_SFD_MODFUNC();
      call SFDControl.disableEvents();
      if (low_to_high) _direction = MSP430TIMER_CM_RISING;
      else _direction = MSP430TIMER_CM_FALLING;
      call SFDControl.setControlAsCapture(_direction);
      call SFDCapture.clearOverflow();
      call SFDControl.clearPendingInterrupt();
      call SFDControl.enableEvents();
    }
    return SUCCESS;
  }

  async command result_t SFD.disable() {
    atomic {
      call SFDControl.disableEvents();
      call SFDControl.clearPendingInterrupt();
      TOSH_SEL_CC_SFD_IOFUNC();
    }
    return SUCCESS;
  }

  async event void SFDCapture.captured(uint16_t time) {
    result_t val = SUCCESS;
    call SFDControl.clearPendingInterrupt();
    val = signal SFD.captured(time);
    if (val == FAIL) {
      call SFDControl.disableEvents();
      call SFDControl.clearPendingInterrupt();
    }
    else {
      if (call SFDCapture.isOverflowPending())
	call SFDCapture.clearOverflow();
    }
  }

  default async event result_t SFD.captured(uint16_t val) { return FAIL; }
}
  
