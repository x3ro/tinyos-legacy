enum {
  AM_STATEMSG = 1,
  AM_CODEMSG = 2,
};

struct StateMsg {
  uint8_t data[16];
} StateMsg;

struct CodeMsg {
  uint8_t data[20];
} CodeMsg;
