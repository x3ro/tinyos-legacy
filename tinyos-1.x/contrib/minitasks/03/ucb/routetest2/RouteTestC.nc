
includes rt2;

configuration RouteTestC
{
  provides interface StdControl;
}
implementation
{
  components RouteTestM
           , LedsC
	   , SpanTreeC
	   , RoutingC
	   , DataStore
	   ;

  StdControl = RouteTestM;
  StdControl = DataStore;

  RouteTestM.Leds -> LedsC;
  RouteTestM.ERoute -> SpanTreeC;
  RouteTestM.CmdRecv -> RoutingC.RoutingReceive[RT_CMD_MSG_HANDLER];
  RouteTestM.getRouteData -> DataStore.getRouteData;
  RouteTestM.EvaderDemoStore -> DataStore;
  
}

