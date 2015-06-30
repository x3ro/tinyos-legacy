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
 * $Id: MelexisM.nc,v 1.1.1.2 2004/03/06 03:00:48 mturon Exp $
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
    interface StdControl as SwitchControl;
    interface SplitControl as LowerControl;
    interface Calibration as LowerCalibrate;
    interface Switch;
    interface Switch as IOSwitch;
    interface ADC as LowerThermopile;
    interface ADC as LowerTemp;
  }
}
implementation {

  enum { THERMOPILE = 0, TEMP = 1, 
	 IDLE, WAIT_SWITCH_ON, WAIT_SWITCH_OFF, BUSY, 
	 REPORT_SAMPLE, MAIN_SWITCH_ON, MAIN_SWITCH_OFF,
	 POWERON, POWEROFF,
         IDLE2, SELECT2};

  char state;
  char state2;
  char sensor;
  char iostate;
  char c_word;

  uint16_t temp,thermopile;
  uint16_t c_value;

  task void IOBus() {

    if (state == BUSY) {
      // get sample
      if (sensor == THERMOPILE)
	call LowerThermopile.getData();
      else if (sensor == TEMP)
	call LowerTemp.getData();
      else if (sensor == 2)
	call LowerCalibrate.getData();
      return;
    }

    else if (state == REPORT_SAMPLE) {
      uint16_t l_thermopile = thermopile;
      uint16_t l_temp = temp;
      char l_sensor = sensor;

      call LowerControl.stop();

      state = IDLE;
      // signal data
      if (l_sensor == THERMOPILE)
	signal Thermopile.dataReady(l_thermopile);
      if (l_sensor == TEMP)
	signal Temperature.dataReady(l_temp);
      if (l_sensor == 2) 
	signal Calibration.dataReady(c_word, c_value);
      return;
    }
  }

  event result_t LowerControl.initDone() { return signal SplitControl.initDone(); }
  event result_t LowerControl.startDone() { return signal SplitControl.startDone(); }
  event result_t LowerControl.stopDone() { return signal SplitControl.stopDone(); }

  event result_t LowerTemp.dataReady(uint16_t data) {
    if (state == BUSY) {
      state = REPORT_SAMPLE;
      temp = data;
      post IOBus();
    }
    return SUCCESS;
  }

  event result_t LowerThermopile.dataReady(uint16_t data) {
    if (state == BUSY) {
      state = REPORT_SAMPLE;
      thermopile = data;
      post IOBus();
    }
    return SUCCESS;
  }

  command result_t SplitControl.init() {
    state = POWEROFF;
    state2 = IDLE2;
    call LowerControl.init();
    return call SwitchControl.init();
  }

  command result_t SplitControl.start() {
    state = MAIN_SWITCH_ON;
    call SwitchControl.start();
    if (call Switch.set(MICAWB_THERM_POWER,1) != SUCCESS) {
      state = WAIT_SWITCH_ON;
    }
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
    state = MAIN_SWITCH_OFF;
    if (call Switch.set(MICAWB_THERM_POWER,0) != SUCCESS) {
      state = WAIT_SWITCH_OFF;
    }
    return SUCCESS;
  }

  event result_t Switch.getDone(char value) {
    return SUCCESS;
  }

  event result_t Switch.setDone(bool l_result) {
    if (state == WAIT_SWITCH_ON) {
      if (call Switch.set(MICAWB_THERM_POWER,1) == SUCCESS) {
	state = MAIN_SWITCH_ON;
      }
    }
    else if (state == WAIT_SWITCH_OFF) {
      if (call Switch.set(MICAWB_THERM_POWER,0) == SUCCESS) {
	state = MAIN_SWITCH_OFF;
      }
    }
    else if (state == MAIN_SWITCH_ON) {
      state = IDLE;
    }
    else if (state == MAIN_SWITCH_OFF) {
      state = POWEROFF;
    }
    return SUCCESS;
  }

  event result_t Switch.setAllDone(bool l_result) {
    return SUCCESS;
  }

  // no such thing
  command result_t Temperature.getContinuousData() {
    return FAIL;
  }

  // no such thing
  command result_t Thermopile.getContinuousData() {
    return FAIL;
  }

  command result_t Calibration.getData() {
    if (state == IDLE)
    {
      state = BUSY;
      sensor = 2;
      // enable the module and disable flash lines
      call LowerControl.start();
      post IOBus();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t Temperature.getData() {
    if (state == IDLE)
    {
      state = BUSY;
      sensor = TEMP;
      // enable the module and disable flash lines
      call LowerControl.start();
      post IOBus();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t Thermopile.getData() {
    if (state == IDLE)
    {
      state = BUSY;
      sensor = THERMOPILE;
      // enable the module and disable flash lines
      call LowerControl.start();
      post IOBus();
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t LowerCalibrate.dataReady(char word, uint16_t value) {
    // on the last byte of calibration data, shut down the I/O interface
    if (state == BUSY) {
      if (word == 2) {
	state = REPORT_SAMPLE;
	c_word = word;
	c_value = value;
	post IOBus();
      }
      else {
	signal Calibration.dataReady(word, value);
      }
    }
    return SUCCESS;
  }

  command result_t ThermopileSelectPin.set(bool value) {
    if (state2 == IDLE2) {
      state2 = SELECT2;
      return call IOSwitch.set(MICAWB_THERMOPILE_SELECT, value);
    }
    return FAIL;
  }

  event result_t IOSwitch.getDone(char value) {
    return SUCCESS;
  }

  event result_t IOSwitch.setDone(bool l_result) {
    if (state2 == SELECT2) {
      state2 = IDLE2;
      signal ThermopileSelectPin.setDone();  
    }
    return SUCCESS;
  }

  event result_t IOSwitch.setAllDone(bool l_result) {
    return SUCCESS;
  }


  default event result_t Calibration.dataReady(char word, uint16_t value) {
    return SUCCESS;
  }

  default event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  default event result_t Thermopile.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

}

