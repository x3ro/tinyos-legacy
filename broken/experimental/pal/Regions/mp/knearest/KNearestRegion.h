#include "Location2D.h"
#include "TupleSpace.h"

enum {
  KNEARESTREGION_MAX_NEIGHBORS = 32,
};

typedef struct KNearestRegion_BeaconMsg {
  uint16_t sourceaddr;
  location_2d_t loc;
} __attribute__ ((packed)) KNearestRegion_BeaconMsg;

enum {
  AM_KNEARESTREGION_BEACONMSG = 79,
};


