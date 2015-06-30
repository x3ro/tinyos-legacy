// $Id: sensorboardApp.h,v 1.9 2005/03/04 10:08:49 husq Exp $


#define MAKE_GPS_ENA_OUTPUT() sbi(DDRE,6)
#define SET_GPS_ENA() cbi(PORTE,6)
#define CLR_GPS_ENA() sbi(PORTE,6)

#define GPS_MSG_LENGTH 100
#define GPS_CHAR 11
#define GGA_FIELDS 8
#define GPS_CHAR_PER_FIELD 10
#define GPS_DELIMITER ','
#define GPS_END_MSG '*'

//  18 bytes.
//
//struct _gga_msg 
//{
//  uint8_t  hours;
//  uint8_t  minutes;
//  float    dec_sec;
//  uint8_t  Lat_deg;
//  float    Lat_dec_min;
//  uint8_t  Long_deg;
//  float    Long_dec_min;
//  uint8_t  NSEWind; 
//  uint8_t  num_sats;           
//};

//typedef struct _gga_msg GGA_Msg;
//
//

typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;


typedef struct GGAMsg
{
  uint8_t  hour;
  uint8_t  minute;
  uint8_t  lat_deg;
  uint8_t  long_deg;
  uint32_t dec_sec;
  uint32_t lat_dec_min;
  uint32_t long_dec_min;
  uint8_t  nsewind;
  uint8_t  fixed;
} __attribute__ ((packed)) GGAMsg;

typedef struct XSensorMTS400DataMsg
{
  uint16_t vref;
  uint16_t humidity;
  uint16_t temperature;
  uint16_t cal_wrod1;
  uint16_t cal_wrod2;
  uint16_t cal_wrod3;
  uint16_t cal_wrod4;
  uint16_t intersematemp;
  uint16_t pressure;
  uint16_t taoch0;
  uint16_t taoch1;
  uint16_t accel_x;
  uint16_t accel_y;
} __attribute__ ((packed)) XSensorMTS400DataMsg;

enum {
  AM_XSXMSG = 0,  
};

typedef struct MyGPS_Msg
{
  /* The following fields are received on the gps. */
  int8_t data[60];
} MyGPS_Msg;

typedef struct XDataMsg {
  XSensorHeader xSensorHeader;
  union {
     XSensorMTS400DataMsg    data1;
     MyGPS_Msg    dataGps;
  }xData;
} __attribute__ ((packed)) XDataMsg;

