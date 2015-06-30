
includes MagCenter;

configuration PursuerServiceC
{
  provides interface StdControl;
}
implementation
{
  components PursuerServiceM
           , RoutingC
	   , TickSensorC
	   , MsgBuffersC
	   ;

  StdControl = PursuerServiceM;

  PursuerServiceM.MagLeaderToPursuer ->
    RoutingC.RoutingReceive[ PROTOCOL_MAG_LEADER_TO_PURSUER ];

  PursuerServiceM.PursuerToMagLeader ->
    RoutingC.RoutingSendByAddress[ PROTOCOL_PURSUER_TO_MAG_LEADER ];

  PursuerServiceM.TickSensor -> TickSensorC;
  PursuerServiceM.MsgBuffers -> MsgBuffersC;
}

