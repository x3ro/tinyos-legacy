includes Index;

interface Index {
  // command result_t create(char *name, uint8_t attrNum, char **attrNames);
  command result_t create(char *name, uint8_t tsize);
  command result_t drop(char *name);
  command result_t insert(GenericTuplePtr gTuplePtr);
  command IndexDescPtr getByName(char *name);
  event result_t createDone(IndexDescPtr idxDescPtr);
  event result_t memFull();
}
