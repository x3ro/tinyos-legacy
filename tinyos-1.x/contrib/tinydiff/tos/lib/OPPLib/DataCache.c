/* Implementation file for the data cache
   The data cache serves to eliminate duplicates.
   Due to the natural memory limitation of the motes it is implemented
   as a queue - FIFA. 
*/

#include "DataCache.h"

// ===================== initialize data cache =============


void initDataCache(DataCache *cache)
// Post: Initialize or reset data cache
{
  cache->head = 0;
  memset(cache->entries, 0, sizeof(DataEntry) * MAX_DATA);
}

// ==================== update data cache ===================

uint8_t updateDataCache(DataCache * cache, DataEntry * data)
// Pre:  DataEntry is a new data to be cached
// Post: The data is cached if it is not a duplicate.
//       If cached was full the oldest data is droped.
//       Returns NULL on duplicate.

{

  // Check for duplicates

  uint8_t i = 0 ;

  for (i = 0; i < MAX_DATA; i++)
  {
    if ((cache->entries[i].seqNum == data->seqNum)
	&& (cache->entries[i].source  == data->source))
    {
      return UPDATE_DUPLICATE;
    }
  }

  // No Duplicates

  cache->head = ((cache->head + 1 >= MAX_DATA )? 0 : cache->head + 1);

  // Update new data
  cache->entries[cache->head].seqNum = data->seqNum;
  cache->entries[cache->head].source = data->source; 
  
  return UPDATE_ADDED;
}
