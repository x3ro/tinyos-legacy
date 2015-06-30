// $Id: TestSounderM.nc,v 1.2 2003/10/07 21:44:54 idgay Exp $

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
 * Last Modified:  08/20/02
 *
 */
/**
 * Implementation for TestSounder application.
 * 
 * When clock fires, this application toggles the sounder to make it buzzes.
 * 
 * @author Alec Woo
 **/

includes sensorboard;
module TestSounderM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface StdControl as SndControl;
  }
}
implementation {

  // declare module static variables here
  bool state;

  /**
   * Initialize the component. Initialize Timer, Leds
   *
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/             
  command result_t StdControl.init() {
    state = FALSE;
    call SndControl.init();
    return SUCCESS;
  }

  /**
   * Start the component.
   *
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/             
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT,1024);
  }

  /**
   * Stop the component.
   *
   * @return returns <code>SUCCESS</code>
   **/             
  command result_t StdControl.stop() {
    return call Timer.stop();;
  }

  /**
   * In response to the <code>Clock.fire</code> event, toggle the Sounder and red led.
   *
   * @return returns <code>SUCCESS</code>
   **/             
  event result_t Timer.fired()
  {
    state = !state;

    if (state){
      call Leds.redOn();
      call SndControl.start();
    }else{
      call Leds.redOff();
      call SndControl.stop();
    }

    return SUCCESS;
  }
}

