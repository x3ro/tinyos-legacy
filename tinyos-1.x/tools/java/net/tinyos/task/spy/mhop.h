typedef struct MultihopMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  uint8_t data[]; 
} __attribute__ ((packed)) TOS_MHopMsg;

  typedef struct RPEstEntry {
    uint16_t id;
    uint8_t receiveEst;
  } __attribute__ ((packed)) RPEstEntry;

  typedef struct RoutePacket {
    uint16_t parent;
    uint16_t cost;
    uint8_t estEntries;
    RPEstEntry estList[];
  } __attribute__ ((packed)) RoutePacket;

enum {
  AM_ROUTEPACKET = 250
};

