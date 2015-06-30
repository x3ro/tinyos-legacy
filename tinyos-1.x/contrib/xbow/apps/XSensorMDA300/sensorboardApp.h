/* sensorboard.h - hardware specific definitions for the MDA300 
*/

// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x81       //MDA300 sensor board id

#define NUM_MSG1_BYTES (28)			// bytes 2-29 
#define NUM_MSG2_BYTES (8)			// bytes 2-9 
#define NUM_MSG3_BYTES (13)			// bytes 2-13 

// format is:
//  byte 1 & 2: ADC reading in big-endian format

typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;


typedef struct PData1 {
  uint16_t  analogCh0;
  uint16_t  analogCh1;
  uint16_t  analogCh2;
  uint16_t  analogCh3;
  uint16_t  analogCh4;
  uint16_t  analogCh5;
  uint16_t  analogCh6;
} __attribute__ ((packed)) PData1;

typedef struct PData2 {
  uint16_t  analogCh7;
  uint16_t  analogCh8;
  uint16_t  analogCh9;
  uint16_t  analogCh10;
  uint16_t  analogCh11;
  uint16_t  analogCh12;
  uint16_t  analogCh13;
} __attribute__ ((packed)) PData2;

typedef struct PData3 {
  uint16_t  digitalCh0;
  uint16_t  digitalCh1;
  uint16_t  digitalCh2;
  uint16_t  digitalCh3;
  uint16_t  digitalCh4;
  uint16_t  digitalCh5;
} __attribute__ ((packed)) PData3;

typedef struct PData4 {
  uint16_t  batt;
  uint16_t  hum;
  uint16_t  temp;
  uint16_t  counter;
} __attribute__ ((packed)) PData4;

typedef struct XDataMsg {
  XSensorHeader xSensorHeader;
  union {
  PData1    datap1;
  PData2    datap2;
  PData3    datap3;
  PData4    datap4;
  }xData;
}  __attribute__ ((packed)) XDataMsg;


enum {
  AM_XSXMSG = 0,  
};

enum {
    Sample_Packet = 6,
};

enum {
    RADIO_TEST,
    UART_TEST
};
