// $Id: SenseTaskM.nc,v 1.4 2004/05/30 23:34:56 jpolastre Exp $

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
 * Authors:  David Culler,  Su Ping  
 *           Intel Research Berkeley Lab
 *
 */
/**
 * Implementation for SenseTask application.  
 *
 * When the timer fires, this application reads sensor data, posts
 * a task that averages the sensor readings, and displays the highest 
 * 3 bits of the average to the LEDs.
 * 
 * @author David Culler
 * @author Su Ping
 * @author Intel Research Berkeley Lab
 **/
module SenseTaskM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface ADC;
    interface Leds;
  }
}

implementation {

  enum {
    log2size = 3,		// log2 of buffer size
    size=1 << log2size,		// Circular buffer size
    sizemask=size - 1,		// bit mask
  };

  // declare module static variables here
  int8_t head;     // index to the head of the circular buffer
  int16_t rdata[size];  // circular buffer

  /**
   * Module scoped method. Save sensor data into circular buffer.
   *
   * @return returns void
   **/ 
  inline void putdata(int16_t val)
  {
    int16_t p;

    atomic
      {
	p = head;
	head = (p+1) & sizemask;
	rdata[p] = val;
      }
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

     atomic 
       for (i=0; i<size; i++)
	 sum += (rdata[i] >> 7);

     display(sum >> log2size);
  }

  /**
   * Initialize the component. Initialize Leds
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.init() {
    atomic head =0;
    return call Leds.init();
  }

  /**
   * Starts the timer.
   * 
   * @return The value of calling <tt>Timer.start()</tt>.
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 500);
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
  async event result_t ADC.dataReady(uint16_t data) {
    putdata(data);
    post processData();
    return SUCCESS;
  }

}
