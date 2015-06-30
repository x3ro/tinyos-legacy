#ifndef __MGMTQUERY_H__
#define __MGMTQUERY_H__

#include "AM.h"
#include "../MgmtAttrs/MgmtAttrs.h"

enum {
  MAX_QUERIES = 4,
  MAX_QUERY_ATTRS = 8,
  AM_MGMTQUERYRESPONSEMSG = 11,
};

enum {
  AM_MGMTQUERYMSG1 = 11,
  AM_MGMTQUERYMSG2 = 12,
  AM_MGMTQUERYMSG3 = 13,
  AM_MGMTQUERYMSG4 = 14,
};

enum {
  QUERY_INACTIVE = 0,
  QUERY_ACTIVE = 1,
  QUERY_ONE_SHOT = 2,
};

typedef struct MgmtQueryMsg {
  uint16_t     epochLength; // In seconds
  uint8_t      msgType:2;   // Activate or Deactivate
  uint8_t      ramQuery:1;  // 1 if the keys are memory addresses
  uint8_t      numAttrs:5;  // Number of attributes in this query
  uint8_t      pad;         // Padding for 16-bit platforms
  MgmtAttrID   attrList[0];
} MgmtQueryMsg;

typedef struct MgmtQueryDesc {
  uint16_t     epochLength;
  uint16_t     epochCounter;
  uint16_t     seqno;
  MgmtAttrID   attrs[MAX_QUERY_ATTRS];
  uint8_t      queryType:2;
  uint8_t      queryActive:1;
  uint8_t      ramQuery:1;
  uint8_t      pad:4;
  uint8_t      numAttrs;
  uint8_t      attrLocks;
} MgmtQueryDesc;

// Pack the results into data, in the order given in the query
// Assume that the querier knows the width of each field in the query
typedef struct MgmtQueryResponseMsg {
  uint16_t seqno;
  uint8_t  qid;
  uint8_t  data[0];
} MgmtQueryResponseMsg;

#endif //__MGMTQUERY_H__
