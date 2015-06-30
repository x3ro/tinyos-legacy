interface MHSend2Comm {
  command result_t send(TOS_MsgPtr msg, uint8_t isOriginated);
  event void moveOnNextPacket(TOS_MsgPtr msg);
  event uint8_t sendDoneFailException(TOS_MsgPtr msg);
}
