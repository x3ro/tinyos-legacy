/* 
 * Traceroute Probing application
 */
includes AM;
includes PiggyBack;

configuration TraceRouteProbe
{
}

implementation
{
  components Main, TraceRouteProbeM, 
    TraceRouteM as TraceRoute,
    MultiHopRouter as Router,
    MultiHopFlood as Flood,
    GenericCommPromiscuous as Comm, TimerC, QueuedSend;
  
  Main.StdControl -> TraceRouteProbeM.StdControl;  
  
  TraceRouteProbeM.Timer -> TimerC.Timer[unique("Timer")];
  TraceRouteProbeM.RouteControl -> Router;
  TraceRouteProbeM.TraceRtCtl -> TraceRoute;

  TraceRouteProbeM.PiggyFlood -> TraceRoute.PiggyBack[AM_PIGGYMSG];
  TraceRouteProbeM.PiggyRoute -> TraceRoute.PiggyBack[AM_PIGGYMSGRT];

  TraceRoute.SubControl -> Flood.StdControl;
  TraceRoute.SubControl -> Router.StdControl;

//MultiHop routing algorithm
  TraceRoute.Send[AM_PIGGYMSGRT] -> Router.Send[AM_PIGGYMSGRT];
  TraceRoute.Receive[AM_PIGGYMSGRT] -> Router.Receive[AM_PIGGYMSGRT];
  TraceRoute.Intercept[AM_PIGGYMSGRT] -> Router.Intercept[AM_PIGGYMSGRT];

  Router.ReceiveMsg[AM_PIGGYMSGRT] -> Comm.ReceiveMsg[AM_PIGGYMSGRT];

//MultiFlood routing algorithm
  TraceRoute.Send[AM_PIGGYMSG] -> Flood.Send[AM_PIGGYMSG];
  TraceRoute.Receive[AM_PIGGYMSG] -> Flood.Receive[AM_PIGGYMSG];
  TraceRoute.Intercept[AM_PIGGYMSG] -> Flood.Intercept[AM_PIGGYMSG];
  
  Flood.ReceiveMsg[AM_PIGGYMSG] -> Comm.ReceiveMsg[AM_PIGGYMSG];
  Flood.SendMsg[AM_PIGGYMSG] -> QueuedSend.SendMsg[AM_PIGGYMSG];
}

//eof
