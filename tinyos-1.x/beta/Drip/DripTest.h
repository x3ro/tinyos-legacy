enum {
  AM_DRIPTESTMSG = 254,
};

typedef struct DripTestMsg {
  uint16_t seqno;
  uint32_t time;
} DripTestMsg;
