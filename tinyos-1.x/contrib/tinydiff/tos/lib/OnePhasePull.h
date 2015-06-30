
/* Diffusion parameters and naming maping */

#ifndef _DEFS_H_
#define _DEFS_H_

#include <inttypes.h>
#include "OPPLib/OPPMacros.h"

//  Size Definitions For Fine Tunings - uses enum for .nc files

enum { 
  MAX_INTERESTS		    = 10,   
  // mmysore TODO: change
  MAX_GRADIENTS		    = 2,
  MAX_GRAD_OVERRIDES	    = 4,
  MAX_ATT		    = 4, // for data length > 31 TODO: change name
  // mmysore TODO: change
  MAX_DATA		    = 25, // data cache size.. TODO: change name..

  TTL			    = 10,
  TIMER_PERIOD_MSEC	    = 125,       // 8 tics per second
  TIMER_TICKS_PER_SEC	    = 1000 / TIMER_PERIOD_MSEC,               
  INTEREST_SENDER_PERIOD    = 5, // every 5 seconds.. has to be less than 
				 // INTEREST_XMIT_MARGIN...
  // DFLT_INTEREST_EXP_TIME has to be greater than INTERST_XMIT_MARGIN
  INTEREST_XMIT_MARGIN	    = 15, // seconds
  DFLT_INTEREST_EXP_TIME    = 60 + INTEREST_XMIT_MARGIN, // seconds

  OPP_LOCAL_GROUP	    = 0x7d,

  NULL_NODE_ID = 0
};

// wanted to make it an enum, but TRUE and FALSE are already enum'd in tos.h
typedef uint8_t BOOL;

enum {
  MAX_NUM_FILTERS	    = 5,
  F_PRIORITY_SEND_TO_NEXT   = 0xff,
  F_PRIORITY_MIN	    = 0x0,
  F_PRIORITY_MAX	    = MAX_NUM_FILTERS - 1
};

typedef enum {
  NOT_FOUND = 0,
  FOUND	    = 1
} SEARCH_STATUS;


typedef enum {
  LOOPBACK	= 0,
  NON_LOOPBACK	= 1
} LOOPBACK_FLAG;

typedef enum {
  UPDATE_ERROR	    = -1,
  UPDATE_DUPLICATE  = 0,
  // the above are types in which no action was taken (possibly due to error)...
  UPDATE_ADDED	    = 1,
  UPDATE_UPDATED    = 2 // not used for now, but could be useful in future...
} UPDATE_STATUS;

// Types Definitions ( also return types) - uses enum for .nc files

enum {
  IS      = 1,
  EQ	  = 2,
  NE	  = 3,
  GT	  = 4,
  GE	  = 5,
  LT	  = 6,
  LE	  = 7,
  EQ_ANY  = 8
};

// TODO: make all keys conform to "ESS_<something>_KEY" name...
enum {
  CLASS	    = 1,
  TEMP	    = 2,
  PRESSURE  = 3,
  ESS_LOAD_KEY = 10,
  ESS_CLUSTERHEAD_KEY = 11,
  INTERVAL  = 50,	    // or whatever...
  LAST	    = 255        // last attribute indicator
};

enum {
  DATA	    = 1,
  INTEREST  = 2
};

#endif // _DEFS_H_








