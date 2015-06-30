includes Localization;
includes LocalizationConfig;
includes SpanTree;
includes ERBcast;

includes MagCenter;
includes Routing;
includes Neighborhood;
includes Config;

configuration TableSensorC
{
}
implementation
{
  components Main
           , SystemC

	   // TableSensor
           , MagHoodC
	   , MagCenterC //just include so the perl scripts grab it
	   , MagReadingC
	   , MagPositionC

	   // RouteTest2
	   , RouteTestC
	   , SpanTreeC
	   , SystemGenericCommC as Comm

	   , SnoopPositionEstimate
	   , PursuerServiceC
	  
	   ;

  Main.StdControl -> SystemC;

  SystemC.Init[10] -> MagPositionC;
  SystemC.Init[11] -> MagHoodC;
  SystemC.Service[10] -> MagReadingC;

  SystemC.Init[30] -> RouteTestC;
  SystemC.Init[31] -> SpanTreeC;

  SystemC.Service[66] -> SnoopPositionEstimate;
  SystemC.Service[66] -> PursuerServiceC;
}

