includes NeighborStore;
module NeighborStoreM {
  provides {
    interface StdControl;
    interface ReadNeighborStore;
    interface WriteNeighborStore;
  }
}
implementation 
{
  uint8_t nextNeighbor;
  typedef struct {
    uint16_t neighborId;
    uint16_t metric16[MAX_NUM_16BIT_METRICS];
    uint32_t metric32[MAX_NUM_32BIT_METRICS];
    uint8_t metricBlob[MAX_BLOB_STORE_SIZE];
  } StoreElement;
  
  StoreElement store[MAX_NUM_NEIGHBORS];

  void initElement(uint8_t element)
  {
    memset((char *)&store[element], 0, sizeof(StoreElement));
    if (MAX_BLOB_STORE_SIZE >= 1)
    {
      store[element].metricBlob[0] = NS_BLOB_END_MARKER;
    }
  }

  command result_t StdControl.init() 
  {
    int i = 0;

    nextNeighbor = 0;

    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      initElement(i);
    }
    dbg(DBG_USR2, "NeighborStore: StdControl.init() called\n");

    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    return SUCCESS;
  }

  int8_t findNeighborEntry(uint16_t id)
  {
    uint8_t i = 0;

    if (id == NULL_NEIGHBOR_ID)
    {
      return -1;
    }

    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (store[i].neighborId == id)
      {
	return i;
      }
    }

    return -1;
  }
  
  int8_t findFreeEntry()
  {
    uint8_t i = 0;

    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (store[i].neighborId == NULL_NEIGHBOR_ID)
      {
	return i;
      }
    }

    return -1;
  }
  
  // iterates over the neighborlist...
  command uint16_t ReadNeighborStore.getNextNeighbor(NeighborIterator *iterator)
  {
    uint8_t i = 0;

    // sanity checks...
    if (iterator == NULL)
    {
      return 0;
    }
    if (*iterator >= MAX_NUM_NEIGHBORS)
    {
      *iterator = 0;
    }

    for (i = *iterator; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (store[i].neighborId != NULL_NEIGHBOR_ID) 
      {
	// set the iterator to the next position...
	*iterator = ((i + 1) >= MAX_NUM_NEIGHBORS ? 0 : (i + 1));
	return store[i].neighborId;
      }
    }
    // Could not find non-zero neighbor until end of list... let's search
    // before the *iterator position
    // This code implements wrap-around. 
    for (i = 0; i < *iterator; i++)
    {
      if (store[i].neighborId != NULL_NEIGHBOR_ID) 
      {
	// set the iterator to the next position...
	*iterator = ((i + 1) >= MAX_NUM_NEIGHBORS ? 0 : (i + 1));
	return store[i].neighborId;
      }
    }

    // This corresponds to there being no neighbor records...
    return 0;
  }

  // Fills up list nlist with neighbors.. and returns # neighbors
  // This code assumes that the array "nList" is as big as
  // MAX_NUM_NEIGHBORS, since the idea is to get all neighbors.. and
  // MAX_NUM_NEIGHBORS is not very large anyway (15 or so)
  command uint8_t ReadNeighborStore.getNeighbors(uint16_t *nList, 
						 uint8_t size)
  {
    uint8_t i = 0;
    uint8_t offset = 0;

    if (size == 0)
    {
      return 0;
    }

    offset = 0;
    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (store[i].neighborId != NULL_NEIGHBOR_ID) 
      {
	nList[offset] = store[i].neighborId;
	offset++;
	if (offset >= size)
	{
	  return offset;
	}
      }
    }
    return offset;
  }

  // returns # neighbors
  command uint8_t ReadNeighborStore.getNumNeighbors()
  {
    uint8_t i = 0;
    uint8_t count = 0;

    // could have maintained a running count of neighbors... but on motes, we
    // are not trying to make code efficient by trading memory....
    count = 0;
    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (store[i].neighborId != NULL_NEIGHBOR_ID) 
      {
	count++;
      }
    }
    return count;
  }

  // commands to get 16 bit metrics of all neighbors... and return # neighbors
  command uint8_t ReadNeighborStore.getMetric16ForAll
    (NeighborValue16 *neighbors, uint8_t number, uint8_t type) 
  {
    uint8_t i = 0;
    uint8_t offset = 0;

    if (type >= MAX_NUM_16BIT_METRICS)
    {
      // return 0, meaning none were found/filled in
      return 0;
    }

    offset = 0;
    for (i = 0; i < MAX_NUM_NEIGHBORS && offset < number; i++)
    {
      if (store[i].neighborId != NULL_NEIGHBOR_ID) 
      {
	neighbors[offset].neighbor = store[i].neighborId;
	neighbors[offset].metric = store[i].metric16[type];
	offset++;
      }
    }

    return offset;
  }

  // commands to get 32 bit metrics of all neighbors... and return # neighbors
  command uint8_t ReadNeighborStore.getMetric32ForAll
    (NeighborValue32 *neighbors, uint8_t number, uint8_t type) 
  {
    uint8_t i = 0;
    uint8_t offset = 0;

    if (type >= MAX_NUM_32BIT_METRICS)
    {
      // return 0, meaning none were found/filled in
      return 0;
    }

    offset = 0;
    for (i = 0; i < MAX_NUM_NEIGHBORS && offset < number; i++)
    {
      if (store[i].neighborId != NULL_NEIGHBOR_ID) 
      {
	neighbors[offset].neighbor = store[i].neighborId;
	neighbors[offset].metric = store[i].metric32[type];
	offset++;
      }
    }

    return offset;
  }

  // commands to get a single 16-bit metric from a neighbor...
  command result_t ReadNeighborStore. getNeighborMetric16(uint16_t neighbor, 
							  uint8_t type, 
							  uint16_t *pValue)
  {
    int8_t element = 0;

    if (type >= MAX_NUM_16BIT_METRICS)
    {
      return FAIL;
    }
    
    if (pValue == NULL)
    {
      return FAIL;
    }

    element = findNeighborEntry(neighbor);

    if (element < 0)
    {
      return FAIL;
    }

    *pValue = store[element].metric16[type];

    return SUCCESS;
  }
 

  // commands to get a single 32-bit metric from a neighbor...
  command result_t ReadNeighborStore. getNeighborMetric32(uint16_t neighbor, 
							  uint8_t type, 
							  uint32_t *pValue)
  {
    int8_t element = 0;

    if (type >= MAX_NUM_32BIT_METRICS)
    {
      return FAIL;
    }

    element = findNeighborEntry(neighbor);

    if (element < 0)
    {
      return FAIL;
    }

    *pValue = store[element].metric32[type];

    return SUCCESS;
  }

  // commands to set a single 16-bit metric...
  command result_t WriteNeighborStore.setNeighborMetric16(uint16_t neighbor, 
							  uint8_t type, 
							  uint16_t metric)
  {
    int8_t element = 0;

    if (type >= MAX_NUM_16BIT_METRICS)
    {
      return FAIL;
    }
    if (neighbor == NULL_NEIGHBOR_ID)
    {
      return FAIL;
    }

    element = findNeighborEntry(neighbor);

    if (element < 0)
    {
      // if not present... add new one
      element = findFreeEntry();
      if (element < 0)
      {
	return FAIL;
      }
      store[element].neighborId = neighbor;
    }

    store[element].metric16[type] = metric;

    return SUCCESS;
  }
  
  // commands to set a single 32-bit metric...
  command result_t WriteNeighborStore.setNeighborMetric32(uint16_t neighbor, 
							  uint8_t type, 
							  uint32_t metric)
  {
    int8_t element = 0;

    if (type >= MAX_NUM_32BIT_METRICS)
    {
      return FAIL;
    }
    if (neighbor == NULL_NEIGHBOR_ID)
    {
      return FAIL;
    }

    element = findNeighborEntry(neighbor);

    if (element < 0)
    {
      return FAIL;
    }

    store[element].metric32[type] = metric;

    return SUCCESS;
  }
  
  // commands to set 16-bit metrics of all neighbors... and return # 
  // neighbors set
  command uint8_t WriteNeighborStore.setMetric16ForAll
    (NeighborValue16 *neighbors, uint8_t number, uint8_t type)
  {
    uint8_t i = 0;
    int8_t element = 0;
    uint8_t numSet = 0;

    numSet = 0;
    if (type >= MAX_NUM_16BIT_METRICS)
    {
      // return 0, meaning none were found/filled in
      return numSet;
    }

    for (i = 0; i < number; i++)
    {
      if (neighbors[i].neighbor == NULL_NEIGHBOR_ID)
      {
	continue;
      }

      element = findNeighborEntry(neighbors[i].neighbor);
      if (element < 0)
      {
	// if not present... add new one
	element = findFreeEntry();
	if (element < 0)
	{
	  continue;
	}
	store[element].neighborId = neighbors[i].neighbor;
      }

      store[element].metric16[type] = neighbors[i].metric;
      numSet++;
    }

    return numSet;
  }

  // commands to set 16-bit metrics of all neighbors... and return # 
  // neighbors set
  command uint8_t WriteNeighborStore.setMetric32ForAll
    (NeighborValue32 *neighbors, uint8_t number, uint8_t type)
  {
    uint8_t i = 0;
    int8_t element = 0;
    uint8_t numSet = 0;

    numSet = 0;
    if (type >= MAX_NUM_32BIT_METRICS)
    {
      // return 0, meaning none were found/filled in
      return numSet;
    }

    for (i = 0; i < number; i++)
    {
      if (neighbors[i].neighbor == NULL_NEIGHBOR_ID)
      {
	continue;
      }

      element = findNeighborEntry(neighbors[i].neighbor);
      if (element < 0)
      {
	// if not present... add new one
	element = findFreeEntry();
	if (element < 0)
	{
	  continue;
	}
	store[element].neighborId = neighbors[i].neighbor;
      }


      store[element].metric32[type] = neighbors[i].metric;
      numSet++;
    }

    return numSet;
  }

  /* Points about blob storage in the NeighborStore module:
   * - This code assumes that the amount of buffer space available for blobs
   *   is enough... otherwise, the setNeighborBlob command will fail
   * - The representation of data in the blob space is in the usual
   *   Type-Length-Values format.  This is done in order to be able to
   *   store say type 1 and type 3 blobs, if they were the only ones used
   *   in the current system, and not implicitly set aside space for blob 2 for
   *   instance... this means that the size of the blob space 
   *   (MAX_BLOB_STORE_SIZE) can be tuned to just the requirement of the
   *   configuration that is used.
   * - Another reason for this format is that the size of the blob can be
   *   changed by the programmer without having to let the NeighborStore module
   *   know (as long as there's enough space)...  so the "length" parameter is 
   *   kept explicit
   * - The length parameter in the T-L-V is the number of bytes taken by
   *   the values, not by the entire TLV combination
   * - invariant: there's always an end marker... and the end marker has a
   *   type field of NS_BLOB_END_MARKER and no length or data following it
   */
   // returns SUCCESS/FAIL
   // the pBufferLen parameter is a read-write parameter that initially
   // specifies the amount of available buffer space and upon return holds
   // the actual size of the blob
   // NOTE: this command never sets more than length number of bytes in
   // the buffer... if the buffer size is insufficient, it returns FAIL
  command result_t ReadNeighborStore.getNeighborBlob(uint16_t neighbor, 
						     uint8_t reqType, 
						     uint8_t *buffer, 
						     uint8_t *pBufferLen)
  {
    uint8_t type = 0; 
    uint8_t length = 0;
    uint8_t offset = 0;
    int8_t element = 0;

    if (MAX_BLOB_STORE_SIZE <= 2 || NS_MAX_NUM_BLOBS == 0)
    {
      dbg(DBG_ERROR, "getNeighborBlob: MAX_BLOB_STORE_SIZE = %d "
	  "NS_MAX_NUM_BLOBS = %d\n", MAX_BLOB_STORE_SIZE, NS_MAX_NUM_BLOBS);
      return FAIL;
    }
    
    if (buffer == NULL || pBufferLen == NULL)
    {
      dbg(DBG_ERROR, "getNeighborBlob: buffer = %d, pBufferLen = %d!!\n",
	  buffer, pBufferLen);
      return FAIL;
    }

    element = findNeighborEntry(neighbor);
    if (element < 0)
    {
      dbg(DBG_ERROR, "getNeighborBlob: couldn't find neighbor entry\n");
      return FAIL;
    }

    offset = 0;
    type = store[element].metricBlob[offset];
    length = store[element].metricBlob[offset + 1];
    while (type != NS_BLOB_END_MARKER || 
	   offset + length + 2 < MAX_BLOB_STORE_SIZE)
    {
      if (type == reqType)
      {
	if (length > *pBufferLen)
	{
	  dbg(DBG_ERROR, "getNeighborBlob: found blob but bigger than buffer "
	      "passed: length = %d, pBufferLen = %d\n", length, *pBufferLen);
	  return FAIL;
	}
	else
	{
	  // this is definitely within the blob space of this neighbor
	  // since we've already made the check above
	  memcpy(buffer, store[element].metricBlob + offset + 2, length);
	  // set the read-write parameter to the length of blob
	  *pBufferLen = length;
	  return SUCCESS;
	}
      }
      // skip over to the next blob... including type and length fields...
      offset += length + 2; 
      // check if we are going to fall off the end of blob array
      if (offset + 2 >= MAX_BLOB_STORE_SIZE)
      {
	if (offset < MAX_BLOB_STORE_SIZE)
	{
	  store[element].metricBlob[offset] = NS_BLOB_END_MARKER;
	}
	break;
      }
      type = store[element].metricBlob[offset];
      length = store[element].metricBlob[offset + 1];
    }

    if (offset < MAX_BLOB_STORE_SIZE && 
	store[element].metricBlob[offset] != NS_BLOB_END_MARKER)
    {
      dbg(DBG_ERROR, "getNeighborBlob: expecting marker, but found none.\n");
      store[element].metricBlob[offset] = NS_BLOB_END_MARKER;
    }
    dbg(DBG_ERROR, "getNeighborBlob: could not find blob\n");
    return FAIL;
  }

  
  // Find the offset of the end marker... this function is useful in
  // evaluating if there's enough space for another blob, etc...
  uint8_t findEndMarkerOffset(uint8_t neighborIndex)
  {
    uint8_t offset = 0;
    uint8_t length = 0;

    offset = 0;
    length = store[neighborIndex].metricBlob[offset + 1];
    while (store[neighborIndex].metricBlob[offset] != NS_BLOB_END_MARKER && 
	   offset + 2 + length < MAX_BLOB_STORE_SIZE - 1) // -1 due to end marker 
    {
      // increment offset by length of blob entry...
      offset += store[neighborIndex].metricBlob[offset + 1];
    }

    if (store[neighborIndex].metricBlob[offset] != NS_BLOB_END_MARKER)
    // something seriously wrong! spurious entry
    {
      dbg(DBG_ERROR, "NeighborStore: findMarkerOffet: unable to fine end "
	  "marker!!\n");
      // delete spurious entry..
      store[neighborIndex].metricBlob[offset] = NS_BLOB_END_MARKER;
    }

    return offset;
  }
   
  // set a blob for a neighbor; expect SUCCESS or FAIL
  command result_t WriteNeighborStore.setNeighborBlob(uint16_t neighbor, 
						     uint8_t reqType, 
						     uint8_t *buffer, 
						     uint8_t bufferLen)
  {
    uint8_t type = 0; 
    uint8_t length = 0;
    uint8_t offset = 0;
    int8_t element = 0;

    if (MAX_BLOB_STORE_SIZE <= 2 || NS_MAX_NUM_BLOBS <= 0)
    {
      dbg(DBG_ERROR, "NeighborStore: setNeighborBlob: MAX_BLOB_STORE_SIZE = %d"
	  " or NS_MAX_NUM_BLOBS = %d\n", MAX_BLOB_STORE_SIZE, NS_MAX_NUM_BLOBS);
      return FAIL;
    }
    
    // it is illegal to have a neighbor id of 0
    if (neighbor == NULL_NEIGHBOR_ID)
    {
      dbg(DBG_ERROR, "setNeighborBlob: neighbor id is NULL\n");
      return FAIL;
    }

    element = findNeighborEntry(neighbor);
    if (element < 0)
    {
      // can't find entry... try creating one.
      element = findFreeEntry();
      if (element < 0)
      {
	// unable to create one... fail.
	dbg(DBG_ERROR, "setNeighborBlob: unable to create new entry\n");
	return FAIL;
      }
      store[element].neighborId = neighbor;
      store[element].metricBlob[0] = NS_BLOB_END_MARKER;
    }

    offset = 0;
    type = store[element].metricBlob[offset];
    length = store[element].metricBlob[offset + 1];
    while (type != NS_BLOB_END_MARKER && 
	   offset + length + 2 <= MAX_BLOB_STORE_SIZE - 1) // -1 due to end marker
    {
      if (type == reqType)
      {
	dbg(DBG_TEMP, "setNeighborBlob: type = %d; match found; offset = %d\n", 
	    reqType, offset);
	if (length >=  bufferLen) // enough space in matching entry. just memcpy.
	{
	  memcpy(store[element].metricBlob + offset + 2, buffer, bufferLen);
	  // if newer blob was smaller, we need to do some shifting...
	  if (store[element].metricBlob[offset + 1] > bufferLen)
	  {
	    // shift the remaining stuff to shrink the blob size...
	    memcpy(store[element].metricBlob + offset + 2 + bufferLen,
		   store[element].metricBlob + offset + 2 + length,
		   MAX_BLOB_STORE_SIZE - (offset + 2 + length));

	  }
	  store[element].metricBlob[offset + 1] = bufferLen;
	  return SUCCESS;
	}
	else
	// match found, but the existing entry is smaller than the newer
	// one.  If we can delete existing entry and add the new one,
	// delete existing entry; if not, return FAIL; 
	{
	  if ((MAX_BLOB_STORE_SIZE - findEndMarkerOffset(element) - 1) < 
	      (bufferLen - length))
	  {
	    dbg(DBG_ERROR, "setNeighborBlob: match found but new entry "
		"longer by more than space remaining\n");
	    return FAIL;
	  }
	  else
	  {
	    memcpy(store[element].metricBlob + offset, 
		   store[element].metricBlob + offset + 2 + length, 
		   MAX_BLOB_STORE_SIZE - (offset + 2 + length));
	  }
	}
      }

      offset += length + 2; // including type and length fields...
      type = store[element].metricBlob[offset];
      length = store[element].metricBlob[offset + 1];
    }

    // now, offset should point to the end marker... since it is always the
    // last one...
    if (store[element].metricBlob[offset] != NS_BLOB_END_MARKER)
    // something seriously wrong! spurious entry
    {
      dbg(DBG_ERROR, "setNeighborBlob: type = %d; expecting END_MARKER but found "
	  "something else... writing END_MARKER; offset = %d, blob[%d] = %d\n", 
	  reqType, offset, offset, store[element].metricBlob[offset]);
      // delete spurious entry..
      store[element].metricBlob[offset] = NS_BLOB_END_MARKER;
    }

    if ((MAX_BLOB_STORE_SIZE - offset - 1) < bufferLen + 2) 
    // -1 due to end marker
    {
      dbg(DBG_ERROR, "setNeighborBlob: adding new entry, but not enough space "
	  "MAX_BLOB_STORE_SIZE = %d, offset = %d, bufferLen = %d\n",
	  MAX_BLOB_STORE_SIZE, offset, bufferLen);
      return FAIL;
    }

    store[element].metricBlob[offset] = reqType;
    store[element].metricBlob[offset + 1] = bufferLen;
    memcpy(store[element].metricBlob + offset + 2, buffer, bufferLen);
    store[element].metricBlob[offset + 2 + bufferLen] = NS_BLOB_END_MARKER;
    dbg(DBG_TEMP, "setNeighborBlob: SUCCESS; type = %d metricBlob[%d] = "
	"END_MARKER\n", reqType, offset + 2 + bufferLen);
	
    return SUCCESS;
  }

  // remove neighbor from neighborlist
  // TODO: for the long term; allow call backs upon removed neighbors or
  // upon such changes in neighbor status.
  command result_t WriteNeighborStore.removeNeighbor(uint16_t neighbor)
  {
    int8_t element = 0;

    element = findNeighborEntry(neighbor);
    if (element < 0)
    {
      dbg(DBG_ERROR, "NeighborStore: removeNeighbor: findNeighborEntry "
	  "returned ZERO!\n");
      return FAIL;
    }

    initElement(element);
    dbg(DBG_USR3, "NeighborStore: removeNeighbor: findNeighborEntry "
	"RESETTING ENTRY; id = %d!\n", store[element].neighborId);

    return SUCCESS;
  }
}
