#include "AM.h"

enum {
  AM_STRAWBCASTMSG = 246,
};

typedef struct StrawBcastMsg {
  int16_t seqno;
  uint8_t data[(TOSH_DATA_LENGTH-2)];
} __attribute__ ((packed)) StrawBcastMsg;

