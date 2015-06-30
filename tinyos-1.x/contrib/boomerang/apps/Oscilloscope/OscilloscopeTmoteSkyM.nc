// $Id: OscilloscopeTmoteSkyM.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

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
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

/**
 * Implementation of Oscilloscope for Tmote Sky.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module OscilloscopeTmoteSkyM
{
  provides interface StdControl;
  uses {
    interface Timer;
    interface Leds;
    
    interface SplitControl as HumidityControl;

    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADC as TSR;
    interface ADC as PAR;
    interface ADC as InternalTemperature;
    interface ADC as InternalVoltage;

    interface Oscope as OHumidity;
    interface Oscope as OTemperature;
    interface Oscope as OTSR;
    interface Oscope as OPAR;
    interface Oscope as OInternalTemperature;
    interface Oscope as OInternalVoltage;

    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
  }
}
implementation
{

  enum {
    OSCOPE_DELAY = 10,
  };

  enum {
    HUMIDITY,
    TEMPERATURE,
    TSRSENSOR,
    PARSENSOR,
    ITEMP,
    IVOLT
  };

  norace uint16_t humidity, temperature, tsr, par, itemp, ivolt;
  norace int state;

  /**
   * Used to initialize this component.
   */
  command result_t StdControl.init() {
    call Leds.init();
    call Leds.set(0);
    state = HUMIDITY;

    //turn on the sensors so that they can be read.
    call HumidityControl.init();

    return SUCCESS;
  }

  event result_t HumidityControl.initDone() {
    return SUCCESS;
  }

  /**
   * Starts the SensorControl component.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.start() {
    call HumidityControl.start();
    return SUCCESS;
  }

  event result_t HumidityControl.startDone() {
    call HumidityError.enable();
    call TemperatureError.enable();
    call Timer.start( TIMER_ONE_SHOT, 250 );
    return SUCCESS;
  }

  /**
   * Stops the SensorControl component.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.stop() {
    call HumidityControl.stop();
    call Timer.stop();
    return SUCCESS;
  }

  event result_t HumidityControl.stopDone() {
    call HumidityError.disable();
    call TemperatureError.disable();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    // set a timeout in case a task post fails (rare)
    call Timer.start(TIMER_ONE_SHOT, 100);
    switch(state) {
    case HUMIDITY:
      call Humidity.getData();
      break;
    case TEMPERATURE:
      call Temperature.getData();
      break;
    case TSRSENSOR:
      call TSR.getData();
      break;
    case PARSENSOR:
      call PAR.getData();
      break;
    case ITEMP:
      call InternalTemperature.getData();
      break;
    case IVOLT:
      call InternalVoltage.getData();
      break;
    default:
      call Timer.start(TIMER_ONE_SHOT, 10);
    }      
    return SUCCESS;
  }

  task void putHumidity() {
    call OHumidity.put(humidity);
    call Leds.yellowOn();
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putTemperature() {
    call OTemperature.put(temperature);
    call Leds.greenOn();
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putTSR() {
    call OTSR.put(tsr);
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putPAR() {
    call OPAR.put(par);
    call Leds.redOn();
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putIntTemp() {
    call OInternalTemperature.put(itemp);
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putIntVoltage() {
    call OInternalVoltage.put(ivolt);
    call Leds.set(0);
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }

  async event result_t Humidity.dataReady(uint16_t data) {
    humidity = data;
    post putHumidity();
    state = TEMPERATURE;
    return SUCCESS;
  }

  event result_t HumidityError.error(uint8_t token) {
    humidity = 0;
    post putHumidity();
    state = TEMPERATURE;
    return SUCCESS;
  }

  async event result_t Temperature.dataReady(uint16_t data) {
    temperature = data;
    post putTemperature();
    state = TSRSENSOR;
    return SUCCESS;
  }

  event result_t TemperatureError.error(uint8_t token) {
    temperature = 0;
    post putTemperature();
    state = TSRSENSOR;
    return SUCCESS;
  }

  async event result_t TSR.dataReady(uint16_t data) {
    tsr = data;
    post putTSR();
    state = PARSENSOR;
    return SUCCESS;
  }

  async event result_t PAR.dataReady(uint16_t data) {
    par = data;
    post putPAR();
    state = ITEMP;
    return SUCCESS;
  }

  async event result_t InternalTemperature.dataReady(uint16_t data) {
    itemp = data;
    post putIntTemp();
    state = IVOLT;
    return SUCCESS;
  }

  async event result_t InternalVoltage.dataReady(uint16_t data) {
    ivolt = data;
    post putIntVoltage();
    state = HUMIDITY;
    return SUCCESS;
  }
}
