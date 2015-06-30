#include <Coord.h>

enum {
  NO_ROUTE = 2,
  MAX_BEACON_INTERVAL = 10000,
  BEACON_INTERVAL = 10000,
  MAX_BEACON_JITTER = 5000,
  BEACON_JITTER = 500,
  ROUTER_NIL = 0xff,
  ROUTER_READY = 0,
  ROUTER_BUSY = 1,
  //MAX_BQLENGTH = 10,
  //MAX_LINK_NUM = 5,
  //MAX_LINK_NUM = 15,
  MAX_NEIGHBNUM = 7,
};

/*
enum {
  BEACON,
  GREEDY,
  CONSOLE_QUERY,
  CONSOLE_QUERY_REPLY,
  CONSOLE_ZONE,
  CONSOLE_ZONE_REPLY,
  CONSOLE_CREATE,
  CONSOLE_CREATE_REPLY,
  CONSOLE_DROP,
  CONSOLE_DROP_REPLY,
  CONSOLE_START = 10,
  CONSOLE_STOP = 12,
};
*/

typedef struct Neighb {
  uint16_t addr_;
  Coord coord_;
} __attribute__ ((packed)) Neighb, *NeighbPtr;

/**
 * 1 + 1 + 2 + 2 + 2  = 8 Bytes. No need of payload length which
 * has been included in TOS message header.
 */
typedef struct {
  uint8_t mode_;
  //uint8_t seqno_; 
  //uint8_t prev_hop_;
  //uint8_t src_addr_; // End-to-end source identification.
  uint16_t src_addr_; // End-to-end source identification.
  Coord coord_;       // Source for beacons and dest for data.
  char data_[0];
} __attribute__ ((packed)) GreedyHeader, *GreedyHeaderPtr;

/*
Coord NeighbHood[MAX_LINK_NUM] = {
  {0, 1},
  {1, 2},
  {1, 3},
  {2, 3},
  {3, 4},
};
Coord NeighbHood[MAX_LINK_NUM] = {
  {0, 2},
  {0, 3},
  {1, 4},
  {2, 3},
  {2, 5},
  {2, 6},
  {3, 4},
  {3, 5},
  {3, 6},
  {4, 7},
  {5, 6},
  {5, 8},
  {6, 7},
  {6, 8},
  {7, 9},
};
*/
