interface TxMan {
  command result_t enqueueTx(TOS_MsgPtr msg);
  command void setSlots(uint8_t slots);
  command void tick();
}


