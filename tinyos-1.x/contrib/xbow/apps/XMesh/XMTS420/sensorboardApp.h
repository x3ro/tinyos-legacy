// $Id: sensorboardApp.h,v 1.1 2004/12/10 05:46:12 husq Exp $

// controls for the voltage reference monitor
#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRA, 5)
#define MAKE_ADC_INPUT() cbi(DDRF, 7)
#define SET_BAT_MONITOR() sbi(PORTA, 5)
#define CLEAR_BAT_MONITOR() cbi(PORTA, 5)

#define MAKE_GPS_ENA_OUTPUT() sbi(DDRE,6)
#define SET_GPS_ENA() cbi(PORTE,6)
#define CLR_GPS_ENA() sbi(PORTE,6)

#define GPS_MSG_LENGTH 100
#define GPS_CHAR 11
#define GGA_FIELDS 8
#define GPS_CHAR_PER_FIELD 10
#define GPS_DELIMITER ','
#define GPS_END_MSG '*'


typedef struct XMeshHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t parent;
}__attribute__ ((packed)) XMeshHeader;

/* * PACKET #3 
 * ----------------
 *  msg->data[0] : sensor id, MTS400 = 0x85,MTS420 = 0x86
 *  msg->data[1] : packet id = 3
 *  msg->data[2] : node id
 *  msg->data[3] : parent
 *  msg->data[4,5] : battery ADC data
 *  msg->data[6,7] : humidity data
 *  msg->data[8,9] : temperature data
 *  msg->data[10,11] : cal_word1 
 *  msg->data[12,13] : cal_word2
 *  msg->data[14,15] : cal_word3
 *  msg->data[16,17] : cal_word4
 *  msg->data[18,19] : intersematemp
 *  msg->data[20,21] : pressure
 */
 typedef struct PData3{
  uint16_t vref;
  uint16_t humidity;
  uint16_t temp;
  uint16_t cal_word1;           //!< Pressure calibration word 1
  uint16_t cal_word2;           //!< Pressure calibration word 2
  uint16_t cal_word3;           //!< Pressure calibration word 3
  uint16_t cal_word4;           //!< Pressure calibration word 4
  uint16_t intersematemp;
  uint16_t intersemapressure;
} __attribute__ ((packed)) PData3;

/* * PACKET #4 
 * ----------------
 *  msg->data[0] : sensor id, MTS400 = 0x85,MTS420 = 0x86
 *  msg->data[1] : packet id = 4
 *  msg->data[2] : node id
 *  msg->data[3] : parent
 *  msg->data[4,5] : taosch0
 *  msg->data[6,7] : taosch1
 *  msg->data[8,9] : accel_x
 *  msg->data[10,11] : accel_y 
 */
typedef struct PData4 {
  uint16_t taosch0;
  uint16_t taosch1;
  uint16_t accel_x;
  uint16_t accel_y;
} __attribute__ ((packed)) PData4 ;


/* * PACKET #2 
 *  msg->data[0] : sensor board id, MTS400 = 0x85,MTS420 = 0x86
 *  msg->data[1] : packet id = 2
 *  msg->data[2] : node id
 *  msg->data[3] : parent
 *  msg->data[4] : Hours
 *  msg->data[5] : Minutes
 *  msg->data[6] : Latitude degrees
 *  msg->data[7] : Longitude degrees
 *  msg->data[8,9,10,11] : Decimal seconds
 *  msg->data[12,13,14,15] : Latitude decimal minutes
 *  msg->data[16,17,18,19] : Longitude decimal minutes
 *  msg->data[20] : NSEWind
 *  msg->data[21] : whether the packet is valid
 */
 typedef struct GGAMsg {
  uint8_t  hours;
  uint8_t  minutes;
  uint8_t  Lat_deg;
  uint8_t  Long_deg;

  uint32_t dec_sec;
  uint32_t Lat_dec_min;
  uint32_t Long_dec_min;

  uint8_t  NSEWind; 
  uint8_t  valid;
  // This can be used after the rest of it is tested.
  /*
  struct {
     uint8_t NS : 1;
     uint8_t EW : 1;
     uint8_t num_sats : 4;
   }
  */

} __attribute__ ((packed)) GGAMsg;


typedef struct XDataMsg {
  XMeshHeader xmeshHeader;
  union {
     PData3    data3;
     PData4    data4;
     GGAMsg    dataGps;
  }xData;
} __attribute__ ((packed)) XDataMsg;


enum {
    BATT_TEMP_PORT = 7,             //adc port for battery voltage
};

enum {
    AM_XCOMMAND_MSG  = 48,
    AM_XDEBUG_MSG    = 49,
    AM_XSENSOR_MSG   = 50,
    AM_XMULTIHOP_MSG = 51         // xsensor multihop 
};

