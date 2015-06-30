generic configuration AMSnoopingReceiver(am_type_t type) {
  provides interface Receive;
}
implementation {
  components ActiveMessagesImpl;

  Receive = ActiveMessagesImpl.Receive[type];
  Receive = ActiveMessagesImpl.Snoop[type];
}


