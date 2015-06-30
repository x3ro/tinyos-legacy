// $Id: BlinkManyM.nc,v 1.1 2004/01/26 19:14:33 vlahan Exp $

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

/**
 * Implementation for the BlinkMany application
 * @author Vlado Handziski (based on the original Blink application)
 **/
module BlinkManyM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer as Timer0;
    interface Timer as Timer1;
    interface Timer as Timer2;
    interface Timer as Timer3;

    interface LedsNumbered;
  }
}
implementation {

  /**
   * Initialize the component.
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call LedsNumbered.init();
    return SUCCESS;
  }


  /**
   * Start four different timers
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {

    uint8_t result_0;
    uint8_t result_1;
    uint8_t result_2;
    uint8_t result_3;

    result_0 = call Timer0.start(TIMER_REPEAT, 125);
    result_1 = call Timer1.start(TIMER_REPEAT, 250);
    result_2 = call Timer2.start(TIMER_REPEAT, 500);
    result_3 = call Timer3.start(TIMER_REPEAT, 1000);

    return rcombine4(result_0, result_1, result_2, result_3);
  }

  /**
   * Halt execution of the application.
   * Disable the timers.
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    uint8_t result_0;
    uint8_t result_1;
    uint8_t result_2;
    uint8_t result_3;

    result_0 = call Timer0.stop();
    result_1 = call Timer1.stop();
    result_2 = call Timer2.stop();
    result_3 = call Timer3.stop();

    return rcombine4(result_0, result_1, result_2, result_3);
  }


  /**
   * Toggle the LEDs on the Infineon board when the coresponding Timer fires.
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer0.fired()
  {
    call LedsNumbered.led0Toggle();
    return SUCCESS;
  }
  event result_t Timer1.fired()
  {
    call LedsNumbered.led1Toggle();
    return SUCCESS;
  }
  event result_t Timer2.fired()
  {
    call LedsNumbered.led2Toggle();
    return SUCCESS;
  }
  event result_t Timer3.fired()
  {
    call LedsNumbered.led3Toggle();
    return SUCCESS;
  }

}


