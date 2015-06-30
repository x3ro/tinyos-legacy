#ifndef _SR_RESULTP__
#define _SR_RESULTP__

// Result of the protocol

typedef struct ResultPkt {

  // This one really only counts
  // at the root
  //0
  uint16_t numFailedNodes;

  // Amount number of bytes sent
  //2
  uint32_t bytesSent;

  // Number of rounds played so far
  // 6
  uint16_t numRounds;

  // Parent at the current iteration
  // 8
  uint16_t parentAddr;

  // Depth within the tree
  // 10
  uint8_t treeLevel;

  // Number of late arrivals (i.e. desynchronized)
  // 12
  uint8_t numLate;

  // Number of full updates sent
  // 13
  uint16_t numFullUpd;

} ResultPkt;

#endif
