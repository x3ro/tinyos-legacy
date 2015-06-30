/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */


module testgpsM {

   provides interface StdControl;

   uses {

     interface Leds;
     interface HLSensor as LeadTek;
   }
}

implementation {

#include "SODebug.h"  
#define DBG_USR2 1


  command result_t StdControl.init() {


    init_debug();
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {

    call LeadTek.powerOn(LEADTEK_POWER_ON);

    // Loading programs doesn't work yet.
    //call LeadTek.loadProgram((void*)gps_test);
    call LeadTek.loadProgram((uint8_t*)vtg_disable);

#if 0
    if (call LeadTek.loadProgram((void*)gps_test)) {
      SODbg(DBG_USR2, "Loading program succeeded in txBytes.\r\n");  
    } else {
      SODbg(DBG_USR2, "Loading program failed in txBytes.\r\n");  
    }
#endif

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

    event result_t LeadTek.powerOnDone() {
      return SUCCESS;
    }

    event result_t LeadTek.powerOffDone() {
      return SUCCESS;
    }


#define RAW_DATA 1
    event result_t LeadTek.dataReady(void * userdata) {

#if RAW_DATA
      int i;
      GPS_Msg * gps_data = (GPS_Msg*)userdata;

      for (i=0; i<=gps_data->length; i++) {
         UARTPutChar(gps_data->data[i]);
      }  
      SODbg(DBG_USR2, "\r\n");  

#else
      GGA_Msg * gga_msg = (GGA_Msg*)userdata;

      SODbg(DBG_USR2, "$=================================================\r\n");
      SODbg(DBG_USR2, "$testgpsM.LeadTek.dataReady()\r\n");
      SODbg(DBG_USR2, "$Hours: %i\r\n",(int)(gga_msg->hours));      
      SODbg(DBG_USR2, "$Minutes: %i\r\n",(int)(gga_msg->minutes));      
      SODbg(DBG_USR2, "$Decimal seconds: %i\r\n",(int)(100*(gga_msg->dec_sec)));      
      SODbg(DBG_USR2, "$Latitude degrees: %i\r\n",(int)(gga_msg->Lat_deg));      
      SODbg(DBG_USR2, "$Latitude decimal minutes: %i\r\n",(int)(100*(gga_msg->Lat_dec_min)));      
      SODbg(DBG_USR2, "$Longitude degrees: %i\r\n",(int)(gga_msg->Long_deg));      
      SODbg(DBG_USR2, "$Longitude decimal minutes: %i\r\n",(int)(100*(gga_msg->Long_dec_min)));   
      SODbg(DBG_USR2, "$NSEWind: %i\r\n",(gga_msg->NSEWind));      
      SODbg(DBG_USR2, "$=================================================\r\n\r\n");
#endif

      call Leds.greenToggle();

      //call LeadTek.powerOff();

      return SUCCESS;
    }


    async event result_t LeadTek.error(uint16_t error_code) {
      return SUCCESS;
    }

}
