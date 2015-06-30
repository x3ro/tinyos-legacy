
/*
 *
 * Authors:		Philip Buonadonna, Crossbow, Gilman Tolle
 * Date last modified:  2/20/03
 *
 */

/**
 * @author Philip Buonadonna
 */


#ifndef _TOS_MULTIHOP_H
#define _TOS_MULTIHOP_H

#ifndef MHOP_QUEUE_SIZE
#define MHOP_QUEUE_SIZE	2
#endif

#ifndef MHOP_HISTORY_SIZE
#define MHOP_HISTORY_SIZE 4
#endif

#include "AM.h"
enum {
  AM_BEACONMSG = 250,
  AM_MULTIHOPMSG = 250,
  AM_DEBUGPACKET = 3 
};

/* Fields of neighbor table */
typedef struct TOS_MHopNeighbor {
  uint16_t addr;                     // state provided by nbr
  uint16_t recv_count;               // since last goodness update
  uint16_t fail_count;               // since last goodness, adjusted by TOs
  uint16_t hopcount;
  uint8_t goodness;
  uint8_t timeouts;		     // since last recv
} TOS_MHopNeighbor;
  
typedef struct MultihopMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  int16_t originseqno;
  uint16_t hopcount;
  uint8_t data[(TOSH_DATA_LENGTH - 10)];
} TOS_MHopMsg;

typedef struct BeaconMsg {
  uint16_t parent;
  uint16_t cost;
  uint16_t hopcount;
  uint32_t timestamp;
} BeaconMsg;

typedef struct DBGEstEntry {
  uint16_t id;
  uint8_t hopcount;
  uint8_t sendEst;
} DBGEstEntry;

typedef struct DebugPacket {
//  uint16_t seqno;
  uint16_t estEntries;
  DBGEstEntry estList[0];
} DebugPacket;

#endif /* _TOS_MULTIHOP_H */

