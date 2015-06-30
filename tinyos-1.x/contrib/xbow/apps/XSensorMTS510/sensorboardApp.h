// $Id: sensorboardApp.h,v 1.2 2004/12/14 11:04:23 pipeng Exp $




// crossbow sensor board id
#define  SENSOR_BOARD_ID 2               //MTS500 sensor board id

typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;

typedef struct PData1 {
  uint16_t light;
  uint16_t accelX;
  uint16_t accelY;
  uint16_t sound[5];
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


