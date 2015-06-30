

/**
 * Displays ADXL output. 
 *
 * Output results through mica2 uart port.
 * Connect serial cable from programming
 * board to PC to monitor ouput. Use any
 * terminal monitoring program set for
 * 57600, N,8,1
 *
 * NOTE:  
 * No real power strategy; just turns sensors on sequentially.
 * Should add BusArbitration routines, like mica2dotwb
 * for better power control
 */


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



module adxlM {

   provides {
     interface StdControl;
     interface HLSensor;
   }

   uses {

      interface Timer;
      interface Leds;

      interface StdControl    as AccelControl;
      interface I2CSwitchCmds as AccelCmd;
      interface ADC           as AccelX;
      interface ADC           as AccelY;
   }
}

implementation {

#include "adxl202je.h"
#include "SODebug.h"  
#define DBG_USR2 0

#define ACCEL_POWER_OFF 0
#define ACCEL_POWER_ON  1

   enum {START, BUSY};

   uint16_t AccelData;
  
   adxl202je_data_msg data_msg;


   command result_t StdControl.init() {

     //init_debug();
      call Leds.init();

      call AccelControl.init();  
      return SUCCESS;
   }

   command result_t StdControl.start() {

      //call Timer.start(TIMER_REPEAT, 500);
      return SUCCESS;
   }

   command result_t StdControl.stop() {

      return SUCCESS;
   }

   event result_t Timer.fired() {

      call AccelCmd.PowerSwitch(ACCEL_POWER_ON);
      return SUCCESS;
   }

/******************************************************************************
 * ADXL202E Accelerometer
 * At 3.0 supply this sensor's sensitivty is ~167mv/g
 *        0 g is at ~1.5V or ~VCC/2 - this varies alot.
 *        For an accurate calibration measure each axis at +/- 1 g and
 *        compute the center point (0 g level) as 1/2 of difference.
 * Note: this app doesn't measure the battery voltage, it assumes 3.2 volts
 * To getter better accuracy measure the battery voltage as this effects the
 * full scale of the Atmega128 ADC.
 * bits/mv = 1024/(1000*VBATT)
 * bits/g  = 1024/(1000*VBATT)(bits/mv) * 167(mv/g)
 *         = 171/VBATT (bits/g)
 * C       = 0.171/VBATT (bits/mg)
 * Accel(mg) ~ (ADC DATA - 512) /C
 *****************************************************************************/  
   async event result_t AccelY.dataReady(uint16_t data){

      float Accel, C;
      float xdata, ydata;
      float VBATT = 3.2;
	
      C = 0.171/VBATT;
      atomic {
         Accel =  ((float)AccelData - 512.0)/C;
         //SODbg(DBG_BOOT, "AccelX data %i AcceX(mg) %i \n",AccelData, (int)Accel);
      }

      xdata = Accel;
      Accel = ((float)data - 512.0)/C;
      //SODbg(DBG_BOOT, "AccelY data %i AcceY(mg) %i \n",data, (int)Accel);
      ydata = Accel;

      atomic {
        data_msg.xdata = xdata;
        data_msg.ydata = ydata;
      }
      signal HLSensor.dataReady(&data_msg);

      call AccelCmd.PowerSwitch(ACCEL_POWER_OFF);
      return SUCCESS;
   }
 


   async  event result_t AccelX.dataReady(uint16_t  data){

      atomic {
         AccelData = data;
      }
      call AccelY.getData();
      return SUCCESS;
   }

   event result_t AccelCmd.SwitchesSet(uint8_t PowerState) {

      if (PowerState) {
         call AccelX.getData();
      } 
      return SUCCESS;
   }
  ///////////////////////////////////////////////////////////
    command result_t HLSensor.powerOn(uint8_t power_level) {
      return SUCCESS;
    }

    default event result_t HLSensor.powerOnDone() {
      return SUCCESS;
    }

    command result_t HLSensor.init() {
      return SUCCESS;
    }

    command result_t HLSensor.powerOff() {
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

    command result_t HLSensor.loadProgram(uint8_t * program, uint8_t length) {
      return SUCCESS;
    }
}

