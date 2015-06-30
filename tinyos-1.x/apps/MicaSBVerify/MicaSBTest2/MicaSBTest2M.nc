// $Id: MicaSBTest2M.nc,v 1.3 2004/12/21 18:59:27 jpolastre Exp $

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
 * Authors:  Alec Woo
 * Last Modified:  $Id: MicaSBTest2M.nc,v 1.3 2004/12/21 18:59:27 jpolastre Exp $
 */
/**
 * Implementation for MicaSBTest2 application.
 * 
 * The MicaSBTest2 tests out light, microphone, and sounder.  
 * Covering the light sensor will trigger the sounder to beeps.  If the microphone
 * detects the sounder's signal, it will turn on the yellow LED to signal the
 * tone is detected.
 * 
 * @author Alec Woo
 **/


module MicaSBTest2M {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
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


  task void SounderStart() {
    call Sounder.start();
  }

  task void SounderStop() {
    call Sounder.stop();
  }

  /**
   * Initialize the component. Initialize the Mic, Photo, and Sounder.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  command result_t StdControl.init() {
    state = FALSE;
    call Leds.init();
    call MicControl.init();
    call MicControl.init();
    call Mic.muxSel(1);  // Set the mux so that raw microhpone output is selected. (refer to Mic.ti)
    call Mic.gainAdjust(64);  // Set the gain of the microphone.  (refer to Mic.ti)

    call PhotoControl.init();
    call Sounder.init();

    return SUCCESS;
  }

  /**
   * Start the component, Mic, Timer, and Photo
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  command result_t StdControl.start() {
    call MicControl.start();
    call MicControl.start();
    call PhotoControl.start();

    return call Timer.start(TIMER_REPEAT, 8); // 128 pulses per second
  }

  /**
   * Stop the component, Mic, Timer, and Photo.
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  command result_t StdControl.stop() {
    call MicControl.stop();
    call MicControl.stop();
    call PhotoControl.stop();

    return call Timer.stop();
  }

  /**
   * In response to the <code>Timer.fired</code> event, toggle the LED,
   * sample the tone detector's output from the microphone, and perform
   * simple filtering to eliminate false negatives and positives from the tone
   * detector.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  event result_t Timer.fired()
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
  async event result_t MicADC.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  /**
   * In response to the <code>PhotoADC.dataReady</code> event, 
   * turn Sounder on if it is dark.
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  async event result_t PhotoADC.dataReady(uint16_t data)
  {
    char value = data >> 7;

    if ((value & 0x7) <= 0x2)
      //return call Sounder.start();
      return post SounderStart();
    else
      //return call Sounder.stop();
      return post SounderStop();
    return FAIL;
  }
}
