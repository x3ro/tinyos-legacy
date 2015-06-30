
/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */

module testadxlM {

   provides interface StdControl;

   uses {

     interface HLSensor as ADXL202JE;
     interface Leds;
   }
}

implementation {

#include "adxl202je.h"
#include "SODebug.h"  
#define DBG_USR2 1


  command result_t StdControl.init() {

    init_debug();
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

    event result_t ADXL202JE.powerOnDone() {
      return SUCCESS;
    }

    event result_t ADXL202JE.powerOffDone() {
      return SUCCESS;
    }

    event result_t ADXL202JE.dataReady(void * userdata) {

      adxl202je_data_msg * msg = (adxl202je_data_msg*)userdata;

      
      SODbg(DBG_USR2, "$ADXL  x: %i, y: %i.\r\n",(int)(msg->xdata),(int)(msg->ydata));
      call Leds.greenToggle();
      return SUCCESS;

    }

    async  event result_t ADXL202JE.error(uint16_t) {
      return SUCCESS;
    }

}
