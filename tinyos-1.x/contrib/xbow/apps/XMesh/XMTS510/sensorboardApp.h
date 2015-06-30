// $Id: sensorboardApp.h,v 1.2 2004/12/14 10:58:52 pipeng Exp $


#define  SENSOR_BOARD_ID    0x2  

typedef struct XMeshHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t parent;
}__attribute__ ((packed)) XMeshHeader;

typedef struct PData1 {
  uint16_t light;
  uint16_t accelX;
  uint16_t accelY;
  uint16_t sound[5];
} __attribute__ ((packed)) PData1;

typedef struct XDataMsg {
  XMeshHeader xMeshHeader;
  union {
  PData1    datap1;
  }xData;

} __attribute__ ((packed)) XDataMsg;

enum {
  AM_XSXMSG = 0,
  
};


enum {
    AM_XCOMMAND_MSG  = 48,
    AM_XDEBUG_MSG    = 49,
    AM_XSENSOR_MSG   = 50,
    AM_XMULTIHOP_MSG = 51         // xsensor multihop 
};

