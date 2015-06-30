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
 * Authors:		Fred Jiang, Kamin Whitehouse
 * Revision:		$Rev$
 *
 */

includes sensorboard;

/* this file manages the analog comparator and timer.  it is only
   concerned with recieve mode.  When the start symbol interrupt is
   received on the atmega 8 from the mica, it is received in
   TxRxControllerM, which calls USoundDetector.enable below, which
   enables the timer capture interrupt to be triggered by the analog
   comparator.  The interrupt below is the timer input capture
   interrupt, which will read the timer value and disable the analog
   comparator interrupt*/

module USoundDetectorM {
  provides interface USoundDetector;
  uses interface Pot;
}

implementation {

  //this funciton is called by UsoundRxrM to enable the analog comparator
  command result_t USoundDetector.enable() {	
    sbi(TIMSK, TICIE1); 	// enable input capture in TIMER1
    outp(0x04, ACSR); 	    // enable intput capture interrupt and disable Comparator interrupt
    return SUCCESS;
  }

  //this funciton is called by UsoundRxrM to set the value which the
  //usound output must exceed to trigger the analog comparator.
  command result_t USoundDetector.setThreshold(uint8_t threshold) {
    call Pot.set(threshold);
    TOSH_CLR_INC_PIN();
    return SUCCESS;
  }
	
  //this funciton is called by UsoundRxrM to disable the analog comparator
  command result_t USoundDetector.disable() {
    //cbi(TIMSK, TICIE1);
    outp(0x00, ACSR);
    return SUCCESS;
  }

  default event result_t USoundDetector.detected(uint16_t timestamp) {
	  return SUCCESS;
  }
  /* this interrupt is the timer input capture interrupt.  It is
  triggered by the ultrasound output exceeding whatever the
  potentiometer output is set to. */
  TOSH_SIGNAL(SIG_INPUT_CAPTURE1) {
    uint16_t timestamp = inp(ICR1L);
    uint16_t timestampH = inp(ICR1H);
	timestamp = timestamp | (timestampH<<8);
    call USoundDetector.disable();
    signal USoundDetector.detected(timestamp);
    __nesc_enable_interrupt();
  }
}







