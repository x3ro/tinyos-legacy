enum {
  AM_TESTDRAINMSG = 254,
  TESTDRAIN_SEND_PERIOD = 1000,
};

typedef struct TestDrainMsg {
  uint16_t data;
} TestDrainMsg;
