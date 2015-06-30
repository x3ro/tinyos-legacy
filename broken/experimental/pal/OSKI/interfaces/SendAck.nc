interface SendAck {
  command error_t send(TOS_MsgPtr msg, uint8_t len);
  command void sendAcked(TOS_MsgPtr msg);
  command void sendUnacked(TOS_MsgPtr msg);
  command void sendFailed(TOS_MsgPtr msg, error_t error);
}
