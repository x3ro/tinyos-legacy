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
 * Authors:		Joe Polastre
 *
 * $Id: AccelM.nc,v 1.2 2004/07/16 21:53:57 ammbot Exp $
 */

includes sensorboard;

module AccelM
{
  provides {
    interface ADC[uint8_t id];
    interface SplitControl;
  }
  uses {
    interface ADC as Accel1;
    interface ADC as Accel2;
    interface ADCControl;
    interface Timer;
    interface StdControl as TimerControl;
  }
}

implementation
{

  char state;

  enum { IDLE = 0, WARM_UP, SAMPLE, POWEROFF };

  task void initDone() {
    signal SplitControl.initDone();
  }

  task void startDone() {
    signal SplitControl.startDone();
  }

  task void stopDone() {
    signal SplitControl.stopDone();
  }

  command result_t SplitControl.init() {
    state = POWEROFF;
    ACCEL_POWER_OFF();
    call ADCControl.init();
    call TimerControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    if(state == POWEROFF) {
      ACCEL_POWER_ON();
      state = WARM_UP;
      call Timer.start(TIMER_ONE_SHOT, 10);
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t SplitControl.stop() {
    if(state == IDLE) {
      state = POWEROFF;
      ACCEL_POWER_OFF();
      post stopDone();
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t Timer.fired() {
    if (state == WARM_UP) {
      state = IDLE;
      post startDone();
    }
    return SUCCESS;
  }

  // no such thing
  async command result_t ADC.getContinuousData[uint8_t id]() {
    return FAIL;
  }

  async command result_t ADC.getData[uint8_t id]() {
    if (state == IDLE)
    {
      state = SAMPLE;
      switch(id) {
      case 1: return call Accel1.getData();
      case 2: return call Accel2.getData();
      }
    }
    //state = IDLE;
    return FAIL;
  }

  default async event result_t ADC.dataReady[uint8_t id](uint16_t data)
  {
    return SUCCESS;
  }

  async event result_t Accel1.dataReady(uint16_t data){ 
    if (state == SAMPLE) {
	state = IDLE;
	signal ADC.dataReady[1](data);
    }
    return SUCCESS;
  }
  async event result_t Accel2.dataReady(uint16_t data){ 
    if (state == SAMPLE) {
	state = IDLE;
	signal ADC.dataReady[2](data);
    }
    return SUCCESS;
  }

}

