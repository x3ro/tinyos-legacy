#ifndef _DATASTRUCTURES_INC_
#define _DATASTRUCTURES_INC_

#include "OnePhasePull.h"

// ============== Interest Message ==================

typedef struct {
  uint16_t seqNum;         // sequence number (32- bits for now...) 
  uint16_t sink;           // source of packet
  uint16_t prevHop;        // last hop
  int8_t  ttl;		   // time to live in terms of hops 
  uint16_t expiration;	   // expiration time of interest(or reinforcement)
  uint8_t  numAttrs;       // number of attributes contained in the packet
  Attribute  attributes[MAX_ATT];  // attributes tuples
} __attribute__((packed)) InterestMessage;

// ============= Data Message =======================

typedef struct {
  uint16_t seqNum;         // sequence number (32- bits for now...) 
  uint16_t source;         // source of packet
  uint16_t prevHop;        // last hop
  int8_t hopsToSrc;       // number of hops packet has travelled from source
  uint8_t  numAttrs;       // number of attributes contained in the packet
  Attribute  attributes[MAX_ATT];  // attributes tuples 

} __attribute__((packed)) DataMessage;



#endif
