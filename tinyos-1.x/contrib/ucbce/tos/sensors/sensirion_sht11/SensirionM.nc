
/******************************************************************************
 * Measures MTS400/420 weatherboard sensors & gps and converts to engineering units
 * were possible. 
 *-----------------------------------------------------------------------------
 * Output results through mica2 uart port. Connect serial cable from programming
 * board to PC to monitor ouput. Use any terminal monitoring program set for
 * 57600, N,8,1
 *
 * NOTE:  
 * No real power strategy; just turns sensors on sequentially.
 * Should add BusArbitration routines, like mica2dotwb for better power control
 *****************************************************************************/


/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 *
 * @url http://firebug.sourceforge.net
 * 
 * @author David. M. Doolin
 */



module SensirionM {

  provides {

    interface StdControl;
    interface HLSensor;
  }

  uses {

//Sensirion
    interface SplitControl as TempHumControl;
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;

    interface Timer;
    interface Leds;
  }
}

implementation {

#include "sensirion_sht11.h"
#include "SODebug.h"  
#define DBG_USR2 0

  enum {START, BUSY, HUMIDITY_DONE};

  
  char count;

  sht11data_msg data_msg;

  uint16_t HumData;
  uint8_t  state;
  


  
  command result_t StdControl.init() {

    //init_debug();
    call Leds.init();
    call TempHumControl.init();    //init Sensirion
    SODbg(DBG_USR2, "SensirionM.StdControl.init()...\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {

    call HumidityError.enable();       //in case Sensirion doesn't respond
    call TemperatureError.enable();    //  "

    state = START;

    SODbg(DBG_USR2, "SensirionM.StdControl.start()...\n");

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    return SUCCESS;
  }

/******************************************************************************
 * Timer fired, test GPS, humidity/temp
 * async for test only
 *****************************************************************************/
  event result_t Timer.fired() {

    call TempHumControl.start();
    return SUCCESS;
  }


  
  task void sensorDataready() {

      signal HLSensor.dataReady(&data_msg);
  }


/******************************************************************************
 * Sensirion SHT11 humidity/temperature sensor
 * - Humidity data is 12 bit:
 *     Linear calc (no temp correction)
 *        fRH = -4.0 + 0.0405 * data -0.0000028 * data^2     'RH linear
 *     With temperature correction:
 *        fRH = (fTemp - 25) * (0.01 + 0.00008 * data) + fRH        'RH true
 * - Temperature data is 14 bit
 *     Temp(degC) = -38.4 + 0.0098 * data
 *****************************************************************************/
 
   async event result_t Temperature.dataReady(uint16_t data) {

      float fTemp, fHumidity;

      fTemp = -38.4 + 0.0098*(float)data;
      atomic {
         fHumidity =  -4.0 + 0.0405 * HumData -0.0000028 * HumData * HumData;  
         fHumidity= (fTemp-25.0)* (0.01 + 0.00008 * HumData) + fHumidity;
      }


      atomic {
        data_msg.tempdata = data;
        data_msg.rel_humdata = HumData;
        data_msg.temp = fTemp;
        data_msg.rel_hum = fHumidity;
      }

      signal HLSensor.dataReady(&data_msg);

      //post sensorDataready();

      fTemp = 10*fTemp; 
      //SODbg(DBG_USR2, "Humidity: Temp(adc): %i  Humidity(adc): %i  Temp(degCx10): %i  Humidity(%): %i \n", data,HumData,(int)fTemp, (int)fHumidity);


      //call TempHumControl.stop();
        //call HLSensor.powerOff();

      return SUCCESS;
   }

  async event result_t Humidity.dataReady(uint16_t data) {

    atomic { 
       HumData = data;
    }
    return call Temperature.getData();
  }

  event result_t TempHumControl.startDone() {
    call Humidity.getData();
    return SUCCESS;
  }
  
  event result_t TempHumControl.initDone() {
    return SUCCESS;
  }

  event result_t TempHumControl.stopDone() {

    state = HUMIDITY_DONE;
    SODbg(DBG_USR2, "SensirionM.TempHumControl.stopDone()...\n");
    return SUCCESS;
  }

  event result_t HumidityError.error(uint8_t token) {

    call Temperature.getData();
    return SUCCESS;
  }


  event result_t TemperatureError.error(uint8_t token) {

    call TempHumControl.stop();
    return SUCCESS;
  }

  ///////////////////////////////////////////////////////////
    command result_t HLSensor.powerOn(uint8_t power_level) {
   
      call StdControl.start();
      call TempHumControl.start();
      return SUCCESS;
    }

    default event result_t HLSensor.powerOnDone() {
      return SUCCESS;
    }

    command result_t HLSensor.init() {

      //call StdControl.init();
      call TempHumControl.init();
      return SUCCESS;
    }

    command result_t HLSensor.powerOff() {
     
      SODbg(DBG_USR2, "SensirionM.Sensor.powerOff()...\n");

      atomic {
        call TempHumControl.stop();
      }
      signal HLSensor.powerOffDone();
      return SUCCESS;
    }

    default event result_t HLSensor.powerOffDone() {
      return SUCCESS;
    }

    command result_t HLSensor.setSamplingInterval(uint16_t sampling_rate) {
      return SUCCESS;
    }
    command result_t HLSensor.getSamplingInterval(uint16_t sampling_rate) {
      return SUCCESS;
    }

    command result_t HLSensor.startSampling() {

      call Timer.start(TIMER_REPEAT, 2000);
      return SUCCESS;
    }

    command result_t HLSensor.stopSampling() {
      return SUCCESS;
    }

    command result_t HLSensor.sampleOnce() {
      return SUCCESS;
    }

    default event result_t HLSensor.dataReady(void * userdata) {
      return SUCCESS;
    }

    async default event result_t HLSensor.error(uint16_t) {
      return SUCCESS;
    }

    command result_t HLSensor.loadProgram(uint8_t * program,uint8_t length) {
      return SUCCESS;
    }

}

