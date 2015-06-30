module MotlleSend {
  provides interface StdControl;
  uses interface SendMsg;
}
implementation {
  TOS_Msg motlleMsg;
  bool sending;

  command result_t StdControl.init() {
    sending = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  uint8_t motlle_req_send_msg(uint8_t *data, uint8_t len)
    __attribute__((C, spontaneous)) {

    if (sending)
      return FALSE;

    if (len > DATA_LENGTH)
      return FALSE;

    memcpy(motlleMsg.data, data, len);

    if (call SendMsg.send(TOS_BCAST_ADDR, &motlleMsg, len))
      {
	sending = TRUE;
	return TRUE;
      }
    return FALSE;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == &motlleMsg)
      sending = FALSE;
  }
}
