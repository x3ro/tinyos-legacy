// $Id: sensorboardApp.h,v 1.1 2005/02/03 10:15:03 pipeng Exp $

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

typedef struct XTotalData {
  uint16_t seq_no;
  uint16_t  vref;
  uint16_t humid;
  uint16_t humtemp;
  uint16_t inthum;
  uint16_t inttemp;     // 15
  uint16_t photo[4];    // 23
  uint16_t  accel_x;
  uint16_t  accel_y;
  uint16_t prtemp;
  uint16_t press;       // 29
  uint16_t presscalib[4]; // 37
} __attribute__ ((packed)) XTotalData;

typedef struct   XDataMsg {
  XSensorHeader xSensorHeader;
  union {
    XTotalData datax;
  }xData;
} __attribute__ ((packed)) XDataMsg;


enum {
  AM_XSXMSG = 0,
  
};
