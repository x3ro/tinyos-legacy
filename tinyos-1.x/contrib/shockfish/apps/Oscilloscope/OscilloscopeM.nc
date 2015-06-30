// $Id: OscilloscopeM.nc,v 1.6 2005/09/02 19:23:14 rogmeier Exp $

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
 */
/**
 * @author Henri Dubois-Ferriere 
 * (directly derived from Joe Polastre's Oscilloscope in contrib/moteiv/)
 */

includes sensorboard;

module OscilloscopeM
{
  provides interface StdControl;
  uses {
    interface Timer;
    interface Leds;

    interface SplitControl as HumidityControl;

    interface ADC as Humidity;
    interface ADC as Temperature; 
    interface ADC as ExTempADC;
    interface ADC as LightADC;
    interface ADC as VoltageADC;
    interface ADC as InternalTempADC;
    interface ADC as InternalVoltageADC;
    
    interface Oscope as OHumidity;
    interface Oscope as OTemperature;
    interface Oscope as OExTemp;
    interface Oscope as OVoltage;
    interface Oscope as OLight;
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
    EX_TEMP,
    VOLTAGE,
    LIGHT,
    ITEMP,
    IVOLT
  };

  norace uint16_t humidity, temperature, ex_temp, voltage, light, itemp, ivolt;
  norace int state;

  /**
   * Used to initialize this component.
   */
  command result_t StdControl.init() {
    call Leds.init();
    call Leds.set(0);
    
  TOSH_MAKE_HUM_SCL_OUTPUT();
  TOSH_MAKE_HUM_SDA_OUTPUT();
  TOSH_MAKE_HUM_PWR_OUTPUT();
    
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

  /**
   * Signalled when the clock ticks.
   * @return The result of calling TempADC.getData().
   */
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
    case EX_TEMP:
      call ExTempADC.getData();
      break;
    case VOLTAGE:
      call VoltageADC.getData();
      break;
    case LIGHT:
      call LightADC.getData();
      break;
    case ITEMP:
      call InternalTempADC.getData();
      break;
    case IVOLT:
      call InternalVoltageADC.getData();
      break;
    default:
      call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
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
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putExTemp() {
    call OExTemp.put(temperature);
    call Leds.greenOn();
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putVoltage() {
    call OVoltage.put(voltage);
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putLight() {
    call OLight.put(light);
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
    state = EX_TEMP;
    return SUCCESS;
  }

  event result_t TemperatureError.error(uint8_t token) {
    temperature = 0;
    post putTemperature();
    state = EX_TEMP;
    return SUCCESS;
  }
  
  async event result_t ExTempADC.dataReady(uint16_t data) {
    temperature = data;
    post putExTemp();
    state = VOLTAGE;
    return SUCCESS;
  }

  async event result_t VoltageADC.dataReady(uint16_t data) {
    voltage = data;
    post putVoltage();
    state = LIGHT;
    return SUCCESS;
  }

  async event result_t LightADC.dataReady(uint16_t data) {
    light = data;
    post putLight();
    state = ITEMP;
    return SUCCESS;
  }


  async event result_t InternalTempADC.dataReady(uint16_t data) {
    itemp = data;
    post putIntTemp();
    state = IVOLT;
    return SUCCESS;
  }

  async event result_t InternalVoltageADC.dataReady(uint16_t data) {
    ivolt = data;
    post putIntVoltage();
    state = HUMIDITY;
    return SUCCESS;
  }

}

