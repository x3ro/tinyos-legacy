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
 *
 * Authors:		Joe Polastre
 *
 * $Id: IntersemaPressureM.nc,v 1.1.1.2 2004/03/06 03:00:49 mturon Exp $
 */

includes sensorboard;
module IntersemaPressureM {
  provides {
    interface ADC as Temperature;
    interface ADC as Pressure;
    interface ADCError as TemperatureError;
    interface ADCError as PressureError;
    interface SplitControl;
    interface Calibration;
  }
  uses {
    interface StdControl as LowerControl;
    interface Calibration as LowerCalibrate;
    interface ADC as LowerPressure;
    interface ADC as LowerTemp;
    interface ADCError as PressError;
    interface ADCError as TempError;
    interface Timer;
    interface StdControl as TimerControl;
  }
}
implementation {

  enum {POWER_OFF = 0, IDLE, SAMPLE, WARM_UP};

  char state;
  uint32_t average_total;
  uint8_t counter;

  task void initDone() {
	signal SplitControl.initDone();
  }

  task void stopDone() {
 	signal SplitControl.stopDone();
  }

  event result_t LowerTemp.dataReady(uint16_t data) {
    // each sensor should be sampled 4 times and averaged
    if (state == SAMPLE) {
        counter++;
        average_total += data;
        if (counter < 8) {
          call LowerTemp.getData();
          return SUCCESS;
        }
        else {
          uint16_t value = ((average_total >> 3) & 0x0FFFF);
          call LowerControl.stop();
	  state = IDLE;
	  signal Temperature.dataReady(value);
        }
    }
    return SUCCESS;
  }

  event result_t LowerPressure.dataReady(uint16_t data) {
    if (state == SAMPLE) {
        counter++;
        average_total += data;
        if (counter < 8) {
          call LowerPressure.getData();
          return SUCCESS;
        }
        else {
          uint16_t value = ((average_total >> 3) & 0x0FFFF);
          call LowerControl.stop();
	  state = IDLE;
	  signal Pressure.dataReady(value);
        }
    }
    return SUCCESS;
  }

  command result_t SplitControl.init() {
    state = POWER_OFF;
    call LowerControl.init();
    call TimerControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
	    PRESSURE_POWER_ON();
	    state = WARM_UP;
	    call Timer.start(TIMER_ONE_SHOT, 500);
	    return SUCCESS;
  }

  command result_t SplitControl.stop() {
	    state = POWER_OFF;
	    call LowerControl.stop();
	    PRESSURE_POWER_OFF();
	    post stopDone();
	    return SUCCESS;
  }

  event result_t Timer.fired() {
        if (state == WARM_UP) {
		state = IDLE;
		signal SplitControl.startDone();
        }
        return SUCCESS;
  }

  // no such thing
  command result_t Pressure.getContinuousData() {
    return FAIL;
  }

  // no such thing
  command result_t Temperature.getContinuousData() {
    return FAIL;
  }

  command result_t Calibration.getData() {
    if (state == IDLE)
    {
      call LowerControl.start();
      state = SAMPLE;
      call LowerCalibrate.getData();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t Temperature.getData() {
    if (state == IDLE)
    {
      counter = 0;
      average_total = 0;
      call LowerControl.start();
      state = SAMPLE;
      call LowerTemp.getData();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t Pressure.getData() {
    if (state == IDLE)
    {
      counter = 0;
      average_total = 0;
      call LowerControl.start();
      state = SAMPLE;
      call LowerPressure.getData();
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t LowerCalibrate.dataReady(char word, uint16_t value) {
    // on the last byte of calibration data, shut down the I/O interface
    if (word == 4) {
      call LowerControl.stop();
      state = IDLE;
      signal Calibration.dataReady(word, value);
    }
    else {
      call LowerControl.stop();
      signal Calibration.dataReady(word, value);
    }
    return SUCCESS;
  }

  command result_t PressureError.enable() {
    return call PressError.enable();
  }

  command result_t PressureError.disable() {
    return call PressError.disable();
  }

  command result_t TemperatureError.enable() {
    return call TempError.enable();
  }

  command result_t TemperatureError.disable() {
    return call TempError.disable();
  }

  event result_t PressError.error(uint8_t token) {
    call LowerControl.stop();
    state = IDLE;
    return signal PressureError.error(token);
  }

  event result_t TempError.error(uint8_t token) {
    call LowerControl.stop();
    state = IDLE;
    return signal TemperatureError.error(token);
  }

  default event result_t PressureError.error(uint8_t token) { return SUCCESS; }

  default event result_t TemperatureError.error(uint8_t token) { return SUCCESS; }

  default event result_t Calibration.dataReady(char word, uint16_t value) {
    return SUCCESS;
  }

  default event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  default event result_t Pressure.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

}

