generic configuration AMReceiver(am_type_t type) {
  provides interface Receive;
}
implementation {
  components ActiveMessagesImpl;

  Receive = ActiveMessagesImpl.Receive[type];
}


