
#ifndef __TEST_DIMMER__
#define __TEST_DIMMER__

enum {
  AM_DIMMERMSG = 140,
};

typedef struct DimmerMsg {
  uint8_t level;
} DimmerMsg;

#endif
