/* Header file for the interest cache implementation.
   The interest cache provides the data dtructure to
   cache interests and, the gradients list to which the 
   interest coresponds, reinforcement list which holds
   the relavent data for reinforcement path selection.
*/ 
#ifndef __INTERESTCACHE_INC_
#define __INTERESTCACHE_INC_

#include "subscribe.h"
#include "OnePhasePull.h"
#include "DataStructures.h"


// Interest Gradiend Entry

typedef struct InterestGradientEntryStruct 
{
  uint16_t prevHop;      // last hop
  // expiration time allows for interest aggregation
  uint16_t expiration;	 // expiration time of interest(or reinforcement)
} InterestGradient;


// Data Gradient Entry

typedef struct DataGradientStruct
{
  uint16_t source;     // source of packet
  uint16_t prevHop;    // last hop
} DataGradient;


// Interest Cache Entry
// The Interest Entry is implements a FIFO queue for gradients and
// Reinforcements of limited size.

typedef struct InterestEntryStruct 
{
  InterestMessage interest;        // Cached Interest or Reinforcement
  InterestGradient gradients[MAX_GRADIENTS];          // Gradients list
  SubscriptionHandle subHandle;
  uint8_t  numGradients;    // Number of Interest Gradient Entries cached
} InterestEntry;

// Interest Cache

typedef struct InterestCacheStruct 
{
  InterestEntry entries[MAX_INTERESTS];   // Limited Array of Data Entries
} InterestCache;


// ================ Functions Prototypes =======================


void initInterestCache(InterestCache * cache);
// Post: Initialize or reset interest cache

UPDATE_STATUS updateInterestCache( InterestCache * cache,  
			     InterestMessage * interest);

// Pre:  interest is a new interest to be cached.
// Post: The interest is cached if it is not a duplicate.
//       If cache is full the oldest interest is droped.
//       Returns 0 on duplicate.
//       At every interest update expired interests are droped.


void initInterestGradient(InterestEntry * entry);
// Post: Initialize or reset interest cache

void updateInterestGradient(InterestEntry * entry, InterestGradient * gradient);

// Pre:  gradient is a new gradient to be cached
// Post: The gradient is cached if it is not a duplicate.
//       If cached was full the oldest gradient is droped.



void updateDataGradient(InterestEntry * entry, DataGradient * reinforcement);

// Pre:  reinforcement is a new reinforcement to be cached
// Post: The reinforcement is cached if it is not a duplicate.
//       If cached was full the oldest reinforcement is droped.


uint8_t getInterestGradient(InterestEntry * entry, uint16_t *gradients,
			    uint8_t maxCount);
// Pre:  Entry is an intrest entry in the  chache
// Post: gradients array returns with all garadients of the interest origin.
//       Function returns the number of gradients. 

InterestEntry *findIntEntryBySubHandle(InterestCache *cache, 
				       SubscriptionHandle handle);

result_t unsubscribeByHandle(InterestCache *cache, SubscriptionHandle handle);
// Drops all interests off the sink from interest cache


SubscriptionHandle getNextSubHandle(InterestCache *cache,
				    SubscriptionHandle handle);

InterestEntry *allocateInterestEntry(InterestCache *cache);

InterestEntry *addInterestCacheEntry(InterestCache *cache,
				     InterestMessage *interest, 
				     SubscriptionHandle handle);

void ageInterests(InterestCache *cache);

#endif





