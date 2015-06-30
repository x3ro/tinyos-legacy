// $Id: sensorboardApp.h,v 1.7 2004/08/11 01:22:35 mturon Exp $

// controls for the voltage reference monitor
#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRC, 7)
#define MAKE_ADC_INPUT() cbi(DDRF, 1)
#define SET_BAT_MONITOR() cbi(PORTC, 7)
#define CLEAR_BAT_MONITOR() sbi(PORTC, 7)

//controls for the thermistor sensor
#define MAKE_THERM_OUTPUT() sbi(DDRC,6)
#define SET_THERM_POWER() cbi(PORTC,6)
#define CLEAR_THERM_POWER() sbi(PORTC,6)

typedef struct XDataMsg {
  uint8_t  board_id;
  uint8_t  packet_id;
  uint8_t  node_id;
  uint8_t  parent;
  uint16_t seq_no;
  uint8_t  vref;
  uint16_t thermistor;
  uint16_t humid;
  uint16_t humtemp; // 13
} __attribute__ ((packed)) XDataMsg;

enum {
    BATT_PORT = 1,             //adc port for battery voltage
};

enum {
    XSENSORMSG_ID = 50,
    XMULTIHOPMSG_ID = 51         // xsensor multihop 
};
