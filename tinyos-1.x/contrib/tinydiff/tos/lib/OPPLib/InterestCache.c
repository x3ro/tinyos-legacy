/* Implementation file for the interest cache.  
 * The interest cache provides the data dtructure to
 * cache interests and, the gradients list to which the 
 * interest coresponds, reinforcement list which holds
 * the relavent data for reinforcement path selection.
 * 
 * Authors: Moshe Golan, Mohan Mysore
*/ 


#include "InterestCache.h"
#include "MatchingRules.h"
#include "Debug.h"


// ================ Functions Implementation  =======================

void initInterestEntry(InterestEntry *entry)
{
  if (entry != NULL)
  {
    memset((char *)entry, 0, sizeof(InterestEntry));
    entry->interest.expiration = 0;
  }
}


// ================ initialize Interest Cache =======================
void initInterestCache( InterestCache * cache )
// Post: Initialize or reset interest cache
{
  uint8_t i = 0;

  memset((char *)cache, 0, sizeof(InterestCache));
  for (i = 0; i < MAX_INTERESTS; i++)
  {
    initInterestEntry(&cache->entries[i]);
  }
}

// ================== intialize an interest entry ============

void initInterestGradient(InterestEntry *entry)
// Post: Initialize or reset interest cache
{
  // Error chaecking
  if (entry != NULL)
  {
    entry->numGradients  = 0;          
    memset((char *)entry->gradients, 0, MAX_GRADIENTS * sizeof(InterestGradient));
  }
  else
  {
    dbg(DBG_ERROR, "initInterestGradient: entry NULL!!\n");
  }
}

// ================ Update Interest Cache ===========================

UPDATE_STATUS updateInterestCache(InterestCache *cache,  
				  InterestMessage *interest)

// Pre:  interest is a new interest to be cached.
// Post: The interest is cached if it is not a duplicate.
//       If cache is full the oldest interest is dropped.
//       Returns 0 on duplicate.
//       At every interest update, expired interests are dropped.
//       Cache is optimized by matching interest rules.
//       If interests match only expriration is updated.

{
  
  // Check for duplicates

  uint8_t i = 0;        // loop index
  InterestGradient thisGradient;
  InterestEntry *entry = NULL;
  SubscriptionHandle subHandle = SUBSCRIBE_ERROR;

  // Sanity checks...
  if ((cache == NULL) || (interest == NULL))
  {
    dbg(DBG_ERROR, "updateInterestCache: cache = %p or interest = %p\n",
	cache, interest);
    return UPDATE_ERROR;
  }

  // Check for Duplicates - at the same time drop expired interest.

  thisGradient.prevHop = interest->prevHop;
  thisGradient.expiration = interest->expiration;

  for (i = 0; i < MAX_INTERESTS; i++)
  {
    // check all valid entries...
    if ((cache->entries[i].interest.expiration != 0) &&
	(cache->entries[i].interest.seqNum == interest->seqNum) && 
	(cache->entries[i].interest.sink  == interest->sink))
    {
      // we should also make sure that the attributes are equivalent... for
      // debugging purposes. if they indeed turn out to be different, we log
      // it during nido simulations, but in actual working, just keep the
      // older entry which came first...
      if (FALSE == areAttribArraysEquiv(cache->entries[i].interest.attributes, 
					cache->entries[i].interest.numAttrs,
					interest->attributes,
					interest->numAttrs))
      {
	dbg(DBG_USR1, "updateInterestCache: same sink %d and seq %d; but "
	    "different in attributes... updating.\n", interest->sink, 
	    interest->seqNum);
	// update record...
	memcpy(cache->entries[i].interest.attributes, interest->attributes, 
	       interest->numAttrs * sizeof(Attribute)); 
	cache->entries[i].interest.numAttrs = interest->numAttrs;
      }

      updateInterestGradient(&cache->entries[i], &thisGradient);

      return UPDATE_DUPLICATE;
    }
  }

  // No entry found... need to add a new one...

  // TODO : don't do this for interests that were forwarded... set
  // handles only for those interests that have subscriptions...
  subHandle = getNextSubHandle(cache, subHandle);

  entry = addInterestCacheEntry(cache, interest, subHandle);
  if (entry == NULL)
  {
    dbg(DBG_ERROR, "updateInterestCache: addInterestCacheEntry returned NULL!\n");
    return UPDATE_ERROR;
  }
  
  // update gradient...
  updateInterestGradient(entry, &thisGradient);

  dbg(DBG_USR2, "updateInterestCache: updating cache..\n");
  prIntCache(DBG_USR2, TRUE, cache);

  return UPDATE_ADDED;
}

// ================== update an interest gradient ============
void updateInterestGradient(InterestEntry *entry, InterestGradient *gradient)
// Pre:  gradient is a new gradient to be cached
//       The interest is not a duplicate
// Post: The gradient is cached if it is not a duplicate.
//       If cache is full the oldest gradient is dropped.
{
  uint8_t i = 0; // Loop Index

  // ERROR checking
  if ((entry == NULL) || (gradient == NULL))
  {
    dbg(DBG_ERROR, "updateInterestGradient: sanity check failed! "
	"entry = %p, gradient = %p\n", entry, gradient);
    return;
  }

  // check for duplicate gradient
  for (i = 0; i < entry->numGradients ; i++ )
  {
    // If it is the same interest gradient update expiration only if larger
    if (entry->gradients[i].prevHop == gradient->prevHop )
    {
      if (entry->gradients[i].expiration < gradient->expiration )
      {
	entry->gradients[i].expiration = gradient->expiration;
      }
      // This means that if an interest gradient entry already exists for that
      // neighbor, we just replace it if it has a longer expiration...
      // otherwise, simply bail out...
      return;
    }
  }

  // Not a duplicate
  // NOTE: with gradients, we add gradients in the order of arrival... if
  // the gradient array is full, we don't want to replace them since they are
  // the "faster" ones that are preferable... so, we just let go of this
  // gradient...

  if (entry->numGradients < MAX_GRADIENTS)
  {
    // Update Gradient Entry
    entry->gradients[entry->numGradients].expiration = gradient->expiration;
    entry->gradients[entry->numGradients].prevHop = gradient->prevHop;

    // increment size
    entry->numGradients++;
  }

  return;
} // end update Data Gradient


