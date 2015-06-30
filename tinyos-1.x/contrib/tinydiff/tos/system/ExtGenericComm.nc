configuration ExtGenericComm
{
  provides 
  {
    interface StdControl as Control;

    interface SendVarLenPacket as UARTSendRawBytes;
    
    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];

    // How many packets were received in the past second
    command uint16_t activity();
  }
  uses
  {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();
  }
}
implementation
{
  components GenericComm, ExtGenericCommM;

  Control = GenericComm.Control;
  UARTSendRawBytes = GenericComm.UARTSendRawBytes;
  SendMsg = ExtGenericCommM.ProvidedSendMsg;
  ReceiveMsg = ExtGenericCommM.ProvidedReceiveMsg;

  ExtGenericCommM.UsedSendMsg -> GenericComm.SendMsg;
  ExtGenericCommM.UsedReceiveMsg -> GenericComm.ReceiveMsg;
}
  
