interface AggressiveSendControl {

  command void setRetries(uint8_t numRetries);
  command uint8_t getRetries();
  
  command void setBcastRetries(uint8_t numRetries);
  command uint8_t getBcastRetries();

  event void transmitted(TOS_MsgPtr msg);
}
