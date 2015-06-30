#ifndef _SR_PKTTYPES__
#define _SR_PKTTYPES__

#include "CompressedSet.h"

typedef struct RosterMsg {
  // Round of this communication
  uint16_t round;
  
  // Set of nodes that we consider alive
  Set alive;
} RosterMsg;

#endif
