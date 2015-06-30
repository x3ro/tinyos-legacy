// $Id: sensorboardApp.h,v 1.6 2004/12/14 10:12:04 pipeng Exp $

// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x87              //MEP401 sensor board id

typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;

typedef struct XData {
  uint16_t vref;
  uint16_t accelX;
  uint16_t accelY;
  uint16_t photo1;
  uint16_t photo2;
  uint16_t photo3;
  uint16_t photo4;
  uint16_t humidity;
  uint16_t therm;
  uint16_t inthumidity;
  uint16_t inttherm;
} __attribute__ ((packed)) XData;

typedef struct WData {
  uint16_t word1;
  uint16_t word2;
  uint16_t word3;
  uint16_t word4;
  uint16_t intersematemp;
  uint16_t pressure;
} __attribute__ ((packed)) WData;

typedef struct   XDataMsg {
  XSensorHeader xSensorHeader;
  union {
    XData   datax;
    WData   dataw;
  }xData;
} __attribute__ ((packed)) XDataMsg;


enum {
  AM_XSXMSG = 0,
  
};
