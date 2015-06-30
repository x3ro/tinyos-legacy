
configuration SystemGenericCommC
{
  provides interface StdControl;
  provides interface SendMsg[ uint8_t am ];
  provides interface ReceiveMsg[ uint8_t am ];
  provides interface RadioSending;
}
implementation
{
  components SystemGenericCommM
	   , RSSIGenericCommC
           , GenericComm
	   ;

  StdControl = RSSIGenericCommC;
  SendMsg = RSSIGenericCommC;
  ReceiveMsg = RSSIGenericCommC;
  RadioSending = SystemGenericCommM;

  RSSIGenericCommC.BottomStdControl -> SystemGenericCommM;
  RSSIGenericCommC.BottomSendMsg -> SystemGenericCommM;
  RSSIGenericCommC.BottomReceiveMsg -> SystemGenericCommM;

  SystemGenericCommM.BottomStdControl -> GenericComm;
  SystemGenericCommM.BottomSendMsg -> GenericComm;
  SystemGenericCommM.BottomReceiveMsg -> GenericComm;
}

