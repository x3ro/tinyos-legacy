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


//  Macros externally tested.
#define extract_num_sats_m(data)     (10*(data[0]-'0') + (data[1]-'0'))
#define extract_hours_m(data)        (10*(data[0]-'0') + (data[1]-'0'))
#define extract_minutes_m(data)      (10*(data[2]-'0') + (data[3]-'0'))
#define extract_dec_sec_m(data)      (10*(data[4]-'0') +  (data[5]-'0') + 0.1*(data[7]-'0') \
                                      + 0.01*(data[8]-'0')                                  \
				      + 0.001*(data[9]-'0'))
#define extract_Lat_deg_m(data)      (10*(data[0]-'0') + (data[1]-'0'))
#define extract_Lat_dec_min_m(data)  (10*(data[2]-'0') +  (data[3]-'0') + 0.1*(data[5]-'0') \
                                      + 0.01*(data[6]-'0') + 0.001*(data[7]-'0') + 0.0001*(data[8]-'0'))
#define extract_Long_deg_m(data)     (100*(data[0]-'0') + 10*(data[1]-'0') + (data[2]-'0'))
#define extract_Long_dec_min_m(data) (10*(data[3]-'0') +  (data[4]-'0') + 0.1*(data[6]-'0') \
				      + 0.01*(data[7]-'0') + 0.001*(data[8]-'0') + 0.0001*(data[9]-'0'))


module gps_driverM {

   provides {

      interface StdControl;
      interface HLSensor;

      command void readGps();


      command uint8_t  extract_hours(char * data);
      command uint8_t  extract_minutes(char * data);
      command float   extract_dec_sec(char * data);
      command uint8_t  extract_Lat_deg(char * data);
      command float extract_Lat_dec_min(char * data);
      command uint8_t  extract_Long_deg(char * data);
      command float extract_Long_dec_min(char * data);
      command uint8_t  extract_NSEWind(char * data);
      command uint8_t  extract_num_sats(char * data);

      command result_t isGGA(uint8_t * data);

      command result_t parse_gga(GPS_Msg * data);
      command uint8_t  get_gps_fix(char * data);

      command void spew_to_uart(GPS_Msg * gps_data);

      command result_t load_gga_struct(char gga_fields[GGA_FIELDS][GPS_CHAR_PER_FIELD]);

      command result_t log_gga_data_to_eeprom(GGAMsg * pGGA);
   }

   uses {


      interface Leds;

      interface StdControl    as SwitchControl;
      interface Switch        as PowerSwitch;
      interface Switch        as IOSwitch;

      interface StdControl    as GpsControl;
      interface I2CSwitchCmds; // as GpsCmd;
      interface BareSendMsg   as GpsSend;
      interface ReceiveMsg    as GpsReceive;
   }
}

