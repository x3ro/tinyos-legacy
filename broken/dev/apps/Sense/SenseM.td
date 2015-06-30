/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  David Culler  Su Ping  
 *           Intel Research Berkeley Lab
 *
 */
/**
 * Implementation for Sense application.  (Lesson 2 in the tutorial)
 *
 * When clock fires, this application 
 * reads the sensor and displays the higher 3 bits of the ADC readings to LEDs.
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
    return rcombine(call ADCControl.init(), call Leds.init());
  }
  /**
   * Start the component. Start the clock.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 200);
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
  event result_t ADC.dataReady(uint16_t data) {
    display(7-((data>>7) &0x7));
    return SUCCESS;
  }

}
