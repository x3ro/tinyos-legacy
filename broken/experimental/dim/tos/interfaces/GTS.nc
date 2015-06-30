interface GTS {
  command result_t create(uint8_t recordSize, uint8_t capacity, uint8_t fieldNum);
  command result_t drop();
  event result_t dropDone();
  command result_t store(void *data);
  event result_t storeDone();
  //command result_t getAt(uint8_t idx);
  //event result_t getAtDone(void *data, uint8_t size);
  event result_t broken(uint8_t errorNo);
  event result_t full();
  command result_t search(GenericQueryPtr gQueryPtr);
  event result_t found(GenericTuplePtr gTuplePtr);
  command result_t searchFirst(GenericQueryPtr gQueryPtr);
  command result_t searchNext();
  event result_t searchDone();
}
