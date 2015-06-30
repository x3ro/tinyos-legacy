includes AM;
interface VCSend {
  command result_t send(uint16_t address, uint8_t length, TOS_MsgPtr msg);
  event void moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered);
  event uint8_t sendDoneFailException(TOS_MsgPtr msg);
  command uint8_t* getUsablePortion(uint8_t *data);

}
