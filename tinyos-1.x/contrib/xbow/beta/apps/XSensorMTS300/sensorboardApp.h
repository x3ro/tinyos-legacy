// $Id: sensorboardApp.h,v 1.4 2004/08/20 15:02:08 mturon Exp $
/* sensorboard.h - hardware specific definitions for the MTS300/310 
*/
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
  uint16_t vref;
  uint16_t thermistor;
  uint16_t light;
  uint16_t mic;
  uint16_t accelX;
  uint16_t accelY;
  uint16_t magX;
  uint16_t magY;
} __attribute__ ((packed)) XDataMsg;

enum {
    BATT_PORT = 7,             //adc port for battery voltage
};

enum {
    XMULTIHOPMSG_ID = 51         // xsensor multihop 
};




