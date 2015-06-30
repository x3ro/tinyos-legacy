#include "Location2D.h"
#include "TupleSpace.h"

enum {
  SPANTREEREGION_MAX_NEIGHBORS = 16,
};

typedef struct SpanTreeRegion_BeaconMsg {
  uint16_t sourceaddr;  // The node sending this beacon
  uint16_t originaddr;  // Root of the spanning tree
  uint16_t parentaddr;  // Parent of the node sending this beacon
  uint8_t seqno;
  uint8_t hopcount;
} __attribute__ ((packed)) SpanTreeRegion_BeaconMsg;

typedef struct SpanTreeRegion_RouteMsg {
  uint8_t data[TOSH_DATA_LENGTH-3];
  uint16_t destaddr;
  uint8_t length;
} __attribute__ ((packed)) SpanTreeRegion_RouteMsg;

typedef struct SpanTreeRegion_TSMsg {
  uint16_t srcaddr;
  uint8_t key;
  uint8_t data_len;
  uint8_t data[TUPLESPACE_BUFLEN];
} __attribute__ ((packed)) SpanTreeRegion_TSMsg;

enum {
  AM_SPANTREEREGION_BEACONMSG = 80,
  AM_SPANTREEREGION_ROUTEMSG = 81,
  AM_SPANTREEREGION_TSMSG = 82,
  AM_SPANTREEREGION_PARENTMSG = 83,
  AM_SPANTREEREGION_ROOTMSG = 84,
};
