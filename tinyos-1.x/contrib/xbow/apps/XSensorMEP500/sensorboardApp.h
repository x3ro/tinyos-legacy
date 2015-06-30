// $Id: sensorboardApp.h,v 1.2 2004/12/14 08:30:18 pipeng Exp $


// controls for the voltage reference monitor
#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRC, 7)
#define MAKE_ADC_INPUT() cbi(DDRF, 1)
#define SET_BAT_MONITOR() cbi(PORTC, 7)
#define CLEAR_BAT_MONITOR() sbi(PORTC, 7)

//controls for the thermistor sensor
#define MAKE_THERM_OUTPUT() sbi(DDRC,6)
#define SET_THERM_POWER() cbi(PORTC,6)
#define CLEAR_THERM_POWER() sbi(PORTC,6)


// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x03               //MTS500 sensor board id


typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;

typedef struct PData1 {
  uint8_t  vref;
  uint16_t thermistor;
  uint16_t humidity;
  uint16_t humtemp; // 13
} __attribute__ ((packed)) PData1;


typedef struct XDataMsg {
  XSensorHeader xSensorHeader;
  PData1 xData;

} __attribute__ ((packed)) XDataMsg;

enum {
  AM_XSXMSG = 0,
  
};

enum {
    BATT_PORT = 1,             //adc port for battery voltage
};


