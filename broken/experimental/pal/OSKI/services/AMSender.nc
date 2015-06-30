generic configuration AMSender(am_type_t type) {
  provides interface SendAM;
}
implementation {
  components ActiveMessagesImpl;

  SendAM = ActiveMessagesImpl.Send[type];
}


