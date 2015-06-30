typedef struct bcastMsg {
  uint8_t type;
  uint16_t sourceaddr;
  uint16_t originaddr;
  uint16_t parentaddr;
  uint8_t seqno;
  uint8_t hopcount;
  union {
    // FOR SURGE_TYPE_SETRATE
    uint32_t newrate;
    // FOR SURGE_TYPE_FOCUS 
    uint16_t focusaddr;
  } args;
  uint32_t debug_code;
} __attribute__ ((packed)) bcastMsg;

enum {
  AM_BCASTMSG = 18
};
