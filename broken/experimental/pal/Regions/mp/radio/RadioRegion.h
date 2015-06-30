#include "TupleSpace.h"

enum {
  RADIOREGION_MAX_NEIGHBORS = 16,
};

typedef struct RadioRegion_BeaconMsg {
  uint16_t sourceaddr;
} __attribute__ ((packed)) RadioRegion_BeaconMsg;

typedef struct RadioRegioN_TSMsg {
  uint8_t cmd;
  uint16_t sourceaddr;
  uint8_t key;
  uint8_t data[TUPLESPACE_BUFLEN];
  uint8_t data_len;
  uint8_t success; // For replies
} __attribute__ ((packed)) RadioRegion_TSMsg;

enum {
  AM_RADIOREGION_BEACONMSG = 77,
  AM_RADIOREGION_TSMSG = 78,
};


