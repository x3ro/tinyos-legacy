#ifndef _DATACACHE_INC_
#define _DATACACHE_INC_

#include "OnePhasePull.h"

// Data Cache Entry

typedef struct DataEntryStruct {
  uint32_t seqNum;	  // sequence number
  uint8_t  source;        // source of packet
 
} DataEntry;

// Data Cache

typedef struct DataCacheStruct {
  DataEntry entries[MAX_DATA];  // Limited Array of Data Entries
  uint8_t  head;                // Position to Enter next data
} DataCache;


// ===========  Functions Prototypes ======================


void initDataCache(DataCache *cache);
// Post: Initialize or reset data cache

uint8_t updateDataCache(DataCache *cache, DataEntry *data);
// Pre:  DataEntry is a new data to be cached
// Post: The data is cached if it is not a duplicate.
//       If cache is full the oldest data is droped.
//       Returns 0 on duplicate.



#endif

