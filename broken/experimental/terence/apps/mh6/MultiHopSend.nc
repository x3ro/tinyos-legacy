includes AM;
interface MultiHopSend {
  command result_t send(TOS_MsgPtr msg, uint8_t length);
  command uint8_t* getUsablePortion(uint8_t *data);
  event void sendDone(TOS_MsgPtr msg, uint8_t success);
}
