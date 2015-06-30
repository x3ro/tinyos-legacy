// $Id: sensorboardApp.h,v 1.2 2004/12/14 10:24:09 pipeng Exp $

// controls for the voltage reference monitor
#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRC, 7)
#define MAKE_ADC_INPUT() cbi(DDRF, 1)
#define SET_BAT_MONITOR() cbi(PORTC, 7)
#define CLEAR_BAT_MONITOR() sbi(PORTC, 7)

//controls for the thermistor sensor
#define MAKE_THERM_OUTPUT() sbi(DDRC,6)
#define SET_THERM_POWER() cbi(PORTC,6)
#define CLEAR_THERM_POWER() sbi(PORTC,6)

// controls for mda500 I/O pins, set these as outputs
#define MAKE_INT0_OUTPUT() sbi(DDRD,0)
#define SET_INT0() cbi(PORTD,0)
#define CLR_INT0() sbi(PORTD,0)

#define MAKE_INT1_OUTPUT() sbi(DDRD,1)
#define SET_INT1() cbi(PORTD,1)
#define CLR_INT1() sbi(PORTD,1)

#define MAKE_PWO_OUTPUT() sbi(DDRC,0)
#define SET_PW0() cbi(PORTC,0)
#define CLR_PW0() sbi(PORTC,0)

#define MAKE_PW1_OUTPUT() sbi(DDRC,1)
#define SET_PW1() cbi(PORTC,1)
#define CLR_PW1() sbi(PORTC,1)

#define MAKE_PWM1B_OUTPUT() sbi(DDRB,6)
#define SET_PWM1B() cbi(PORTB,6)
#define CLR_PWM1B() sbi(PORTB,6)

#define MAKE_GPS_ENA_OUTPUT() sbi(DDRE,6)
#define SET_GPS_ENA() cbi(PORTE,6)
#define CLR_GPS_ENA() sbi(PORTE,6)




// crossbow sensor board id
#define  SENSOR_BOARD_ID 1

typedef struct XMeshHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t parent;
}__attribute__ ((packed)) XMeshHeader;

typedef struct PData1 {
  uint16_t vref;
  uint16_t thermistor;
  uint16_t adc2;
  uint16_t adc3;
  uint16_t adc4;
  uint16_t adc5;
  uint16_t adc6;
  uint16_t adc7;
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
    BATT_TEMP_PORT = 1,             //adc port for battery voltage
    ADC2_PORT = 2,
    ADC3_PORT = 3,
    ADC4_PORT = 4,
    ADC5_PORT = 5,
    ADC6_PORT = 6,
    ADC7_PORT = 7  
};

enum {
    AM_XCOMMAND_MSG  = 48,
    AM_XDEBUG_MSG    = 49,
    AM_XSENSOR_MSG   = 50,
    AM_XMULTIHOP_MSG = 51         // xsensor multihop 
};

