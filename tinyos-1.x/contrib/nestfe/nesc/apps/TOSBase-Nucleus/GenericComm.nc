configuration GenericComm {
  provides {
    interface StdControl;
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];
  }
  uses {
    interface SendMsg as SendMsgUse[uint8_t id];
    interface ReceiveMsg as ReceiveMsgUse[uint8_t id];
  }
}
implementation {
  components NoControlM;
  StdControl = NoControlM;
  SendMsg = SendMsgUse;
  ReceiveMsg = ReceiveMsgUse;
}

