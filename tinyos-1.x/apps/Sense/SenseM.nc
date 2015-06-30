// $Id: SenseM.nc,v 1.5 2004/05/30 23:26:50 jpolastre Exp $

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
 * Authors:  David Culler  Su Ping  
 *           Intel Research Berkeley Lab
 *
 * Modified: Barbara Hohlt 08/23/03
 */
/**
 * Implementation for Sense application.  (Lesson 2 in the tutorial)
 *
 * When clock fires, this application 
 * reads the sensor and displays the higher 3 bits of the ADC readings to LEDs.
 * @author David Culler
 * @author Su Ping
 * @author Intel Research Berkeley Lab
 **/
module SenseM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface ADC;
    interface StdControl as ADCControl;
    interface Leds;
  }
}

implementation {

  // declare module static variables here 


  /**
    * Module scoped method.  Displays the lowest 3 bits to the LEDs,
    * with RED being the most signficant and YELLOW being the least significant.
    *
    * @return returns <code>SUCCESS</code>
    **/
  // display is module static function
  result_t display(uint16_t value)
  {
    if (value &1) call Leds.yellowOn();
    else call Leds.yellowOff();
    if (value &2) call Leds.greenOn();
    else call Leds.greenOff();
    if (value &4) call Leds.redOn();
    else call Leds.redOff();
    return SUCCESS;
  }
 /**
   * Initialize the component. Initialize ADCControl, Leds
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  // implement StdControl interface 
  command result_t StdControl.init() {
    return call Leds.init();
  }
  /**
   * Start the component. Start the clock.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 500);
  }
  
  /**
   * Stop the component. Stop the clock.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /**
   * Read sensor data in response to the <code>Timer.fired</code> event.  
   *
   * @return The result of calling ADC.getData().
   **/
  event result_t Timer.fired() {
    return call ADC.getData();
  }

  /**
   * Display the upper 3 bits of sensor reading to LEDs
   * in response to the <code>ADC.dataReady</code> event.  
   * @return Always returns <code>SUCCESS</code>
   **/
  // ADC data ready event handler 
  async event result_t ADC.dataReady(uint16_t data) {
    display(7-((data>>7) &0x7));
    return SUCCESS;
  }

}
