module EchoM {
  uses {
    interface ReceiveMsg[uint8_t id];
    interface SendMsg[uint8_t id];
  }
}
implementation {
  TOS_Msg echoBuf;
  bool echoBufBusy;

  task void sendBuf();

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
    if (echoBufBusy) {
      return msg;
    }
    echoBufBusy = TRUE;
    memcpy(&echoBuf, msg, sizeof(TOS_Msg));
    post sendBuf();
  }

  task void sendBuf() {
    call SendMsg.send[echoBuf.type](echoBuf.addr, echoBuf.length, &echoBuf);
  }

  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t result) {
    if (msg == &echoBuf) 
      echoBufBusy = FALSE;
    return SUCCESS;
  }
}
