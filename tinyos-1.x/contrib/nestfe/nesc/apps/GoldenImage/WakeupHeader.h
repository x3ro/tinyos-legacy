enum {
  AM_WAKEUPMSG = 1,
};

enum {
  WAKEUP_USERBUTTON_LEASE = 61440U, // 10 minutes
//  WAKEUP_USERBUTTON_LEASE = 1000U, // 10 seconds
};

enum {
  WAKEUP_SOURCE_BOTH = 0,
  WAKEUP_SOURCE_BAT = 1,
  WAKEUP_SOURCE_CAP = 2,
};

typedef struct WakeupMsg {
  uint16_t wakeupPeriod; //100ths of a second
  uint16_t  source; 
} WakeupMsg;
