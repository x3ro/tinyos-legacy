

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */

module testintersemaM {

   provides interface StdControl;

   uses {

     interface HLSensor as Intersema5534AP;
     interface Leds;
   }
}

implementation {

#include "intersema_5534ap.h"
#include "SODebug.h"  
#define DBG_USR2 1


  command result_t StdControl.init() {

    init_debug();
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Intersema5534AP.startSampling();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

    event result_t Intersema5534AP.powerOnDone() {
      return SUCCESS;
    }

    event result_t Intersema5534AP.powerOffDone() {
      return SUCCESS;
    }

    event result_t Intersema5534AP.dataReady(void * userdata) {

      intersema5534ap_data_msg * msg = (intersema5534ap_data_msg*)userdata;
      uint16_t baro_presdata;
      uint16_t tempdata;
      float temp;
      float baro_pres;

      baro_presdata = msg->baro_presdata;
      tempdata = msg->tempdata;
      temp = msg->temp;
      baro_pres = msg->baro_pres;

      call Leds.greenToggle();
      SODbg(DBG_USR2, "$Pressure: Temp(adc): %i  Press(adc): %i  Temp(degCx10): %i  Press(mbar): %i \r\n", tempdata,baro_presdata,(int)temp, (int)baro_pres);

      return SUCCESS;
    }

    async event result_t Intersema5534AP.error(uint16_t error_code) {
      return SUCCESS;
    }

}
