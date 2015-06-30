enum {
  AM_DRAINTESTMSG = 254,
};

typedef struct DrainTestMsg {
  uint16_t seqno;
  uint32_t time;
} DrainTestMsg;
