includes ERBcast;

configuration SpanTreeC {
  provides interface ERoute;
  provides interface StdControl;  
}
implementation {
  components SpanTreeM, ERBcast, RoutingC, SpanTreeReinitCmdC, SpanTreeStatusCmdC,
    LedsC, NoLeds;

  StdControl = SpanTreeM.StdControl;
  StdControl = ERBcast.StdControl;
  
  SpanTreeM.BcastRecv -> ERBcast.Receive[ERBCAST_AMHANDLER];
  SpanTreeM.BcastSend -> RoutingC.RoutingSendBySingleBroadcast[ERBCAST_AMHANDLER];

  SpanTreeM.RouteSend -> RoutingC.RoutingSendByAddress[ROUTE_AMHANDLER];
  SpanTreeM.RouteRecv -> RoutingC.RoutingReceive[ROUTE_AMHANDLER];

  SpanTreeM.SpanTreeReinitCmd -> SpanTreeReinitCmdC;
  SpanTreeM.SpanTreeStatusCmd -> SpanTreeStatusCmdC;
  
  SpanTreeM.Leds -> LedsC;
  // SpanTreeM.Leds -> NoLeds;

  ERBcast.RoutingReceive[ERBCAST_AMHANDLER] -> RoutingC.RoutingReceive[ERBCAST_AMHANDLER];
  
  ERBcast -> SpanTreeM.epochExpired;
  ERoute = SpanTreeM;
}
