#ifndef __POWERMGMT_H__
#define __POWERMGMT_H__

enum {
  AM_POWERMGMTCMDMSG = 1,
};

enum {
  POWERMGMT_ON = 0,
  POWERMGMT_LPL = 1,
  POWERMGMT_SLEEP = 2,
  POWERMGMT_HIBERNATE = 3,
};

typedef struct PowerMgmtCmdMsg {
  uint16_t changeDelay;
  uint8_t powerMode;
} PowerMgmtCmdMsg;

enum {
  LPL_CHANGE_DELAY = 4096,
  LPL_CHANGE_RETRY_DELAY = 1024,
};

#ifndef LPL_SLEEP_DELAY
#define LPL_SLEEP_DELAY 65535U
#endif

enum {
  CC1K_FPL = 0,
  CC1K_LPL = 6,
};

#endif
