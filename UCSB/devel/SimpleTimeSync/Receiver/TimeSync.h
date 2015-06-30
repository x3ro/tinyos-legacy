enum {
  TIME_SYNC = 1,
  SYNC_ACK = 2
};

typedef struct TimeSyncMsg {
  uint8_t value;
  uint32_t timeLow;
  uint32_t timeHigh;
} TimeSyncMsg;
