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
 * $Id: SensirionHumidityM.nc,v 1.1.1.1 2007/11/05 19:10:41 jpolastre Exp $
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
    interface StdControl as BusControl;

    interface BusArbitration;

    interface StdControl as TimerControl;
    interface Timer;
  }
}
implementation {

  char state;
  char id;

  enum { IDLE = 0, WARM_UP, POWER_OFF, SAMPLE, 
         MICAWB_HUMIDITY, MICAWB_HUMIDITY_TEMP, WAIT_FOR_BUS };

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
    state = POWER_OFF;
    call TimerControl.init();
    call SensorControl.init();
    call BusControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
    // turn the sensor on
    call BusControl.start();
    HUMIDITY_POWER_ON();
    state = WARM_UP;
    call Timer.start(TIMER_ONE_SHOT, 80);
    return SUCCESS;
  }

  command result_t SplitControl.stop() {
    state = POWER_OFF;
    // turn the sensor off
    call SensorControl.stop();
    HUMIDITY_POWER_OFF();
    post stopDone();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    if (state == WARM_UP) {
      state = IDLE;
      post startDone();
    }
    else if (state == SAMPLE) {
      if (id == MICAWB_HUMIDITY)
        return call HumSensor.getData();
      else if (id == MICAWB_HUMIDITY_TEMP)
        return call TempSensor.getData();
    }
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

  event result_t BusArbitration.busFree() {
    if (state == WAIT_FOR_BUS) {
      if (call BusArbitration.getBus()) {
        state = SAMPLE;
        call SensorControl.start();
        return call Timer.start(TIMER_ONE_SHOT, 11);
      }
    }
    return SUCCESS;
  }


  async command result_t Humidity.getData() {
    if (state == IDLE)
    {
      state = SAMPLE;
      id = MICAWB_HUMIDITY;
      if (call BusArbitration.getBus()) {
        call SensorControl.start();
        return call Timer.start(TIMER_ONE_SHOT, 11);
      }
      else {
        state = WAIT_FOR_BUS;
      }
    }
    state = IDLE;
    return FAIL;
  }

  async command result_t Temperature.getData() {
    if (state == IDLE)
    {
      state = SAMPLE;
      id = MICAWB_HUMIDITY_TEMP;
      if (call BusArbitration.getBus()) {
        call SensorControl.start();
        return call Timer.start(TIMER_ONE_SHOT, 11);
      }
      else {
         state = WAIT_FOR_BUS;
      }
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
    if (state == SAMPLE) {
	state = IDLE;
        call SensorControl.stop();
        call BusArbitration.releaseBus();
	signal Temperature.dataReady(data);
    }
    return SUCCESS;
  }

  async event result_t HumSensor.dataReady(uint16_t data) {
    if (state == SAMPLE) {
	state = IDLE;
        call SensorControl.stop();
        call BusArbitration.releaseBus();
	signal Humidity.dataReady(data);
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
    call BusArbitration.releaseBus();
    return signal HumidityError.error(token);
  }

  event result_t TempError.error(uint8_t token) {
    state = IDLE;
    call SensorControl.stop();
    call BusArbitration.releaseBus();
    return signal TemperatureError.error(token);
  }

  default event result_t HumidityError.error(uint8_t token) { return SUCCESS; }

  default event result_t TemperatureError.error(uint8_t token) { return SUCCESS; }

}

