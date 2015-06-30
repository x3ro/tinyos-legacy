configuration RadioCRCPacket {
  provides {
    interface SplitControl as Control;
    interface SendSP as Send;
    interface ReceiveSP as Receive;
    interface LinkEstimator;
    interface SPLinkAdaptor;
  }
}
implementation {
  components CC2420RadioC as RadioCRCPacketM, CC2420LinkEstimatorM;

  Control = RadioCRCPacketM;
  Send = RadioCRCPacketM.Send;
  Receive = RadioCRCPacketM.Receive;
  LinkEstimator = CC2420LinkEstimatorM;
  SPLinkAdaptor = RadioCRCPacketM;
}
