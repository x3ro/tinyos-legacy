// $Id: sensorboardApp.h,v 1.7 2005/01/27 06:48:58 husq Exp $
/* sensorboard.h - hardware specific definitions for the MTS300/310 
*/




#define FEATURE_SOUNDER     1

// Define SOUND_STATE_CHANGE one of two ways:
//      One time sound at test init   ==>  FALSE
//      Continuous beeping throughout ==>  !sound_state
#define SOUND_STATE_CHANGE  FALSE
//#define SOUND_STATE_CHANGE  !sound_state
#define MTS310
// crossbow sensor board id
#ifndef MTS310
#define  SENSOR_BOARD_ID 0x83               //MTS300 sensor board id
#else
#define  SENSOR_BOARD_ID 0x84               //MTS300 sensor board id
#endif

typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;

typedef struct PData1 {
  uint16_t vref;
  uint16_t thermistor;
  uint16_t light;
  uint16_t mic;
  uint16_t accelX;
  uint16_t accelY;
  uint16_t magX;
  uint16_t magY;
} __attribute__ ((packed)) PData1;

typedef struct XDataMsg {
  XSensorHeader xSensorHeader;
  union {
  PData1    datap1;
  }xData;
} __attribute__ ((packed)) XDataMsg;

enum {
  AM_XSXMSG = 0,
  
};
