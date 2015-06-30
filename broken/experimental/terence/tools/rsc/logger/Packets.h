enum {
  AM_ROUTEPACKET = 2,
  AM_STATPACKET = 102,
  AM_ROUTEDBMSG = 3,
  AM_SURGEMSG = 17,
  AM_ESTIMATORMSG = 12,
  AM_TABLEPACKET = 6
};

// mig is not smart enough to put struct within struct
// (or maybe i don't know how to use it)
// that's why i have so much reducdancy. it will be nice if

//////////////////////////////////////
// StatPacket with blast
typedef	struct StatPacket {
  // am header
  uint16_t addr;
  uint8_t amtype;
  uint8_t group;
  uint8_t length;

  uint16_t dataGenerated; // 5 - 6
  uint16_t forwardPacket; // 7 - 8
  uint16_t totalRetransmission; // 9 - 10
  uint8_t numTrans;  // 11
  uint8_t parent;  // 12
  uint16_t cost; // 13 - 14
  uint8_t hop; // 15
  uint8_t parentSendQuality; // 16 
  uint16_t commSendActivity; // 17 - 18
  uint8_t numRetrans;  // 19
  uint8_t numChildren; // 20
  uint8_t forwardQueueSize; // 21
  uint16_t noParentCount; // 22 - 23
  uint16_t parentChange;  // 24 - 25
  uint8_t numCycles;  // 26
  uint8_t parentReceiveQuality; // 27 
  uint16_t commReceiveQuality;  // 28 - 29
  // mh header
  uint8_t dataSeqnum; // 30
  uint8_t realSource; // 31

  // vc header
  uint8_t source; // 32
  int8_t seqnum; // 33

  // crc
  uint16_t crc;
} StatPacket;

//////////////////////////////////////

typedef struct RouteDBMsg {
  // am header
  uint16_t addr;
  uint8_t amtype;
  uint8_t group;
  uint8_t length;

  // route db msg
  uint8_t decision;

  uint8_t oldParent;
  uint16_t oldParentLinkCost;
  uint16_t oldParentCost;
  uint8_t oldParentSendEst;
  uint8_t oldParentReceiveEst;

  uint8_t bestParent;
  uint16_t bestParentLinkCost;
  uint16_t bestParentCost;
  uint8_t bestParentSendEst;
  uint8_t bestParentReceiveEst;

  uint8_t parent;
  uint8_t dbSeqnum;

  // vc header
  uint8_t source;
  int8_t seqnum;

  // crc
  uint16_t crc;
} RouteDBMsg;

//////////////////////////////////////

struct Entry {
  uint8_t id;
  uint8_t receiveEst;
};

struct RoutePacket {
  // am header
  uint16_t addr;
  uint8_t amtype;
  uint8_t group;
  uint8_t length;

  // route packet
  uint8_t parent;
  uint8_t hop;
  uint16_t cost;
  uint8_t estLength;
  struct Entry entries[11];

  // vc header
  uint8_t source;
  int8_t seqnum;

  // crc
  uint16_t crc;
};
//////////////////////////////////////

typedef struct SurgeMsg {
  // am header
  uint16_t addr;
  uint8_t amtype;
  uint8_t group;
  uint8_t length;
  // surge packet
  uint8_t type;
  uint16_t sourceaddr;
  uint16_t originaddr;
  uint16_t parentaddr;
  uint8_t seqno;
  uint8_t hopcount;
  uint16_t reading;
  uint8_t parent_link_quality;
  uint8_t nbrs[4];
  uint8_t q[4];
  uint32_t debug_code;
  // crc
  uint16_t crc;
} SurgeMsg;



struct EstimatorMsg {
  // am header
  uint16_t addr;
  uint8_t amtype;
  uint8_t group;
  uint8_t length;

  // estimator payload
  uint8_t oldGoodness;
  uint8_t lastSeqnum;
  uint8_t oldNew;
  uint16_t received;
  uint16_t missed;
  uint8_t goodness;
  uint8_t expTotal;
  uint8_t total;
  uint8_t new;
  uint8_t whichSource;

  // vc header
  uint8_t source;
  int8_t seqnum;

  // crc
  uint16_t crc;
};


/*
struct TablePacket {
  // am header
  uint16_t addr;
  uint8_t amtype;
  uint8_t group;
  uint8_t length;
  // vc header
  uint8_t source;
  int8_t seqnum;

  uint8_t id1;
  uint8_t receiveEst1;
  uint8_t sendEst1;
  uint16_t cost1;

  uint8_t id2;
  uint8_t receiveEst2;
  uint8_t sendEst2;
  uint16_t cost2;

  uint8_t id3;
  uint8_t receiveEst3;
  uint8_t sendEst3;
  uint16_t cost3;

  uint8_t id4;
  uint8_t receiveEst4;
  uint8_t sendEst4;
  uint16_t cost4;

  uint8_t id5;
  uint8_t receiveEst5;
  uint8_t sendEst5;
  uint16_t cost5;

};
*/


struct TablePacket {
  // am header
  uint16_t addr;
  uint8_t amtype;
  uint8_t group;
  uint8_t length;

  // Table Packet
  uint8_t id1;
  uint8_t receiveEst1;
  uint8_t sendEst1;
  uint16_t cost1;

  uint8_t id2;
  uint8_t receiveEst2;
  uint8_t sendEst2;
  uint16_t cost2;

  uint8_t id3;
  uint8_t receiveEst3;
  uint8_t sendEst3;
  uint16_t cost3;

  uint8_t id4;
  uint8_t receiveEst4;
  uint8_t sendEst4;
  uint16_t cost4;

  uint8_t id5;
  uint8_t receiveEst5;
  uint8_t sendEst5;
  uint16_t cost5;

  // vc header
  uint8_t source;
  int8_t seqnum;

  // crc
  uint16_t crc;
};

