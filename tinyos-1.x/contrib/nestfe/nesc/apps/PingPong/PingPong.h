enum {
  AM_PPCMDMSG = 0x31,
  AM_PPREPLYMSG = 0x32,
};

enum {
  PP_IMMEDIATE = 1,
  PP_TASK = 2,
};

typedef struct PpCmdMsg {
  uint16_t cmd;
} PpCmdMsg;

typedef struct PpReplyMsg {
  uint16_t reply;
} PpReplyMsg;

