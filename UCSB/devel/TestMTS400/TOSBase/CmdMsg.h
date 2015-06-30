enum {
  AM_SENSORMSG = 0,
  AM_CMDMSG = 1
};

enum {
  LED_ON = 1,
  LED_OFF = 2,
  RADIO_POWER = 3,
  DATA_RATE = 4
};

typedef struct CmdMsg {
  uint8_t node_id;
  uint8_t action; 
  uint32_t interval;
  uint8_t power;
} CmdMsg; 

typedef struct MTS400DataMsg {
  uint16_t vref;
  uint16_t humidity;
  uint16_t temperature;
  uint16_t taosch0;
  uint16_t taosch1;
  uint16_t strength;
} MTS400DataMsg;