struct PingReplyMsg {
  uint16_t parent;
  uint16_t freeram;
  uint16_t voltage;
  uint8_t qlen;
  uint8_t mhqlen;
  uint8_t depth;
  uint8_t qual;
  uint8_t qids[2];
};
