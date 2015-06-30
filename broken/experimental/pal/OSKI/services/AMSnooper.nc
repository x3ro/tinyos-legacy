generic configuration AMSnooper(am_type_t type) {
  provides interface Receive;
}
implementation {
  components ActiveMessagesImpl;

  Receive = ActiveMessagesImpl.Snoop[type];
}


