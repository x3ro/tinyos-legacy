// $Id: sensorboardApp.h,v 1.12 2004/08/11 01:22:34 mturon Exp $

// controls for the voltage reference monitor
#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRA, 5)
#define MAKE_ADC_INPUT() cbi(DDRF, 7)
#define SET_BAT_MONITOR() sbi(PORTA, 5)
#define CLEAR_BAT_MONITOR() cbi(PORTA, 5)

typedef struct XDataMsg {
  uint8_t  board_id;
  uint8_t  packet_id;
  uint8_t  node_id;
  uint8_t  parent;       // 4
  uint16_t seq_no;
  uint8_t  vref;
  uint16_t humid;
  uint16_t humtemp;
  uint16_t inthum;
  uint16_t inttemp;     // 15
  uint16_t photo[4];    // 23
  uint8_t  accel_x;
  uint8_t  accel_y;
  uint16_t presstemp;
  uint16_t press;       // 29
  uint16_t presscalib[4]; // 37
} __attribute__ ((packed)) XDataMsg;

enum {
    BATT_PORT = 7,             //adc port for battery voltage
};

enum {
    XSENSORMSG_ID = 50,
    XMULTIHOPMSG_ID = 51         // xsensor multihop 
};
