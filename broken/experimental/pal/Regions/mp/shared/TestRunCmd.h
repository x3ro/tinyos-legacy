
enum {
  TESTRUN_CMD_START = 0,
  TESTRUN_CMD_DONE = 1,
};

typedef struct TestRun_CmdMsg {
  uint8_t type;
  uint16_t sourceaddr;
  uint32_t code;
} __attribute__ ((packed)) TestRun_CmdMsg;

enum {
  AM_TESTRUN_CMDMSG = 76,
};


