enum {
  STAT_NUM_NEIGHBOR = 5
};

typedef	struct StatPacket {
  uint16_t dataGenerated;
  uint16_t forwardPacket;
  uint16_t totalRetransmission;
  uint8_t numTrans;
  uint8_t parent;
  cost_t cost;
  uint8_t hop;
  uint8_t id[STAT_NUM_NEIGHBOR];
  uint8_t quality[STAT_NUM_NEIGHBOR];
  uint16_t senseReading;
} StatPacket;
