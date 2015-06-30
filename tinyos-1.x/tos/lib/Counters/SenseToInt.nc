// $Id: SenseToInt.nc,v 1.2 2003/10/07 21:46:18 idgay Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


module SenseToInt {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface StdControl as TimerControl;
    interface ADC;
    interface StdControl as ADCControl;
    interface IntOutput;
  }
}
implementation {
  uint16_t reading;
  
  command result_t StdControl.init() {
    return rcombine (call ADCControl.init(), call TimerControl.init());
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ADCControl.start();
    call TimerControl.start();
    return call Timer.start(TIMER_REPEAT, 250);
  }

  command result_t StdControl.stop() {
    call ADCControl.stop();
    return call Timer.stop();
  }

  event result_t Timer.fired() {
    call ADC.getData();
    return SUCCESS;
  }

  void task outputTask() {
    uint16_t rCopy;
    atomic {
      rCopy = reading;
    }
    call IntOutput.output(rCopy >> 7);
  }
  
  async event result_t ADC.dataReady(uint16_t data) {
    atomic {
      reading = data;
    }
    post outputTask();
    return SUCCESS;
  }

  event result_t IntOutput.outputComplete(result_t success) {
    return SUCCESS;
  }
}

