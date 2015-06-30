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
 * Authors:  David Culler,  Su Ping  
 *           Intel Research Berkeley Lab
 *
 */
/**
 * Implementation for Sense2 application.  
 *
 * When the timer fires, this application reads sensor data, posts
 * a task that averages the sensor readings, and displays the highest 
 * 3 bits of the average to the LEDs.
 * 
 **/
module Sense2M {
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

  // nesC does not support preprocessor. Don't use #define 
  enum {
    maxdata=8,     // Circular buffer size
    maskdata=0x7,  // bit mask
    shiftdata=3    // divid by 2^3 for averaging the circular buffer.
  };

  // declare module static variables here
  int8_t head;     // index to the head of the circular buffer
  int16_t rdata[maxdata];  // circular buffer

  /**
   * Module scoped method. Save sensor data into circular buffer.
   *
   * @return returns void
   **/ 
  inline void putdata(int16_t val)
  {
    int16_t p = (int16_t)head;
    head = (p+1) & maskdata;
    rdata[p] = val;
    
  }

  /** 
   * Module scoped method.  Displays the lowest 3 bits to the LEDs,
   * with RED being the most signficant and YELLOW being the least significant.
   *
   * @return returns <code>SUCCESS</code>
   **/
  // display is a module static function
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
   * Module task.  Process sensor reading, compute the average, and
   * display it.
   * @return returns void
   **/
  task void processData() 
  {
     int16_t i, sum=0;

     for (i=0; i<maxdata; i++)
       sum += (rdata[i] >> 7);
     display(sum >> shiftdata);
  }

  /**
   * Initialize the component. Initialize ADCControl, Leds
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.init() {
    head =0;
    return rcombine(call ADCControl.init(), call Leds.init());
  }

  /**
   * Starts the timer.
   * 
   * @return The value of calling <tt>Timer.start()</tt>.
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 200);
  }

  /**
   * Stops the timer.
   *
   * @return The value of calling <tt>Timer.stop()</tt>.
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /**
   * Read sensor data in response to the <code>Timer.fired</code> event.  
   *
   * @return The value of calling <tt>ADC.getData()</tt>.
   **/
  event result_t Timer.fired() {
    return call ADC.getData();
  }

  /**
   * In response to <code>ADC.dataReady</code>, store sensor data 
   * and post task for averaging.
   * @return returns <code>SUCCESS</code>
   **/
  event result_t ADC.dataReady(uint16_t data) {
    putdata(data);
    post processData();
    return SUCCESS;
  }

}
