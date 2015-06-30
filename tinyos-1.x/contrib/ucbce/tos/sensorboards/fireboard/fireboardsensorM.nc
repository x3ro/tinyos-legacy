/* -*- Mode: C; c-basic-indent: 3; indent-tabs-mode: nil -*- */ 


/**
 * Driver for Crossbow, Inc. MTS420CA "fireboard", developed
 * in part for the NSF ITR funded FireBug project:
 * 
 * @url http://firebug.sourceforge.net
 *
 * @author David M. Doolin
 *
 */

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */

module fireboardsensorM {

   provides {

      interface Data[uint8_t id];
      interface StdControl;
   }

   uses {

      interface Leds;

      interface Timer         as GlobalTimer;

      interface Sensor       as LeadTek9546;
      interface Sensor       as SHT11;
      interface Sensor       as TAOS;
      interface Sensor       as Intersema5534AP;
   }
}

// For convenience.
/*
typedef struct _firedata {
    uint16_t addr;
    uint16_t cnt;
    float temp;
    float rel_hum;
    float baro_pres;
    float lux;
} Firedata_msg;
*/

implementation {

#include "taos_tsl250rd.h"
#include "sensirion_sht11.h"
#include "intersema_5534ap.h"
#include "SODebug.h"  
#define DBG_USR2 1


   Firedata_msg firemsg = {0};
   GGA_Msg gga_msg      = {0};

   char state1;

   enum {IDLE, BUSY, 
         GPS_DONE, SHT_DONE,
         PRESSURE_DONE, LIGHT_DONE};
       

   default event result_t Data.dataReady[uint8_t id](void * msg) {
      return SUCCESS;
   }

   command result_t StdControl.init() {

      state1 = IDLE;
      init_debug();
      //call Leds.init();
      return SUCCESS;
   }

   command result_t StdControl.start() {

     //call Leds.redOn();
      call GlobalTimer.start(TIMER_REPEAT, 3000) ;
      //SODbg(DBG_USR2, "fireboardsensorM.StdControl.start()\n");
      return SUCCESS;
   }

   command result_t StdControl.stop() {

      call GlobalTimer.stop();
      return SUCCESS;
   }


   event result_t GlobalTimer.fired() {

     //SODbg(DBG_USR2, "fireboardsensorM.GlobalTimer.fired()\n");


     switch (state1) {
       
     case BUSY:
       break;
       
     case IDLE:
       state1 = BUSY;
       call LeadTek9546.powerOn();
       if (signal Data.dataReady[0]((void*)(&gga_msg))) {
         state1 = GPS_DONE;
       }
       break;

     case GPS_DONE:
       state1 = BUSY;
       call SHT11.powerOn();
       break;

     case SHT_DONE:
       state1 = BUSY;
       call Intersema5534AP.powerOn();
       break;

     case PRESSURE_DONE:
       state1 = BUSY;
       call TAOS.powerOn();    
       break;

     case LIGHT_DONE:
       state1 = BUSY;
       if (signal Data.dataReady[1](&firemsg)) {
          state1 = IDLE;
       }
       break;

     default:
       break;
     }

      return SUCCESS;
   }




  /** Sensirion SHT11 event handlers.
   */
   event result_t SHT11.powerOnDone() {return SUCCESS;}

   event result_t SHT11.powerOffDone() {

     //SODbg(DBG_USR2, "fireboardsensorM.SHT11.stopDone()\n")
     state1 = SHT_DONE;
     return SUCCESS;
   }

   async event result_t SHT11.error(uint16_t error_code) {return SUCCESS;}

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

      //call Leds.greenToggle();
      SODbg(DBG_USR2, "$SHT11.dataReady: Humidity: Temp(adc): %i  Humidity(adc): %i  Temp(degCx10): %i  Humidity(%): %i \r\n",tempdata,rel_humdata,(int)temp, (int)rel_hum);

      atomic {
        call SHT11.powerOff();
      }

     return SUCCESS;
   }




   /** Intersema pressure and temperature sensor.
    */
   event result_t Intersema5534AP.powerOnDone() {return SUCCESS;}

   event result_t Intersema5534AP.powerOffDone() {
     state1 = PRESSURE_DONE;
     return SUCCESS;
   }
   
   async event result_t Intersema5534AP.error(uint16_t error_code) {return SUCCESS;}

   event result_t Intersema5534AP.dataReady(void * userdata) {

      intersema5534ap_data_msg * msg = (intersema5534ap_data_msg*)userdata;  
      
#if DBG_USR2
      uint16_t baro_presdata;
      uint16_t tempdata;
      float baro_pres;
      float temp;

      baro_presdata = msg->baro_presdata;
      tempdata = msg->tempdata;
      temp = msg->temp;
      baro_pres = msg->baro_pres;

      SODbg(DBG_USR2, "$Pressure: Temp(adc): %i  Press(adc): %i  Temp(degCx10): %i  Press(mbar): %i \r\n", tempdata,baro_presdata,(int)temp, (int)baro_pres);
#endif

      atomic {
        call Intersema5534AP.powerOff();
      }

     return SUCCESS;
   }




   event result_t LeadTek9546.powerOnDone() {return SUCCESS;}

   event result_t LeadTek9546.powerOffDone() {

     //state1 = GPS_DONE;
     return SUCCESS;
   }

   async event result_t LeadTek9546.error(uint16_t error_code) {return SUCCESS;}

   event result_t LeadTek9546.dataReady(void * userdata) {

      int i;

      GPS_Msg * gps_data = (GPS_Msg*)userdata;

      SODbg(DBG_USR2, "\r\n");  
      for (i=0; i<=gps_data->data[0]; i++) {
        /** UARTPutChar is an SODebug function.
         * FIXME: Change this to use a char[].
         */
         UARTPutChar(gps_data->data[i]);
      }  
      SODbg(DBG_USR2, "\r\n");  

      //call Leds.greenToggle();
      // Use this if writing to serial port instead of leadtek
      // monitor software.
#if 0
      SODbg(DBG_USR2, "=================================================\n");
      SODbg(DBG_USR2, "DataCollectM.GPS.dataReady()\n");
      SODbg(DBG_USR2, "Hours: %i\n",(int)(10*gga_msg->hours));      
      SODbg(DBG_USR2, "Minutes: %i\n",(int)(10*gga_msg->minutes));      
      SODbg(DBG_USR2, "Decimal seconds: %i\n",(int)(10*gga_msg->dec_sec));      
      SODbg(DBG_USR2, "Latitude degrees: %i\n",(int)(10*gga_msg->Lat_deg));      
      SODbg(DBG_USR2, "Latitude decimal minutes: %i\n",(int)(10*gga_msg->Lat_dec_min));      
      SODbg(DBG_USR2, "Longitude degrees: %i\n",(int)(10*gga_msg->Long_deg));      
      SODbg(DBG_USR2, "Longitude decimal minutes: %i\n",(int)(10*gga_msg->Long_dec_min));   
      SODbg(DBG_USR2, "NSEWind: %i\n",(int)(10*gga_msg->NSEWind));      
      SODbg(DBG_USR2, "=================================================\n");
#endif

      //SODbg(DBG_USR2, "fireboardsensor.LeadTek.dataReady()\n");
     atomic {
       call LeadTek9546.powerOff();
     }
     return SUCCESS;
   }




  /** Taos TSL250RD light intensity sensor events.
   */
   event result_t TAOS.powerOnDone() {return SUCCESS;}

   event result_t TAOS.powerOffDone() {
   
     //SODbg(DBG_USR2, "fireboardsensor.TAOS.powerOffDone()\n");
     state1 = LIGHT_DONE;
     return SUCCESS;
   }

   async event result_t TAOS.error(uint16_t error_code) {return SUCCESS;}

   event result_t TAOS.dataReady(void * userdata) {

      taos_tsl250rd_data_msg * data_msg =  (taos_tsl250rd_data_msg*)userdata;
      float lux = 0;

#if DBG_USR2
      uint8_t channel;
      uint16_t taos_data;
      uint16_t cord;
      uint16_t step;
      uint16_t adc;


      channel = data_msg->channel;
      taos_data  = data_msg->taos_data;
      cord = data_msg->cord;
      step = data_msg->step;
      adc = data_msg->adc;
      lux = data_msg->lux;

      //call Leds.greenToggle();

      SODbg(DBG_USR2, "$Taos Ch%i data: %i Cord: %i Step: %i  ADC Counts: %i Light(lux): %i \r\n",
            channel, taos_data,cord,step,adc,(int)lux);
#endif

      firemsg.lux = lux;
      atomic {
        call TAOS.powerOff();
      }
      return SUCCESS;
   }

}

