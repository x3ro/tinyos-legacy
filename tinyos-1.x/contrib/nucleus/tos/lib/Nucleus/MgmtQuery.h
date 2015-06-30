//$Id: MgmtQuery.h,v 1.8 2005/08/18 04:01:51 gtolle Exp $

#ifndef __MGMTQUERY_H__
#define __MGMTQUERY_H__

#include "Attrs.h"

enum {
  MGMTQUERY_MIN_DELAY = 100,
  MGMTQUERY_MAX_QUERIES = 1,
  MGMTQUERY_MAX_QUERY_ATTRS = 8,
  MGMTQUERY_RESPONSE_HEADER_SIZE = 5, // XXX: sizeof is wrong?
  MGMTQUERY_ATTR_SIZE = 3, // XXX: sizeof is wrong?
};

enum {
  AM_MGMTQUERYMSG         = 11,
  AM_MGMTQUERYRESPONSEMSG = 12,
};

enum {
  MGMTQUERY_DEST_COLLECTION = 1 << 0,
  MGMTQUERY_DEST_SERIAL = 1 << 1,
  MGMTQUERY_DEST_STORAGE = 1 << 2,
  MGMTQUERY_DEST_LOCAL = 1 << 3,
};  

typedef struct MgmtQueryAttr {
  AttrID  id;
  uint8_t pos;
} MgmtQueryAttr;

typedef struct MgmtQueryMsg {
  uint16_t     queryID;         // Unique integer for a particular query
  uint16_t     delay;           // Tenths of a second (ignored for once query)
  uint16_t     destination;     // AM Address of destination node
  uint8_t      ramAttrs;        // Bitfield - whether the attrs are RAM
  uint8_t      active:1;        // Activate or Deactivate
  uint8_t      repeat:1;        // Repeat or One-Shot
  uint8_t      numAttrs:6;      // How many attributes are in the query
  MgmtQueryAttr attrList[0];
} MgmtQueryMsg;

typedef struct MgmtQueryDesc {
  MgmtQueryMsg queryMessage;
  uint32_t     countdown;
  uint16_t     seqno;
  uint16_t     attrLocks;
  MgmtQueryAttr attrList[MGMTQUERY_MAX_QUERY_ATTRS];
  bool         queryPending;
} MgmtQueryDesc;

// Pack the results into data, in the order given in the query
// Assume that the querier knows the width of each field in the query
typedef struct MgmtQueryResponseMsg {
  uint16_t queryID;
  uint16_t seqno;
  uint8_t  attrsPresent;
  uint8_t  data[0];
} MgmtQueryResponseMsg;

#endif //__MGMTQUERY_H__
