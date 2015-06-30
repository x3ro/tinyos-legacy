interface quickGTS {
  command result_t create(uint8_t tupleSize, uint8_t totalNum, uint8_t fieldNum);
  event result_t createDone(result_t success);
  command result_t drop();
  command result_t store(GenericTuplePtr gTuplePtr);
  event result_t full();
  command result_t search(GenericQueryPtr gQueryPtr);
  event result_t found(GenericTuplePtr gTuplePtr);
  command result_t delete(uint32_t timeLo, uint32_t timeHi);
}
