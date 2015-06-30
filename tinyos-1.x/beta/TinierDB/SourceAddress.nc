includes AM;

interface SourceAddress {
  command uint16_t getAddress(TOS_MsgPtr msg);
}
