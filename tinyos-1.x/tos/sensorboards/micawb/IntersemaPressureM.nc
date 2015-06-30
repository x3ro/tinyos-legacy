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
 * $Id: IntersemaPressureM.nc,v 1.9 2003/12/13 01:50:57 whong Exp $
 */

includes sensorboard;

module IntersemaPressureM {
  provides {
    interface ADC as Temperature;
    interface ADC as Pressure;
    interface StdControl;
    interface Calibration;
  }
  uses {
    interface StdControl as SwitchControl;
    interface StdControl as LowerControl;
    interface Calibration as LowerCalibrate;
    interface Switch;
    interface Switch as IOSwitch;
    interface ADC as LowerPressure;
    interface ADC as LowerTemp;
  }
}
implementation {

  enum { IDLE, WAIT_SWITCH_ON, WAIT_SWITCH_OFF, BUSY, 
	 MAIN_SWITCH_ON, MAIN_SWITCH_OFF, SWITCH_IO1, SWITCH_IO2, SWITCH_IO3, 
	 POWERON, POWEROFF, IOON = 1, IOOFF = 0 };

  char state;
  char sensor;
  char iostate;
  char c_word;

  uint16_t temp,pressure;
  uint16_t c_value;

  task void IOBus() {
    if (state == BUSY) {
      state = SWITCH_IO1;
      call IOSwitch.set(MICAWB_PRESSURE_SCLK, iostate);
    }
    else if (state == SWITCH_IO1) {
      state = SWITCH_IO2;
      call IOSwitch.set(MICAWB_PRESSURE_DIN, iostate);
    }
    else if (state == SWITCH_IO2) {
      state = SWITCH_IO3;
      call IOSwitch.set(MICAWB_PRESSURE_DOUT, iostate);
    }
    else if (state == SWITCH_IO3) {
      // get sample
      if (iostate == IOON) {
	if (sensor == MICAWB_PRESSURE)
	  call LowerPressure.getData();
	else if (sensor == MICAWB_PRESSURE_TEMP)
	  call LowerTemp.getData();
	else if (sensor == 2)
	  call LowerCalibrate.getData();
      }
      else if (iostate == IOOFF) {
	uint16_t l_pressure = pressure;
	uint16_t l_temp = temp;
	char l_sensor = sensor;
	call LowerControl.stop();
	state = IDLE;
	// signal data
	if (l_sensor == MICAWB_PRESSURE)
	  signal Pressure.dataReady(l_pressure);
	if (l_sensor == MICAWB_PRESSURE_TEMP)
	  signal Temperature.dataReady(l_temp);
	if (l_sensor == 2)
	  signal Calibration.dataReady(c_word, c_value);
      }
    }
  }

  event result_t LowerTemp.dataReady(uint16_t data) {
    if (state == SWITCH_IO3) {
      iostate = IOOFF;
      state = BUSY;
      temp = data;
      post IOBus();
    }
    return SUCCESS;
  }

  event result_t LowerPressure.dataReady(uint16_t data) {
    if (state == SWITCH_IO3) {
      iostate = IOOFF;
      state = BUSY;
      pressure = data;
      post IOBus();
    }
    return SUCCESS;
  }

  command result_t StdControl.init() {
    state = IDLE;
    iostate = IOOFF;
    call LowerControl.init();
    return call SwitchControl.init();
  }

  command result_t StdControl.start() {
    state = MAIN_SWITCH_ON;
    call SwitchControl.start();
    if (call Switch.set(MICAWB_PRESSURE_POWER,1) != SUCCESS) {
      state = WAIT_SWITCH_ON;
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    state = MAIN_SWITCH_OFF;
    if (call Switch.set(MICAWB_PRESSURE_POWER,0) != SUCCESS) {
      state = WAIT_SWITCH_OFF;
    }
    return SUCCESS;
  }

  event result_t Switch.getDone(char value) {
    return SUCCESS;
  }

  event result_t Switch.setDone(bool l_result) {
    if (state == WAIT_SWITCH_ON) {
      if (call Switch.set(MICAWB_PRESSURE_POWER,1) == SUCCESS) {
	state = MAIN_SWITCH_ON;
      }
    }
    else if (state == WAIT_SWITCH_OFF) {
      if (call Switch.set(MICAWB_PRESSURE_POWER,0) == SUCCESS) {
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

  event result_t IOSwitch.getDone(char value) {
    return SUCCESS;
  }

  event result_t IOSwitch.setDone(bool l_result) {
    if ((state == SWITCH_IO1) || (state == SWITCH_IO2) || (state == SWITCH_IO3)) {
      post IOBus();
    }
    return SUCCESS;
  }

  event result_t IOSwitch.setAllDone(bool l_result) {
    return SUCCESS;
  }

  // no such thing
  async command result_t Temperature.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t Pressure.getContinuousData() {
    return FAIL;
  }

  command result_t Calibration.getData() {
    if (state == IDLE)
    {
      state = BUSY;
      sensor = 2;
      iostate = IOON;
      // enable the module and disable flash lines
      call LowerControl.start();
      post IOBus();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t Temperature.getData() {
    if (state == IDLE)
    {
      state = BUSY;
      sensor = MICAWB_PRESSURE_TEMP;
      iostate = IOON;
      // enable the module and disable flash lines
      call LowerControl.start();
      post IOBus();
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t Pressure.getData() {
    if (state == IDLE)
    {
      state = BUSY;
      sensor = MICAWB_PRESSURE;
      iostate = IOON;
      // enable the module and disable flash lines
      call LowerControl.start();
      post IOBus();
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t LowerCalibrate.dataReady(char word, uint16_t value) {
    // on the last byte of calibration data, shut down the I/O interface
    if (word == 4) {
      state = BUSY;
      c_word = word;
      c_value = value;
      iostate = IOOFF;
      post IOBus();
    }
    else {
      signal Calibration.dataReady(word, value);
    }
    return SUCCESS;
  }

  default event result_t Calibration.dataReady(char word, uint16_t value) {
    return SUCCESS;
  }

  default async event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  default async event result_t Pressure.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

}

