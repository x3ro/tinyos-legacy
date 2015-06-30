#ifndef _SR_DFDTYPES__
#define _SR_DFDTYPES__

#include <VitalStats.h>
#include <TimeStamp.h>

// Important constants
enum {
  // Max number of neighbors that a node can watch
  MAX_WATCHED = 5,

  // .. of them, how many nodes are "under evaluation"
  // and may possible replace one of the permanent slots
  MAX_CANDIDATES = 1,

  // .. maximum number of nodes we expect to cover any
  // given node
  MAX_COVERAGE = 5
};

// Failure opinions
enum {
  FOP_UNCERTAIN = 0,
  FOP_ALIVE = 1,
  FOP_TENTATIVELY_FAILED = 2,
  FOP_FAILED = 3
};

typedef uint8_t FOpinion;

typedef struct {
  // Node that we're tracking
  uint16_t srcAddr;

 // Coverage of this node (i.e. the number of 
  // monitors it thinks it has)
  uint8_t coverage;
    
  // Has this slot not been occupied
  uint8_t free:1;
  // Is this slot is used to evaluate
  // the fitness of the node for being a monitoring target
  uint8_t candidate:1;

  // Failure status of the node
  uint8_t status:2;

  // The core state that this node shared
  // with the previous heartbeat
  VitalStats stats;
} MonitorRec;

typedef struct {
  uint8_t len;
  uint8_t addrHash[0];
} NodeList;

uint8_t addrHash(uint16_t addr) {
  return (addr >> 8) ^ (addr & 0xFF);
}

void clearNList(NodeList *nl) {
  nl->len = 0;
}

// Unique
void addNList(NodeList *nl, uint16_t addr, uint8_t maxLen) {
  uint8_t i, myHash = addrHash(addr);

  for (i = 0; i < nl->len; i++) {
    if (nl->addrHash[i] == myHash)
      return;
  }

  if (nl->len < maxLen) {
    nl->addrHash[nl->len++] = myHash;
  }
}

void delNList(NodeList *nl, uint16_t addr) {
  uint8_t i, myHash = addrHash(addr);

  for (i = 0; i < nl->len; i++) {
    if (nl->addrHash[i] == myHash) {
      memmove(&nl->addrHash[i], 
	      &nl->addrHash[i+1],
	      (nl->len - 1) * sizeof(nl->addrHash[0]));
      nl->len--;

      break;
    }
  }
}

void copyNList(NodeList *tgt, NodeList *src, uint8_t maxLen) {

  tgt->len = src->len;

  memcpy(&tgt->addrHash[0],
	 &src->addrHash[0],
	 (src->len > maxLen ? maxLen : src->len) * sizeof(src->addrHash[0]));
}

typedef struct {
  uint8_t idx;
} MonitorIterator;

// Node timeout types
enum {
  NT_FAIL_DETECTOR = 0,
  NT_MONITORED, 
  // Timeout for the nodes I monitor
  // I stop monitoring these nodes when the node repeatedly
  // excludes me from the list of its monitors
  NT_MONITORING 
  // Timeout for the nodes monitoring me
  // I stop counting the node as my monitor
  // when the node monitoring me stops monitoring me for that long
};

#endif
