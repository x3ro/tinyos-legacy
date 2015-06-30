// $Id: SenseLightToLogM.nc,v 1.3 2003/10/07 21:44:59 idgay Exp $

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
 * Implementation for SenseLightToLog module. When a command to start 
 * sensing is received, it periodically samples the light sensor for 
 * N samples and stores them in the EEPROM. Once N samples have been 
 * collected, the timer is turned off and a send done event is posted.
 *
 */

module SenseLightToLogM {
  provides interface StdControl;
  provides interface Sensing;

  uses {
    interface ADC;
    interface StdControl as SubControl;
    interface Leds;
    interface Timer as Timer;
    interface LoggerWrite;
    interface ProcessCmd as CmdExecute;
  }
}
implementation
{

  enum {
    maxdata = 8  // Circular buffer size
  };

  // declare module static variables here
  char head;              // index to the head of the circular buffer
  uint8_t currentBuffer;  // current index to the circular double buffer
  int data[maxdata*2];    // circular double buffer
  int *bufferPtr[2];      // two pointers to the double buffer
  short nsamples;         // number of samples

 /**
   * Initialize the application. 
   * @return Initialization status.
   **/
  command result_t StdControl.init() {
    atomic {
      head = 0;
      currentBuffer = 0;
      bufferPtr[0] = &(data[0]);
      bufferPtr[1] = &(data[8]);
    }
    return rcombine(call SubControl.init(), call Leds.init());
  }

  /**
   * Start the application. 
   * @return Start status.
   **/
  command result_t StdControl.start() {
    return call SubControl.start();
  }

  /**
   * Stop the application. 
   * @return Stop status.
   **/
  command result_t StdControl.stop() {
    return call SubControl.stop();
  } 

  /**
   * This command belongs to the <code>Sensing</code> interface.
   * It starts the timer to generate periodic events.
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t Sensing.start(int samples, int interval_ms) {
    nsamples = samples;
    //call Leds.yellowOff();
    call Timer.start(TIMER_REPEAT, interval_ms);
    return SUCCESS;
  }

  /**
   * Event handler to the <code>Timer.fired</code> event.  
   * @return Always returns <code>SUCCESS</code> 
   **/
  event result_t Timer.fired() {
    nsamples--;
    if (nsamples== 0) {
      // Stop the timer
      call Timer.stop();
      signal Sensing.done();
    }
    call Leds.redToggle();
    call ADC.getData();
    return SUCCESS;

  }
  /**
   * Default event handler to the <code>Sensing.done</code> event. 
   * @return Always returns <code>SUCCESS</code> 
   **/
  default event result_t Sensing.done() {
    return SUCCESS;
  }

  task void writeTask() {
    char* ptr;
    atomic {
      ptr = (char*)bufferPtr[currentBuffer];
      currentBuffer ^= 0x01;
    }
    call LoggerWrite.append(ptr);
  }
  
  /**
   * Event handler to the <code>ADC.dataReady</code> event.
   * 
   * Store the reading in the buffer, when the buffer fills up, 
   * write it out to the logger, and switch to another circular buffer.  
   * @return Always returns <code>SUCCESS</code> 
   **/
  async event result_t ADC.dataReady(uint16_t this_data){
    atomic {
      int p = head;
      bufferPtr[currentBuffer][p] = this_data;
      head = (p+1);
      if (head == maxdata) head = 0;
      if (head == 0) {
	post writeTask();
      }
    }
    return SUCCESS;
  }

  /**
   * Event handler for the <code>LoggerWrite.writeDone</code> event.
   * Toggle the yellow LED if status is true.
   *
   * @return Always returns <code>SUCCESS</code> 
   **/
  event result_t LoggerWrite.writeDone( result_t status ) {
    //if (status) call Leds.yellowOn();
    return SUCCESS;
  }

  /**
   * Event handler to the <code>CmdExecute.done</code> event. Do nothing. 
   * @return Always returns <code>SUCCESS</code> 
   **/
  event result_t CmdExecute.done(TOS_MsgPtr pmsg, result_t status ) {
    return SUCCESS;
  } 
}
