interface Zone {
  command result_t getCode(CodePtr codePtr);
  command result_t init(Coord coo);
  command result_t adjust(Coord coo);
  command result_t showCode(Code code, char *text);
  command result_t getAddress(Code code, CoordPtr coordPtr);
  command bool subZone(Code foo, Code bar);
  command result_t encodeTuple(GenericTuplePtr gTuplePtr, uint8_t attrNum, CodePtr gCodePtr, bool mkUpper);
  command result_t encodeQuery(GenericQueryPtr gQueryPtr, uint8_t attrNum, CodePtr gCodePtr);
}
