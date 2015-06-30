#ifndef _SR_TIME_SYNC__
#define _SR_TIME_SYNC__

enum {
  TIME_SYNC_AM = 55
};

#define NOT_TIME_SYNCHED 0xFFFFFFFF

enum {
  // Interval between time synchronization messages
  kTIME_SYNC_MSG_INTERVAL = 2048,
  // Interval the node spends awake
  kTIME_SYNC_WAKING_TIME = 1024
};

enum {
  // The likelihood of the node
  // sleeping when not synchronized * 65536
  kSLEEP_WHEN_NOTSYNC = 0x8888,
  // The likelihood of the node
  // sleeping after epoch is over, when synchronized * 65536
  kSLEEP_WHEN_SYNC = 0x000F
};

#endif
