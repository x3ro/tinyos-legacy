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
 * $Id: SensirionHumidityM.nc,v 1.1.1.1 2007/11/05 19:10:40 jpolastre Exp $
 */

includes sensorboard;
module SensirionHumidityM {
  provides {
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface SplitControl;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
  }
  uses {
    interface ADC as HumSensor;
    interface ADC as TempSensor;
    interface ADCError as HumError;
    interface ADCError as TempError;
    interface StdControl as SensorControl;

    interface Timer;
    interface StdControl as SwitchControl;
    interface Switch as Switch1;
    interface Switch as SwitchI2W;
  }
}
implementation {

  enum {IDLE, BUSY, BUSY_0, BUSY_1, GET_SAMPLE_0, GET_SAMPLE_1,
        OPENSCK, OPENDATA, CLOSESCK, CLOSEDATA,  POWEROFF,
	MAIN_SWITCH_ON, MAIN_SWITCH_OFF, WAIT_SWITCH_ON, WAIT_SWITCH_OFF, TIMER};

  char state;
  char id;
  char tempvalue;
  uint16_t result;
  bool power;

  task void initDone() {
    signal SplitControl.initDone();
  }

  command result_t SplitControl.init() {
    state = POWEROFF;
    power = FALSE;
    call SensorControl.init();
    call SwitchControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    // turn the sensor on
    state = MAIN_SWITCH_ON;
    call SensorControl.start();
    call SwitchControl.start();
    if (call Switch1.set(MICAWB_HUMIDITY_POWER,1) != SUCCESS) {
      state = WAIT_SWITCH_ON;
    }
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
    power = FALSE;
    state = MAIN_SWITCH_OFF;
    // turn the sensor off
    if (call Switch1.set(MICAWB_HUMIDITY_POWER,0) != SUCCESS) {
      state = WAIT_SWITCH_OFF;
    }
    return call SensorControl.stop();
  }

  event result_t Switch1.getDone(char value) {
    return SUCCESS;
  }

  event result_t Switch1.setDone(bool local_result) {
    if (state == MAIN_SWITCH_ON) {
      state = IDLE;
      signal SplitControl.startDone();
    }
    else if (state == MAIN_SWITCH_OFF) {
      state = POWEROFF;
      signal SplitControl.stopDone();
    }
    else if (state == WAIT_SWITCH_ON) {
      if (call Switch1.set(MICAWB_HUMIDITY_POWER,1) == SUCCESS) {
	state = MAIN_SWITCH_ON;
      }
    }
    else if (state == WAIT_SWITCH_OFF) {
      if (call Switch1.set(MICAWB_HUMIDITY_POWER,0) == SUCCESS) {
	state = MAIN_SWITCH_OFF;
      }
    }
    return SUCCESS;
  }

  event result_t Switch1.setAllDone(bool local_result) {
    return SUCCESS;
  }

  event result_t SwitchI2W.getDone(char value) {
    return SUCCESS;
  }

  event result_t SwitchI2W.setDone(bool local_result) {
    if (state == OPENSCK) {
      state = OPENDATA;
      return call SwitchI2W.set(MICAWB_HUMIDITY_DATA,1);
    } else if (state == OPENDATA) {
      state = TIMER;
      return call Timer.start(TIMER_ONE_SHOT, 100);
    } else if (state == CLOSESCK) {
      state = CLOSEDATA;
      return call SwitchI2W.set(MICAWB_HUMIDITY_DATA,0);
    } else if (state == CLOSEDATA) {
        uint16_t l_result = result;
	state = IDLE;
	if (id == MICAWB_HUMIDITY)
	  signal Humidity.dataReady(l_result);
	else if (id == MICAWB_HUMIDITY_TEMP)
	  signal Temperature.dataReady(l_result);
    }
    return SUCCESS;
  }

  event result_t Timer.fired() {
      state = BUSY;
      if (id == MICAWB_HUMIDITY)
      {
	return call HumSensor.getData();
      }
      else if (id == MICAWB_HUMIDITY_TEMP)
      {
	return call TempSensor.getData();
      }
      state = IDLE;
      return SUCCESS;
  }


  event result_t SwitchI2W.setAllDone(bool local_result) {
    return SUCCESS;
  }

  // no such thing
  async command result_t Humidity.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t Temperature.getContinuousData() {
    return FAIL;
  }

  async command result_t Humidity.getData() {
    if (state == IDLE)
    {
      id = MICAWB_HUMIDITY;
      state = OPENSCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,1);
    }
    state = IDLE;
    return FAIL;
  }

  command result_t Temperature.getData() {
    if (state == IDLE)
    {
      id = MICAWB_HUMIDITY_TEMP;
      state = OPENSCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,1);
    }
    state = IDLE;
    return FAIL;
  }

  default async event result_t Humidity.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  default async event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  async event result_t TempSensor.dataReady(uint16_t data) {
    result = data;
    if (state == BUSY) {
      state = CLOSESCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,0);
    }
    return SUCCESS;
  }

  async event result_t HumSensor.dataReady(uint16_t data) {
    result = data;
    if (state == BUSY) {
      state = CLOSESCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,0);
    }
    return SUCCESS;
  }

  command result_t HumidityError.enable() {
    return call HumError.enable();
  }

  command result_t HumidityError.disable() {
    return call HumError.disable();
  }

  command result_t TemperatureError.enable() {
    return call TempError.enable();
  }

  command result_t TemperatureError.disable() {
    return call TempError.disable();
  }

  event result_t HumError.error(uint8_t token) {
    state = IDLE;
    call SensorControl.stop();
    return signal HumidityError.error(token);
  }

  event result_t TempError.error(uint8_t token) {
    state = IDLE;
    call SensorControl.stop();
    return signal TemperatureError.error(token);
  }

  default event result_t HumidityError.error(uint8_t token) { return SUCCESS; }

  default event result_t TemperatureError.error(uint8_t token) { return SUCCESS;
 }

}

