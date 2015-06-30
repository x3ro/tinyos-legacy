
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
 * Authors:  Alec Woo
 * Last Modified:  08/20/02
 */
/**
 * Implementation for MicasbTest2 application.
 * 
 * The MicasbTest2 tests out light, microphone, and sounder.  
 * Covering the light sensor will trigger the sounder to beeps.  If the microphone
 * detects the sounder's signal, it will turn on the yellow LED to signal the
 * tone is detected.
 * 
 **/


module MicasbTest2M {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
    interface Leds;
    interface StdControl as MicControl;
    interface ADC as MicADC;
    interface Mic;
    interface StdControl as Sounder;
    interface ADC as PhotoADC;
    interface StdControl as PhotoControl;
  }
}
implementation {

  // declare module static variables here  
  char state;
  char count;
  char light;
  char detected;


  /**
   * Initialize the component. Initialize the Mic, Photo, and Sounder.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  command result_t StdControl.init() {
    state = FALSE;
    call MicControl.init();
    call MicControl.init();
    call Mic.muxSel(1);  // Set the mux so that raw microhpone output is selected. (refer to Mic.ti)
    call Mic.gainAdjust(64);  // Set the gain of the microphone.  (refer to Mic.ti)

    call PhotoControl.init();
    call Sounder.init();

    return SUCCESS;
  }

  /**
   * Start the component, Mic, Clock, and Photo
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  command result_t StdControl.start() {
    call MicControl.start();
    call MicControl.start();
    call PhotoControl.start();

    return call Clock.setRate(TOS_I128PS, TOS_S128PS);
  }

  /**
   * Stop the component, Mic, Clock, and Photo.
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  command result_t StdControl.stop() {
    call MicControl.stop();
    call MicControl.stop();
    call PhotoControl.stop();

    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }

  /**
   * In response to the <code>Clock.fire</code> event, toggle the LED,
   * sample the tone detector's output from the microphone, and perform
   * simple filtering to eliminate false negatives and positives from the tone
   * detector.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  event result_t Clock.fire()
  {
    char in;

    if (state < 5){
      state++;
      call Leds.redOn();
    }else{
      state++;
      if (state > 25)
	state = 0;
      call Leds.redOff();
    }
    
    if (state == 0){
      call PhotoADC.getData();
    }

    /* Read the input from the tone detector */
    in = call Mic.readToneDetector();

    // Low pass filtering
    if (in == 0){
      if (count < 32)
	count++;
    }else{
      if (count > 0)
	count--;
    }

    // Threshold detection setting
    if (detected == 1){
      light--;
      if (light == 0){
	call Leds.yellowOff();
	detected = 0;
      }
    }
    
    if (count > 5){
      call Leds.yellowOn();
      detected = 1;
      light = 16;
    }
    
    return SUCCESS;
  }

  /**
   * In response to the <code>MicADC.dataReady</code> event, do nothing.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  event result_t MicADC.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  /**
   * In response to the <code>PhotoADC.dataReady</code> event, 
   * turn Sounder on if it is dark.
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  event result_t PhotoADC.dataReady(uint16_t data)
  {
    char value = data >> 7;

    if ((value & 0x7) <= 0x2)
      return call Sounder.start();
    else
      return call Sounder.stop();
    return FAIL;
  }
}
