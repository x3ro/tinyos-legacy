includes NeighborStore;

// interface used to read from a NeighborStore
interface ReadNeighborStore {

  // Fills up list nlist with neighbors.. and returns # neighbors
  command uint8_t getNeighbors(uint16_t *nList, uint8_t size);

  // returns # neighbors
  command uint8_t getNumNeighbors();  

  // iterates over the neighborlist...
  command uint16_t getNextNeighbor(NeighborIterator *iterator);

  // commands to get a single metric from a neighbor...
  command result_t getNeighborMetric16(uint16_t neighbor, uint8_t type, 
				       uint16_t *pValue);
  command result_t getNeighborMetric32(uint16_t neighbor, uint8_t type, 
				       uint32_t *pValue);

  // commands to get metrics of all neighbors... and return # neighbors
  command uint8_t getMetric16ForAll(NeighborValue16 *neighbors, 
				    uint8_t count, uint8_t type);
  command uint8_t getMetric32ForAll(NeighborValue32 *neighbors, 
				    uint8_t count, uint8_t type);

  // get a blob from a neighbor; expect back blob and its length
  command uint8_t getNeighborBlob(uint16_t neighbor, uint8_t type,
				   uint8_t *buffer, uint8_t *pLength);

  // command result_t getFlag(uint16_t neighbor, uint8_t &flag);
}