implementation {

#include "SODebug.h"  
#define DBG_USR2 0

   uint8_t state;
   uint8_t gps_state;

   GGAMsg gga_msg = {0};
 
   /** This is essentially thread safe, because once it is
    * set, it will only reset to 0.  Read the NMEA specs
    * to determine the values.
    */
   norace bool have_gps_fix = 0;

   enum {IDLE, BUSY, BUSY_0, BUSY_1, GET_SAMPLE_0, GET_SAMPLE_1,
         POWEROFF, TIMER, GPS_WORKING, GPS_FINISHED};


   command result_t StdControl.init() {

     //init_debug();
      call Leds.init();
     /** Control.init in GpsPacket.nc */
      call GpsControl.init();      
      //SODbg(DBG_USR2, "gps_driverM.StdControl.init()\r\n");
      return SUCCESS;
   }

   command result_t StdControl.start() {

     //call Leds.redOn();

      /** Control.start in GpsPacket.nc, calls
       * SwitchControl.start and ByteControl.start()
       */
      call GpsControl.start();
      //SODbg(DBG_USR2, "gps_driverM.StdControl.start()\n");
      return SUCCESS;
   }

   command result_t StdControl.stop() {

      return SUCCESS;
   }


   /** Ok, this function turns on the gps unit for reading,
    * which is turned of elsewhere when the read is finished.
    * If the read isn't finished, the function exits.
    *
    * FIXME: Get rid of this function, move the code into the
    * appropriate Sensor interface function.
    */
   command void readGps() {

      if (gps_state == GPS_WORKING) {
        //SODbg(DBG_USR2, "gps_driverM.readGps(): GPS_WORKING\r\n");
         return;
      }

      /* Implementation is in GpsPacket.nc */      
      if (call I2CSwitchCmds.PowerSwitch(GPS_POWER_ON)) {
         SODbg(DBG_USR2, "gps_driverM.readGps(): GPS powered on\r\n");
         gps_state = GPS_WORKING;
      }
   }


   event result_t PowerSwitch.getDone(char value) {
      return SUCCESS;
   }

   event result_t PowerSwitch.setDone(bool local_result) {
      SODbg(DBG_USR2,"gps_driverM.PowerSwitch.setDone()\r\n");
      //gps_state = GPS_FINISHED;
      return SUCCESS;
   }

   event result_t PowerSwitch.setAllDone(bool local_result) {
      return SUCCESS;
   }


   event result_t IOSwitch.getDone(char value) {
      return SUCCESS;
   }

   event result_t IOSwitch.setAllDone(bool local_result) {
      return SUCCESS;
   }

   event result_t IOSwitch.setDone(bool local_result) {
      return SUCCESS;
   }

   /** This can be turned into if-else blocks for
    * selecting which format string is currently
    * returned.  We can use constants because NMEA
    * is a documented format and the characters are
    * always in the same place.  The return value
    * can be an enum for use in a switch-case in
    * the calling code.
    */
   command result_t isGGA(uint8_t * data) {

      if ( (data[3] == 'G') && 
           (data[4] == 'G') &&
           (data[5] == 'A')) {
         return TRUE;
      } 
      else if ( (data[3] == 'R') && 
                (data[4] == 'M') &&
                (data[5] == 'C')) {
         return FALSE;
      }
      else {
         return FALSE;
      }   
   }


   command result_t log_gga_data_to_eeprom(GGAMsg * pGGA) {

#if 0
      int j;
      char gga_log_array[GPS_CHAR];

      gga_log_array[0]  = pGGA->hours;
      gga_log_array[1]  = pGGA->minutes;
      gga_log_array[2]  = (pGGA->dec_sec)>>8; // MSB
      gga_log_array[3]  = pGGA->dec_sec;      // LSB
      gga_log_array[4]  = pGGA->Lat_deg;
      gga_log_array[5]  = (pGGA->Lat_dec_min)>>8;
      gga_log_array[6]  = pGGA->Lat_dec_min;
      gga_log_array[7]  = pGGA->Long_deg;
      gga_log_array[8]  = (pGGA->Long_dec_min)>>8;
      gga_log_array[9]  = pGGA->Long_dec_min;
      gga_log_array[10] = pGGA->NSEWind;

  
      //SODbg(DBG_USR2, "LOGGER GPS:\n");
      for(j=0; j<11; j++) {
        UARTPutChar(gga_log_array[j]);
      }
      SODbg(DBG_USR2, "\n");

      // Write into eeprom here.

#endif
      return SUCCESS;
   }


   command void spew_to_uart(GPS_Msg * gps_data) {

      int i;
      SODbg(DBG_USR2, "\r\n");
      for (i=0; i<=gps_data->length; i++) {
        /** UARTPutChar is an SODebug function.
         * FIXME: Change this to use a char[].
         */
         UARTPutChar(gps_data->data[i]);
      }  
      SODbg(DBG_USR2, "\r\n");
   }



  /**
   * Packet received from GPS - ASCII msg
   * 1st byte in pkt is number of ascii bytes
   * async used only for testing.
   * 
   * FIXME: Why is the data returned?  It's passed in.
   * It should be declared const.
   *
   * This function is called from GpsPacket.receiveTask().
   */
   event TOS_MsgPtr GpsReceive.receive(TOS_MsgPtr data) {

      GPS_MsgPtr gps_data = (GPS_MsgPtr)data;

#if DBG_USR2
      signal HLSensor.dataReady(gps_data);
     
#else
      if ((call isGGA(gps_data->data))) {

          call parse_gga(gps_data);

          if (have_gps_fix) {
            //call spew_to_uart(gps_data);
            signal HLSensor.dataReady(&gga_msg);
          }
          }
#endif

      return data;                    
   }


   event result_t GpsSend.sendDone(TOS_MsgPtr msg, result_t success) {

     //SODbg(DBG_USR2, "GpsSend.sendDone(): state: %i \r\n", state);
      return SUCCESS;
   }


   event result_t I2CSwitchCmds.SwitchesSet(uint8_t PowerState) {

     //SODbg(DBG_USR2, "gps_new.GpsCmd.SwitchesSet(): PowerState: %i \n\n", PowerState);
     //call Leds.yellowOn();
     //call Leds.redOff();
      return SUCCESS;
   }


  /** FIXME: Change this to count commas on the raw gga string.
   * Counting commas will save a lot of processing power otherwise
   * used for building char[][]s.
   */
   command uint8_t get_gps_fix(char * data) {

     return (data[0] - '0');
   }


   command result_t load_gga_struct(char gga_fields[GGA_FIELDS][GPS_CHAR_PER_FIELD]) {

      char NS;
      char EW;

      gga_msg.hours =  extract_hours_m(gga_fields[1]);
      gga_msg.minutes = extract_minutes_m(gga_fields[1]);
      gga_msg.dec_sec = extract_dec_sec_m(gga_fields[1]);
      gga_msg.Lat_deg = extract_Lat_deg_m(gga_fields[2]);
      gga_msg.Lat_dec_min = extract_Lat_dec_min_m(gga_fields[2]);
      gga_msg.Long_deg = extract_Long_deg_m(gga_fields[4]);
      gga_msg.Long_dec_min = extract_Long_dec_min_m(gga_fields[4]);     


      NS = (gga_fields[3][0] == 'N') ? 1 : 0;
      EW = (gga_fields[5][0] == 'W') ? 1 : 0;
      gga_msg.NSEWind = EW | (NS<<4); // eg. Status = 000N000E = 00010000

      gga_msg.num_sats = call extract_num_sats(gga_fields[7]);
      
      return SUCCESS;
   }


   /** The internal logic of this command is inherited from
    * whoknowswhere.  It's too complicated for it's doing.
    * FIXME: Simplify the code in this command.
    */
   command result_t parse_gga(GPS_Msg * gps_data) {

      //SODbg(DBG_USR2, "gps_new.GpsCmd.SwitchesSet(): PowerState: %i \n\n", PowerState);

     char gga_fields[GGA_FIELDS][GPS_CHAR_PER_FIELD]; // = {{0}};

      bool end_of_field = FALSE;
      uint8_t i=0;
      uint8_t j,m;
      uint16_t k=0;
      uint8_t length = gps_data->length;

      // Parse and store comma delimited fields into EEPROM
      while (i < GGA_FIELDS) {

         // assemble gga_fields array
         end_of_field = FALSE;
         j = 0;
         while (!end_of_field & k < length) {
            if (gps_data->data[k] == GPS_DELIMITER) {
               end_of_field = TRUE;
            } 
            else {
               gga_fields[i][j] = gps_data->data[k];
            }
            j++;
            k++;
         }

         // two commas (,,) indicate empty field
         // if field is empty, set it equal to 0
         if (j <= 1) {
            for (m=0; m<10; m++) gga_fields[i][m] = '0';
         }

         i++;
      }
   
      // Finding the gps fix should probably done somewhere else.
      have_gps_fix = call get_gps_fix(gga_fields[6]);
      //SODbg(DBG_USR2, "gps_new.parse_gga(): gps_fix %i \r\n", gps_fix);

      if (have_gps_fix) {
         call load_gga_struct(gga_fields);
      }
      return SUCCESS;
   }


   command uint8_t  extract_hours(char * data) {
      return (10*(data[0]-'0') + (data[1]-'0'));
   }

   command uint8_t  extract_minutes(char * data) {
      return (10*(data[2]-'0') + (data[3]-'0'));
   }

   /** FIXME: Where is data[6]?  The decimal point?
    */
   command float extract_dec_sec(char * data) {

      float dec_secs;

      dec_secs = 10*(data[4]-'0') +  (data[5]-'0') + 0.1*(data[7]-'0') 
               + 0.01*(data[8]-'0')
               + 0.001*(data[9]-'0');

      return dec_secs;
   }

   command uint8_t  extract_Lat_deg(char * data) {
      return 10*(data[0]-'0') + (data[1]-'0');
   }

   command float extract_Lat_dec_min(char * data) {

      float dec_min;
      dec_min = 10*(data[2]-'0') +  (data[3]-'0') + 0.1*(data[5]-'0') 
              + 0.01*(data[6]-'0') + 0.001*(data[7]-'0') + 0.0001*(data[8]-'0');

      /*
      dec_min = 100000*(data[2]-'0') + 10000*(data[3]-'0')
              + 1000*(data[4]-'0') + 100*(data[5]-'0')
              + 10*(data[6]-'0') + (data[7]-'0'); 
      */
      return dec_min;
   }

   command uint8_t  extract_Long_deg(char * data) {
      return  (100*(data[0]-'0') + 10*(data[1]-'0')
               + (data[2]-'0'));     
   }

   command float extract_Long_dec_min(char * data) {

      float dec_min;

      dec_min = 10*(data[3]-'0') +  (data[4]-'0') + 0.1*(data[6]-'0') 
              + 0.01*(data[7]-'0') + 0.001*(data[8]-'0') + 0.0001*(data[9]-'0');

      /*
      dec_min = 100000*(data[3]-'0') + 10000*(data[4]-'0')
              + 1000*(data[5]-'0') + 100*(data[6]-'0')
              + 10*(data[7]-'0') + (data[8]-'0'); 
      */
      return dec_min;
   }

   command uint8_t  extract_NSEWind(char * data) {
      return 0;
   }
            
   command uint8_t extract_num_sats(char * data) {
      return (10*(data[0]-'0') + (data[1]-'0')); 
   }


  ///////////////////////////////////////////////////////////
    command result_t HLSensor.init() {

      //SODbg(DBG_USR2, "gps_driverM.HLSensor.init()\n");
      return SUCCESS;
    }

    command result_t HLSensor.powerOn(uint8_t power_level) {

      //SODbg(DBG_USR2, "gps_driverM.Sensor.powerOn()\n");
      call GpsControl.start();
      call readGps();
      return SUCCESS;
    }

    default event result_t HLSensor.powerOnDone() {
      return SUCCESS;
    }

    command result_t HLSensor.powerOff() {

      //call stopGps();
      if (call I2CSwitchCmds.PowerSwitch(GPS_POWER_OFF)) {

        //SODbg(DBG_USR2,"gps_driverM.StdControl.stop(): GPS sensor powered off.\n");
         gps_state = GPS_FINISHED;
      }
      have_gps_fix = 0;
      signal HLSensor.powerOffDone();
      return SUCCESS;
    }

    default event result_t HLSensor.powerOffDone() {
      return SUCCESS;
    }

   /** This will need to call Sensor.loadProgram with an appropriate
    * NMEA string.
    */
    command result_t HLSensor.setSamplingInterval(uint16_t sampling_rate) {
      return SUCCESS;
    }

   /** This will need to call Sensor.loadProgram with an appropriate
    * NMEA string.
    */
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


    /** Not currently working for at least 2 reasons:
     * 1. Not sure if the program string is correct for
     *    the LeadTek;
     * 2. Not sure if any program string is correctly navigating
     * the UART and loading into the LeadTek.
     */
    command result_t HLSensor.loadProgram(uint8_t * program, uint8_t length) {

      TOS_Msg msg = {0};
      //strcpy(msg->data,program);
      //GPS_Msg msg;
      //msg->data = program;

      msg.length = strlen(program);
      //program[0] = msg.length;
      strcpy(msg.data,program);

     
      signal HLSensor.dataReady((void*)program);

      return call GpsSend.send(&msg);
    }
    
  /** In many cases we might want the GPS unit to be silent
   * until a valid fix is obtained, report the fix,
   * then shut up.  Not being able to obtain a valid fix 
   * in some amount of time can be regarded as an error
   * and signaled.
   */
    async default event result_t HLSensor.error(uint16_t error_code) {
      return SUCCESS;
    }
}

