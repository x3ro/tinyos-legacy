

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */

module testsensirionM {

   provides interface StdControl;

   uses {

     interface HLSensor as SHT11;
     interface Leds;
   }
}

implementation {

#include "sensirion_sht11.h"
#include "SODebug.h"  
#define DBG_USR2 1


  command result_t StdControl.init() {

    init_debug();
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {

    call SHT11.startSampling();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

    event result_t SHT11.powerOnDone() {
      return SUCCESS;
    }

    event result_t SHT11.powerOffDone() {
      return SUCCESS;
    }

    event result_t SHT11.dataReady(void * userdata) {

      sht11data_msg * msg = (sht11data_msg*)userdata;
      uint16_t rel_humdata;
      uint16_t tempdata;
      float temp;
      float rel_hum;

      rel_humdata = msg->rel_humdata;
      tempdata = msg->tempdata;
      temp = 10*msg->temp;
      rel_hum = msg->rel_hum;

      call Leds.greenToggle();
      SODbg(DBG_USR2, "$Humidity: Temp(adc): %i  Humidity(adc): %i  Temp(degCx10): %i  Humidity(%): %i \r\n",tempdata,rel_humdata,(int)temp, (int)rel_hum);
      return SUCCESS;
    }

    async event result_t SHT11.error(uint16_t) {
      return SUCCESS;
    }

}
