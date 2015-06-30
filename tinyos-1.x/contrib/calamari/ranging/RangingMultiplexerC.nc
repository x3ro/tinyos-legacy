configuration RangingMultiplexerC
{
  provides interface RangingTransmitter;
  provides interface RangingReceiver;
  provides interface StdControl;
}
implementation
{
  components
    RangingMultiplexerM,
    //mica2   TransmitterC as UltrasoundRangingTransmitterC,
    //mica2   ReceiverC as UltrasoundRangingReceiverC,
    RSSIRangingTransmitterC,
    RSSIRangingReceiverC;

  //mica2  StdControl = UltrasoundRangingTransmitterC;
  //mica2  StdControl = UltrasoundRangingReceiverC;
    StdControl = RSSIRangingTransmitterC;
  StdControl = RSSIRangingReceiverC;
  
  //mica2  RangingMultiplexerM.UltrasoundRangingTransmitter -> TransmitterC;
  //mica2  RangingMultiplexerM.UltrasoundRangingReceiver -> ReceiverC;
  RangingMultiplexerM.RSSIRangingTransmitter -> RSSIRangingTransmitterC;
  RangingMultiplexerM.RSSIRangingReceiver -> RSSIRangingReceiverC;
  RangingMultiplexerM.RangingTransmitter = RangingTransmitter;
  RangingMultiplexerM.RangingReceiver = RangingReceiver;
  
}
