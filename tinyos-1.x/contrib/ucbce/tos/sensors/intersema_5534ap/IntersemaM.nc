


/* History:   created 1/25/2001
 *
 *
 */
  

/******************************************************************************
 * Measures MTS400/420 weatherboard sensors & gps and converts to engineering units
 * were possible. 
 *-----------------------------------------------------------------------------
 * Output results through mica2 uart port. Connect serial cable from programming
 * board to PC to monitor ouput. Use any terminal monitoring program set for
 * 57600, N,8,1
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



module IntersemaM {

  provides {
    interface StdControl;
    interface HLSensor;
  }

  uses {

//Intersema
    interface SplitControl as PressureControl;
    //interface StdControl as PressureControl;
    interface ADC as IntersemaTemp;
    interface ADC as IntersemaPressure;
    interface Calibration as IntersemaCal;
    
    interface Timer;
    interface Leds;


  }
}

implementation {

#include "intersema_5534ap.h"
#include "SODebug.h"  
#define DBG_USR2 0

enum {START, BUSY, HUMIDITY_DONE, PRESSURE_DONE, LIGHT_DONE, ACCEL_DONE};

  intersema5534ap_data_msg data_msg;  

  char count;

  uint16_t calibration[6];
  uint16_t C1,C2,C3,C4,C5,C6;      //intersema calibration coefficients
  uint16_t PressureData;
  uint8_t  state;
  
  bool  gps_active;          //true if gps is active

  
  command result_t StdControl.init() {

    init_debug();
    call Leds.init();
    call PressureControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {

      state = START;
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

    call PressureControl.start();
    return SUCCESS;
  }

  task void signalDataReady() {

      signal HLSensor.dataReady(&data_msg);
  }


/******************************************************************************
 * Intersema MS5534A barometric pressure/temperature sensor
 *  - 6 cal coefficients (C1..C6) are extracted from 4, 16 bit,words from sensor
 * - Temperature measurement:
 *     UT1=8*C5+20224
 *     dT=data-UT1
 *     Temp=(degC x10)=200+dT(C6+50)/1024
 * - Pressure measurement:
 *     OFF=C2*4 + ((C4-512)*dT)/1024
 *     SENS=C1+(C3*dT)/1024 + 24576
 *     X=(SENS*(PressureData-7168))/16384 - OFF
 *     Press(mbar)= X/32+250
 *****************************************************************************/
   async event result_t IntersemaTemp.dataReady(uint16_t data) {

      float UT1,dT,Temp;
      float OFF,SENS,X,Press;

      //temperature   
      UT1=8*(float)C5+20224;
      dT = (float)data-UT1;
      Temp = 200.0 + dT*((float)C6+50.0)/1024.0;

      //pressure
      OFF = (float)C2*4 + (((float)C4-512.0)*dT)/1024;
      SENS = (float)C1 + ((float)C3*dT)/1024 + 24576;
      atomic {
         X = (SENS*((float)PressureData-7168.0))/16384 - OFF;
      }
      Press = X/32.0 + 250.0;

      data_msg.baro_presdata = PressureData;
      data_msg.tempdata = data;
      data_msg.temp = Temp;
      data_msg.baro_pres = Press;

      post signalDataReady();

      SODbg(DBG_USR2, "Pressure: Temp(adc): %i  Press(adc): %i  Temp(degCx10): %i  Press(mbar): %i \n",
	               data,PressureData,(int)Temp, (int)Press);
  

      // FIXME: PressureControl is wired to SplitControl in IntersemaPressureM,
      // and called asynchronously from here, which needs to be fixed.
      //call PressureControl.stop();
      return SUCCESS;
  }

  async event result_t IntersemaPressure.dataReady(uint16_t data) {
    atomic {
      PressureData = data;
    }
    return call IntersemaTemp.getData();
  }

  event result_t IntersemaCal.dataReady(char word, uint16_t value) {
    // make sure we get all the calibration bytes
     count++;
   // SODbg(DBG_USR2, " cal word  %i value %x \n",word,value);
    calibration[word-1] = value;

    if (count == 4) {
	  SODbg(DBG_USR2, "Pressure cal words (1..4): %x,%x,%x,%x \n",
	  calibration[0],calibration[1],calibration[2],calibration[3] );
	  atomic {
            C1 = calibration[0] >> 1;
            C2 = ((calibration[2] &  0x3f) << 6) |  (calibration[3] &  0x3f);
	    C3 = calibration[3]  >> 6;
	    C4 = calibration[2]  >> 6;
	    C5 = ((calibration[0] &  1) << 10) |  (calibration[1] >>  6); 
            C6 = calibration[1] &  0x3f;
          }
//	  SODbg(DBG_USR2, "Pressure C1:%x C2:%x C3:%x C4:%x C5:%x C6:%x \n",
//	     C1,C2,C3,C4,C5,C6 );
	  SODbg(DBG_USR2, "Pressure C1:%i C2:%i C3:%i C4:%i C5:%i C6:%i \n",
	     C1,C2,C3,C4,C5,C6 );


     call IntersemaPressure.getData();
    }

    return SUCCESS;
  }

  event result_t PressureControl.initDone() {
    return SUCCESS;
  }

  event result_t PressureControl.stopDone() {
    state = PRESSURE_DONE;
    return SUCCESS;


  }

  event result_t PressureControl.startDone() {
    count = 0;
    call IntersemaCal.getData();
    return SUCCESS;
  }
  ///////////////////////////////////////////////////////////
    command result_t HLSensor.powerOn(uint8_t power_level) {
      call PressureControl.start();
      return SUCCESS;
    }

    default event result_t HLSensor.powerOnDone() {
      return SUCCESS;
    }

    command result_t HLSensor.init() {
      call PressureControl.init();
      return SUCCESS;
    }

    command result_t HLSensor.powerOff() {

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
      call Timer.start(TIMER_REPEAT, 1500);
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

    command result_t HLSensor.loadProgram(uint8_t * program,uint8_t length) {
      return SUCCESS;
    }
      
    async default event result_t HLSensor.error(uint16_t error_code) {
      return SUCCESS;
    }

}

