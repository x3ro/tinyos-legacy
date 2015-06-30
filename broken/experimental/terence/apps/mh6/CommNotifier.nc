interface CommNotifier {
  event void notifyReceive(TOS_MsgPtr msg);
  event void notifySendDone(TOS_MsgPtr msg, bool delivered);
  event void notifySendDoneFail(TOS_MsgPtr msg, uint8_t retransmit);
}
