interface HandleBcast {
  command uint8_t* extractData(TOS_MsgPtr msg);
  event void execute(TOS_MsgPtr msg);
}
