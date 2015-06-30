configuration BcastCommand {
  provides {
    interface HandleBcast;
  }
}
implementation {
  components VirtualComm, BcastCommandM;
  HandleBcast = BcastCommandM;
  BcastCommandM.VCSend -> VirtualComm.VCSend[RS_COMMAND_TYPE];
  BcastCommandM.VCExtractHeader -> VirtualComm.VCExtractHeader;
  BcastCommandM.ReceiveBcastMsg -> VirtualComm.ReceiveMsg[RS_COMMAND_TYPE];
}
