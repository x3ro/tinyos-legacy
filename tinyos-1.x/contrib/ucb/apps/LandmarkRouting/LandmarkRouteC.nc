includes ERBcast;

configuration LandmarkRouteC {
  provides interface LRoute;
  provides interface LandmarkRoute;
  provides interface StdControl;
}
implementation {
  components LandmarkRouteM, ERBcast, RoutingC, LedsC, NoLeds, TimerC, RandomLFSR;


  LandmarkRouteM.BcastRecv -> ERBcast.Receive[ERBCAST_AMHANDLER];
  LandmarkRouteM.BcastSend -> RoutingC.RoutingSendBySingleBroadcast[ERBCAST_AMHANDLER];

  LandmarkRouteM.RouteSend -> RoutingC.RoutingSendByAddress[ROUTE_AMHANDLER];
  LandmarkRouteM.RouteRecv -> RoutingC.RoutingReceive[ROUTE_AMHANDLER];
  LandmarkRouteM.Random -> RandomLFSR;

  LandmarkRouteM.Leds -> LedsC;
  //LandmarkRouteM.Leds -> NoLeds;
  LandmarkRouteM.TimerTree -> TimerC.Timer[unique("Timer")];
  LandmarkRouteM.ResendTimer -> TimerC.Timer[unique("Timer")];

  LRoute = LandmarkRouteM;
  LandmarkRoute = LandmarkRouteM;
  StdControl = LandmarkRouteM;
  StdControl = RoutingC;

  ERBcast.RoutingReceive[ERBCAST_AMHANDLER] -> RoutingC.RoutingReceive[ERBCAST_AMHANDLER];
  
  ERBcast -> LandmarkRouteM.epochExpired;
}
