enum {
  AM_DRIPDRAINPINGMSG = 1,
};

typedef struct DripDrainPingMsg {
  uint16_t identifier;
  uint16_t seqno;
} DripDrainPingMsg;
