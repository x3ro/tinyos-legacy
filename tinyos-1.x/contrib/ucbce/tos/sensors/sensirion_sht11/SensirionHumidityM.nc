


/*
 *
 * Authors:		Joe Polastre
 *
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
    interface Leds;
  }
}

implementation {

#include "SODebug.h" 
#define DBG_USR2  0  

  enum {IDLE, BUSY, BUSY_0, BUSY_1, GET_SAMPLE_0, GET_SAMPLE_1,
        OPENSCK, OPENDATA, CLOSESCK, CLOSEDATA,  POWEROFF,
	MAIN_SWITCH_ON, MAIN_SWITCH_OFF, WAIT_SWITCH_ON, WAIT_SWITCH_OFF, TIMER};

  norace char state;
  norace char id;
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

    SODbg(DBG_USR2, "SensirionHumidityM.SplitControl.start() \n", state);

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

    SODbg(DBG_USR2, "SensirionHumidityM.SplitControl.stop() \n", state);

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

    SODbg(DBG_USR2, "SensirionHumidityM.Switch1.setDone() \n", state);

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



  /** FIXME: Change to switch/case, set a return variable, 
   * return after the switch.
   */
  event result_t SwitchI2W.setDone(bool local_result) {
    

    SODbg(DBG_USR2, "SensirionHumidityM.SwitchI2W.setDone: state: %i \n", state);

   if (state == OPENSCK) {                                //SCK line enabled
        state = OPENDATA;
        return call SwitchI2W.set(MICAWB_HUMIDITY_DATA,1);
    } else if (state == OPENDATA) {                       //Data line enabled
        state = TIMER;
        SODbg(DBG_USR2, "SensirionHumidityM.SwitchI2W: Timer Started \n");      

        return call Timer.start(TIMER_ONE_SHOT, 100);
    } else if (state == CLOSESCK) {
        state = CLOSEDATA;
        return call SwitchI2W.set(MICAWB_HUMIDITY_DATA,0);
    } else if (state == CLOSEDATA) {
        
        uint16_t l_result;

        atomic {
           l_result = result;
        }

	    state = IDLE;
	    if (id == MICAWB_HUMIDITY){
	       signal Humidity.dataReady(l_result);         //everything complete, humidity data ready
	    }
	    else if (id == MICAWB_HUMIDITY_TEMP)
	       signal Temperature.dataReady(l_result);     //everything complete, temp data ready
        }
        return SUCCESS;
  }

  event result_t Timer.fired() {


    SODbg(DBG_USR2, "SensirionHumidityM.Timer.fired() \n", state);

       state = BUSY;
      if (id == MICAWB_HUMIDITY)
      {
	      SODbg(DBG_USR2, "SensirionHumidityM.Timer.fired: get humidity data \n"); 
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

    SODbg(DBG_USR2, "SensirionHumidityM.Humidity.getData(), state: \n", state);

    if (state == IDLE) {

      id = MICAWB_HUMIDITY;
      state = OPENSCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,1);
    } 
	state = IDLE;
    return FAIL;
  }

 async command result_t Temperature.getData() {


    SODbg(DBG_USR2, "SensirionHumidityM.Temperature.getData(), state: \n", state);

    if (state == IDLE) 
    {
      id = MICAWB_HUMIDITY_TEMP;
      state = OPENSCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,1);
    }
    state = IDLE;
    return FAIL;
  }

  async default event result_t Humidity.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  async default event result_t Temperature.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  async event result_t TempSensor.dataReady(uint16_t data) {

    atomic {
       result = data;
    }

    if (state == BUSY) {
      state = CLOSESCK;
      return call SwitchI2W.set(MICAWB_HUMIDITY_SCLK,0);
    }
    return SUCCESS;
  }

/******************************************************************************
 * HumSensor.dataReady
 *  -Data ready from humidity sensor
 *  -Start to turn-off SCK,SDA serial lines
 ******************************************************************************/
   async  event result_t HumSensor.dataReady(uint16_t data) {

     //SODbg(DBG_USR2, "SensirionHumidityM.HumSensor.dataReady: data ready \n");

   atomic {
	result = data;
    }

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

