interface SendAM {
  command error_t send(am_addr_t dest, TOS_MsgPtr msg, uint8_t len);
  command void sendSucceeded(TOS_MsgPtr msg);
  command void sendFailed(TOS_MsgPtr msg, error_t error);
}

