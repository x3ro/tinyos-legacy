// $Id: sensorboardApp.h,v 1.5 2004/12/14 10:40:05 pipeng Exp $
/* sensorboard.h - hardware specific definitions for the MTS101 
*/

// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x82               //MTS101 sensor board id

typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;

typedef struct PData1 {
  uint16_t vref;
  uint16_t thermistor;
  uint16_t photo;
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
