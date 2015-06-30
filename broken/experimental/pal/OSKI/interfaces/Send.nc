interface Send {
  command error_t send(TOS_MsgPtr msg, uint8_t len);
  command void sendSucceeded(TOS_MsgPtr msg);
  command void sendFailed(TOS_MsgPtr msg, error_t error);
}



