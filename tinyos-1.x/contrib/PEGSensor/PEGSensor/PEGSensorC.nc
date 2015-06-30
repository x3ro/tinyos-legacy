includes Localization;
includes LocalizationConfig;
includes SpanTree;
includes ERBcast;

//includes LocalizationConfig;
includes MagCenter;
includes Routing;
includes Neighborhood;
includes Config;

//includes Omnisound;

configuration PEGSensorC
{
}
implementation
{
  components Main
           , SystemC

	   // PEGSensor
           , MagHoodC
	   , MagCenterC //just include so the perl scripts grab it
	   , MagReadingC
	   , MagPositionC

#if 0
	   // Ultrasonic Ranging
	   , TransmitterServiceC
	   , ReceiverC
	   , TransmitterAppM
#endif

	   // RouteTest2
	   , RouteTestC
	   , SpanTreeC
	   , SystemGenericCommC as Comm

    // Snooping base station support
	   , SnoopPositionEstimate
	   , PursuerServiceC
	   //, CalamariApp
	  
	   ;

  Main.StdControl -> SystemC;

  SystemC.Init[10] -> MagPositionC;
  SystemC.Init[11] -> MagHoodC;
  SystemC.Service[10] -> MagReadingC;

#if 0
  SystemC.Init[20] -> ReceiverC;
  SystemC.Service[20] -> TransmitterServiceC;
  TransmitterAppM.UltrasonicRangingReceiver -> ReceiverC;
  //TransmitterAppM.ReportRangingEst -> Comm.SendMsg[AM_TOF]; // Report over RF
#endif

  SystemC.Init[30] -> RouteTestC;
  SystemC.Init[31] -> SpanTreeC;

  //SystemC.Service[50] -> CalamariApp;

  SystemC.Service[66] -> SnoopPositionEstimate;
  SystemC.Service[66] -> PursuerServiceC;
}

