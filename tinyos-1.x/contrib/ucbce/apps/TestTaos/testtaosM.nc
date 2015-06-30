
/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */

module testtaosM {

   provides interface StdControl;

   uses {

     interface HLSensor as TAOS;
     interface Leds;
   }
}

implementation {

#include "taos_tsl250rd.h"
#include "SODebug.h"  
#define DBG_USR2 1


  command result_t StdControl.init() {
    init_debug();
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {

    call TAOS.powerOn(TAOS_POWER_ON);
    //call TAOS.setSamplingInterval(2500);
    //call TAOS.startSampling();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

    event result_t TAOS.powerOnDone() {
      return SUCCESS;
    }

    event result_t TAOS.powerOffDone() {
      return SUCCESS;
    }

    event result_t TAOS.dataReady(void * userdata) {

      taos_tsl250rd_data_msg * data_msg =  (taos_tsl250rd_data_msg*)userdata;

      uint8_t channel;
      uint16_t taos_data;
      uint16_t cord;
      uint16_t step;
      uint16_t adc;
      float lux;

      channel = data_msg->channel;
      taos_data  = data_msg->taos_data;
      cord = data_msg->cord;
      step = data_msg->step;
      adc = data_msg->adc;
      lux = data_msg->lux;

      call Leds.greenToggle();

      SODbg(DBG_USR2, "$Taos Ch%i data: %i Cord: %i Step: %i  ADC Counts: %i Light(lux): %i \r\n", channel, taos_data,cord,step,adc,(int)lux);


      return SUCCESS;
    }


    async event result_t TAOS.error(uint16_t error_code) {

      SODbg(DBG_USR2, "OVERFLOW\r\n");
      return SUCCESS;
    }

}