// NOTE: the programmer using this function has the responsibility of passing
// a large enough "gradients" array (and correspodingly a large enough
// maxCount)... otherwise, all the gradient entries may not be picked up
uint8_t getInterestGradient(InterestEntry * entry, uint16_t *gradients,
			    uint8_t maxCount)

// Pre:  Entry is an intrest entry in the  chache
// Post: gradients array returns with all garadients of the interest origin.
//       Function returns the number of gradients. 
{
  uint8_t i = 0 ; // loop counter
  uint8_t minCount = 0;

  // Error Checking
  if (entry == NULL || gradients == NULL)
  {
    return 0;
  }

  minCount = MIN(entry->numGradients, maxCount);
  for( i = 0; i < minCount; i++ )
  {
    gradients[i] =  entry->gradients[i].prevHop;
  }

  return minCount;

}

InterestEntry *findIntEntryBySubHandle(InterestCache *cache, 
				       SubscriptionHandle handle)
{
  uint8_t i = 0;

  for (i = 0; i < MAX_INTERESTS; i++)
  {
    if (cache->entries[i].subHandle == handle &&   // if the handle matches AND
	cache->entries[i].interest.expiration != 0) // if it's a valid entry 
    {
      return &(cache->entries[i]);
    }
  }
  return NULL;
}

// removes an interest entry corresponding to "handle"... 
result_t unsubscribeByHandle(InterestCache *cache, SubscriptionHandle handle)
{
  InterestEntry *entry = NULL;

  entry = findIntEntryBySubHandle(cache, handle);
  if (entry != NULL)
  {
    initInterestEntry(entry);
    return SUCCESS;
  }

  return FAIL;
}

SubscriptionHandle getNextSubHandle(InterestCache *cache,
				    SubscriptionHandle handle)
{
  handle++;
  // NOTE: handle cannot be 0 since that's what is the value of the  handle 
  // in a "fresh" interest cache entry.
  while (handle == 0 || handle == SUBSCRIBE_ERROR ||
	 findIntEntryBySubHandle(cache, handle) != NULL)
  // this will certainly not be an infinite loop because the space of the
  // SubscriptionHandle is much larger than the number of InterestEntries
  // there are...
  {
    handle++;
  }

  return handle;
}

// this function should never return NULL
InterestEntry *allocateInterestEntry(InterestCache *cache)
{
  uint8_t i = 0;
  uint8_t minIndex = 0;

  // Approach: offer the entry with the smallest expiration time... 
  // Since expiration time is a uint, the least value possible is zero...
  // and hence if there's an expired/unused entry, it will be given out...
  // or else, the entry closest to its expiration is offered out -- since
  // the damage done is not too much... and there's a greater chance of that 
  // interest being refreshed
  minIndex = 0; // gotta start somewhere! *shrug*
  for (i = 0; i < MAX_INTERESTS; i++)
  {
    dbg(DBG_USR3, "allocateInterestEntry: index %d expiration %d\n",
	i, cache->entries[i].interest.expiration);
    if (cache->entries[i].interest.expiration < 
	cache->entries[minIndex].interest.expiration)
    {
      minIndex = i;
    }
  }
  
  dbg(DBG_USR3, "allocateInterestEntry: minIndex = %d\n", minIndex);
  return &cache->entries[minIndex];
}

InterestEntry *addInterestCacheEntry(InterestCache *cache,
				     InterestMessage *interest, 
				     SubscriptionHandle handle)
{
  InterestEntry *entry = NULL;

  entry = allocateInterestEntry(cache);
  // allocateInterestEntry *has* to return a non-NULL entry... 
  if (entry == NULL)
  {
    return NULL;
  }
  
  initInterestEntry(entry);
  memcpy((char *)&(entry->interest), (char *)interest, sizeof(InterestMessage));
  initInterestGradient(entry);
  entry->subHandle = handle;

  return entry;
}


void ageInterests(InterestCache *cache)
{
  uint8_t i = 0;          // Outer Loop Counter

  for ( i = 0; i < MAX_INTERESTS ; i++)
  {
    // NOTE: expiration is an unsigned number... so the below code is
    // indeed important.
    if (cache->entries[i].interest.expiration > 0)
    {
      cache->entries[i].interest.expiration--;
      //dbg(DBG_USR3, "ageInterests: decrementing expiration: %d for entry %d!\n",
      //    cache->entries[i].interest.expiration, i);
      // NOTE: expiration is an unsigned number...
      if (cache->entries[i].interest.expiration == 0)
      {
	//dbg(DBG_USR3, "ageInterests: removing interest entry %d!\n", i);
	prIntEnt(DBG_USR3, TRUE, &cache->entries[i]);
	initInterestEntry(&cache->entries[i]);
      }
    }
  }
  //dbg(DBG_USR3, "ageInterests: done.\n");
}

