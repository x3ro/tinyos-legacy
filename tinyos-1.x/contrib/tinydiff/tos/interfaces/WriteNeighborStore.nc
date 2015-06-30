// interface used to write to a NeighborStore
interface WriteNeighborStore {
  
  // commands to set a single metric...
  command result_t setNeighborMetric16(uint16_t neighbor, uint8_t type, 
				      uint16_t metric);
  command result_t setNeighborMetric32(uint16_t neighbor, uint8_t type, 
				      uint32_t metric);

  // commands to set metrics of all neighbors... and return # neighbors set
  command uint8_t setMetric16ForAll(NeighborValue16 *neighbors,
				  uint8_t count, uint8_t type);
  command uint8_t setMetric32ForAll(NeighborValue32 *neighbors,
				  uint8_t count, uint8_t type);

  // set a blob for a neighbor; expect SUCCESS or FAIL
  command result_t setNeighborBlob(uint16_t neighbor, uint8_t type,
				   uint8_t *buffer, uint8_t length);

  // remove neighbor from neighborlist
  command result_t removeNeighbor(uint16_t neighbor);


  // command result_t setFlag(uint16_t neighbor, uint8_t flag);
}
