// @author Jaein Jeong

typedef struct TestReadingMsg {
  uint16_t PIR_val;
  uint16_t Cap_val;
  uint16_t Batt_val;
  uint8_t  bPowerSource;
  uint8_t  bCharging;
  uint32_t ts_val;
  uint16_t RefVol;
  uint16_t Vcc;
} TestReadingMsg;

enum {
  AM_TESTREADINGMSG = 68
};


