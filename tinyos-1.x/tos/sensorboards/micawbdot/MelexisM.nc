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
 * $Id: MelexisM.nc,v 1.7 2003/12/19 17:28:05 idgay Exp $
 */

includes sensorboard;
module MelexisM {
  provides {
    interface ADC as Temperature;
    interface ADC as Thermopile;
    interface SplitControl;
    interface Calibration;
    interface ThermopileSelectPin;
  }
  uses {
    interface SplitControl as LowerControl;
    interface Calibration as LowerCalibrate;
    interface ADC as LowerThermopile;
    interface ADC as LowerTemp;
    interface StdControl as TimerControl;
    interface Timer;
  }
}
implementation {

  char state;

  enum { IDLE=0, WARM_UP, POWEROFF, TEMP, THERM, CALIB };

  enum { FILTER_SIZE = 8 };

  uint16_t temp,thermopile;

  uint32_t average;
  uint8_t count;

  task void setSelect() {
    signal ThermopileSelectPin.setDone();
  }

  task void initDone() {
    signal SplitControl.initDone();
  }

  task void startDone() {
    signal SplitControl.startDone();
  } 

  task void stopDone() {
    signal SplitControl.stopDone();
  }

  async event result_t LowerTemp.dataReady(uint16_t data) {
    if (state == TEMP) {
      count++;
      average += (data >> 4); 
      if (count >= FILTER_SIZE) {
        average = average >> 3;
        state = IDLE;
        average = ((average << 4) & 0xFFF0) | (data & 0x0F);
        signal Temperature.dataReady(average & 0xFFFF);
      }
      else {
        call LowerTemp.getData();
      }
    }
    return SUCCESS;
  }

  async event result_t LowerThermopile.dataReady(uint16_t data) {
    if (state == THERM) {
      count++;
      average += (data >> 4);
      if (count >= FILTER_SIZE) {
        average = average >> 3;
        state = IDLE;
        average = ((average << 4) & 0xFFF0) | (data & 0x0F);
        signal Thermopile.dataReady(average & 0xFFFF);
      }
      else {
        call LowerThermopile.getData();
      }
    }
    return SUCCESS;
  }

  command result_t SplitControl.init() {
    state = POWEROFF;
    call TimerControl.init();
    call LowerControl.init();
    MELEXIS_SET_SHDN_PIN();
    MELEXIS_MAKE_SHDN_INPUT();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    state = WARM_UP;
    call Timer.start(TIMER_ONE_SHOT, 800);
    MELEXIS_MAKE_SHDN_OUTPUT();
    MELEXIS_CLEAR_SHDN_PIN();
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
    state = POWEROFF;
    call LowerControl.stop();
    MELEXIS_SET_SHDN_PIN();
    MELEXIS_MAKE_SHDN_INPUT();
    call Timer.start(TIMER_ONE_SHOT, 100);
    return SUCCESS;
  }

  event result_t Timer.fired() {
    if (state == WARM_UP) {
      state = IDLE;
      post startDone();
    }
    else if (state == POWEROFF) {
      post stopDone();
    }
    return SUCCESS;
  }

  // no such thing
  async command result_t Temperature.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t Thermopile.getContinuousData() {
    return FAIL;
  }

  event result_t LowerControl.initDone() {
    return SUCCESS;
  }

  event result_t LowerControl.startDone() {
    if (state == CALIB) {
      call LowerCalibrate.getData();
    }
    else if (state == TEMP) {
      call LowerTemp.getData();
    }
    else if (state == THERM) {
      call LowerThermopile.getData();
    }
    return SUCCESS;
  }

  event result_t LowerControl.stopDone() {
    return SUCCESS;
  }

  command result_t Calibration.getData() {
    if (state == IDLE)
    {
      state = CALIB;
      call LowerControl.start();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t Temperature.getData() {
    if (state == IDLE)
    {
      state = TEMP;
      count = 0;
      average = 0;
      call LowerControl.start();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t Thermopile.getData() {
    if (state == IDLE)
    {
      state = THERM;
      count = 0;
      average = 0;
      call LowerControl.start();
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t LowerCalibrate.dataReady(char word, uint16_t value) {
    // on the last byte of calibration data, shut down the I/O interface
    if (state == CALIB) {
      if (word == 2) {
	state = IDLE;
	signal Calibration.dataReady(word, value);
      }
      else {
	signal Calibration.dataReady(word, value);
      }
    }
    return SUCCESS;
  }

  command result_t ThermopileSelectPin.set(bool value) {
    MELEXIS_MAKE_SELECT_OUTPUT();
    if (value == FALSE)
      MELEXIS_SET_SELECT_PIN();
    else
      MELEXIS_CLEAR_SELECT_PIN();
    return post setSelect();
  }


  default event result_t Calibration.dataReady(char word, uint16_t value) {
    return SUCCESS;
  }

  default async event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  default async event result_t Thermopile.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

}

