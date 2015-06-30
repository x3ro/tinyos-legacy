


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


module taosM {

   provides {
     interface StdControl;
     interface HLSensor;
   }

   uses {

      interface Timer;
      interface Leds;

      interface SplitControl as TaosControl;
      interface ADC          as TaosCh0;
      interface ADC          as TaosCh1;
   }
}


implementation {

#include "taos_tsl250rd.h"
#include "SODebug.h"  
#define DBG_USR2 0

   uint16_t TaosData;
   uint16_t sampling_interval;// = 2000;

   taos_tsl250rd_data_msg data_msg = {0};

   command result_t StdControl.init() {

      atomic {
         TaosData = 0;
      }
      init_debug();
      call Leds.init();

      call TaosControl.init();
      return SUCCESS;
   }

   command result_t StdControl.start() {
     call TaosControl.start();
      return SUCCESS;
   }

   command result_t StdControl.stop() {
     call TaosControl.stop();
     signal HLSensor.powerOffDone();
      return SUCCESS;
   }

   event result_t Timer.fired() {

      SODbg(DBG_USR2, "$taosM.Timer.fired() \r\n") ;
      return SUCCESS;
   }


   task void signalDataready() {

      signal HLSensor.dataReady(&data_msg);
   }

  /**
   * Taos- tsl2250 light sensor
   * Two ADC channels:
   *    ADC Count Value (ACNTx) = INT(16.5*[CV-1]) +S*CV
   *    where CV = 2^^C
   *          C  = (data & 0x7) >> 4
   *          S  = data & 0xF
   * Light level (lux) = ACNT0*0.46*(e^^-3.13*R)
   *          R = ACNT1/ACNT0
   */
   /**
    * @todo There is some inconsistent masking with TaosData and data
    * which should be cleaned up for passing around.
    */
   /**
    * @todo Find a way to handle overflow.
    */
   async event result_t TaosCh1.dataReady(uint16_t data) {

      uint16_t CV1,CH1,ST1,ACNT0,ACNT1;
      float CNT1,R,Lux;

	
      atomic {
         ST1 = TaosData & 0xf;
      }
      atomic {
         CH1 = (TaosData & 0x70) >> 4;
      }
      CV1 = 1 << CH1;
      CNT1 = (int)(16.5*(CV1-1)) + ST1*CV1;
      ACNT0 = (int)CNT1;
     
      atomic {
         if (TaosData == 0xff) {
           signal HLSensor.error(0);
            SODbg(DBG_USR2, "Taos Ch0 data: OVERFLOW \n") ;
         }
      }


      atomic {
        data_msg.channel = 0;
        data_msg.taos_data = TaosData & 0x0FF;
        data_msg.cord = CH1;
        data_msg.step = ST1;
        data_msg.adc = ACNT0;
        data_msg.lux = 0;
      }

      signal HLSensor.dataReady(&data_msg);
      //post signalDataready();

      //SODbg(DBG_USR2, "Taos Ch0 data: %i Cord: %i Step: %i  ADC Counts: %i \n", TaosData & 0x0FF, CH1,ST1,ACNT0);
	
      data = data & 0xff;
      ST1 = data & 0xf;
      CH1 = (data & 0x70) >> 4;
      CV1 = 1 << CH1;
      CNT1 = (int)(16.5*(CV1-1)) + ST1*CV1;
      ACNT1 = (int)CNT1;
      R = (float)ACNT1/(float)ACNT0;
      Lux = (float)ACNT0*0.46/exp(3.13*R);
      if (data == 0xff) {
           signal HLSensor.error(0);
         SODbg(DBG_USR2, "Taos Ch1 data: OVERFLOW \n");
      }

      atomic {
        data_msg.channel = 1;
        data_msg.taos_data = data;
        data_msg.cord = CH1;
        data_msg.step = ST1;
        data_msg.adc = ACNT1;
        data_msg.lux = Lux;
      }

      signal HLSensor.dataReady(&data_msg);
      //post signalDataready();

      //SODbg(DBG_USR2, "Taos Ch1 data: %i Cord: %i Step: %i  ADC Counts: %i Light(lux): %i \n", data & 0x0FF, CH1,ST1,ACNT1,(int)Lux);

      //call TaosControl.stop();
      return SUCCESS;
   }

   async event result_t TaosCh0.dataReady(uint16_t data) {

      atomic {
         TaosData = data & 0xff;
      }
      //SODbg(DBG_USR2, "Got Taos Ch0 data \n") ;
      return call TaosCh1.getData();
   }

   event result_t TaosControl.startDone(){
      return call TaosCh0.getData();
   }
  
   event result_t TaosControl.initDone() {
      return SUCCESS;
   }

   event result_t TaosControl.stopDone() {

      signal HLSensor.powerOffDone();
      return SUCCESS;
   }


  ///////////////////////////////////////////////////////////
    command result_t HLSensor.powerOn(uint8_t power_level) {

      call TaosControl.start();
      return SUCCESS;
    }

    default event result_t HLSensor.powerOnDone() {
      return SUCCESS;
    }

    command result_t HLSensor.init() {
      return SUCCESS;
    }

    command result_t HLSensor.powerOff() {

      call TaosControl.stop();
      signal HLSensor.powerOffDone();
      return SUCCESS;
    }

    default event result_t HLSensor.powerOffDone() {
      return SUCCESS;
    }

    command result_t HLSensor.setSamplingInterval(uint16_t interval) {

      atomic {
        sampling_interval = interval;
      }
      return SUCCESS;
    }

    command result_t HLSensor.getSamplingInterval(uint16_t sampling_rate) {
      return SUCCESS;
    }

    command result_t HLSensor.startSampling() {
      SODbg(DBG_USR2, "$taosM.Sensor.startSampling() \r\n") ;
      call TaosControl.start();    
      call Timer.start(TIMER_REPEAT, sampling_interval);
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

    default async event result_t HLSensor.error(uint16_t error_code) {
      return SUCCESS;
    }

    command result_t HLSensor.loadProgram(uint8_t * program,uint8_t length) {
      return SUCCESS;
    }
}

