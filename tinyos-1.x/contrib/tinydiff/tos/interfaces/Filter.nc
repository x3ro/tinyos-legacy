includes DiffMsg;
interface Filter
{
  command result_t addFilter(Attribute *attrArray, uint8_t numAttrs);
  command result_t removeFilter();
  event result_t receiveMatchingMsg(DiffMsgPtr msg);
  command result_t sendMessage(DiffMsgPtr msg, uint8_t priority);

  command uint8_t getMyPriority();
  // This command is to enable a filter to query the next sequence number
  // in order to build a packet... this is needed because a filter might
  // create new packets and needs to know what sequence number to give them
  // since it is responsible for the whole packet... (all other fields in 
  // the packet don't need such explicit querying)...

  command uint16_t getNextSeqNum();
}
