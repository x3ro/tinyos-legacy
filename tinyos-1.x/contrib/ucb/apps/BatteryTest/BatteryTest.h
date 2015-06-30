enum {
  AM_BATTERYTESTMSG = 123,
};

typedef struct {
  uint16_t voltage;
} BatteryTestMsg;

/* 
   These values were measured on an early Telos Rev A. 
   Your mileage may vary.
*/

enum {
  BATTERYTEST_3V = 3283,
  BATTERYTEST_2_7V = 3027,
  BATTERYTEST_2_2V = 2451,
};
