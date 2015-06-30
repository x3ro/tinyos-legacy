
includes RSSIGenericComm;

configuration RSSIGenericCommC
{
  provides interface StdControl;
  provides interface SendMsg[ uint8_t am ];
  provides interface ReceiveMsg[ uint8_t am ];
  uses interface StdControl as BottomStdControl;
  uses interface SendMsg as BottomSendMsg[ uint8_t am ];
  uses interface ReceiveMsg as BottomReceiveMsg[ uint8_t am ];
}
implementation
{
  components RSSIGenericCommM
#if defined(RSSIGENERICCOMM_CC1000)
           , CC1000RadioIntM
#endif
	   , ADCC
	   ;

  StdControl = RSSIGenericCommM;
  SendMsg = RSSIGenericCommM;
  ReceiveMsg = RSSIGenericCommM;

  BottomStdControl = RSSIGenericCommM;
  BottomSendMsg = RSSIGenericCommM;
  BottomReceiveMsg = RSSIGenericCommM;

#if defined(RSSIGENERICCOMM_CC1000)
  RSSIGenericCommM.RadioCoordinator -> CC1000RadioIntM.RadioReceiveCoordinator;
  RSSIGenericCommM.ADC -> ADCC.ADC[0];
#endif
}

