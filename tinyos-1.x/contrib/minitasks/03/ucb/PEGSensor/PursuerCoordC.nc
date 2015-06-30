
includes MagCenter;

configuration PursuerCoordC
{
  provides interface MagCenterReport;
  provides interface StdControl;
}
implementation
{
  components PursuerCoordM
           , RoutingC
	   , SpanTreeC
	   , MagDataAttrM
	   , MsgBuffersC
	   ;

  MagCenterReport = PursuerCoordM;
  StdControl = PursuerCoordM;

  PursuerCoordM.MagLeaderToPursuer -> RoutingC.RoutingSendBySingleBroadcast[ PROTOCOL_MAG_LEADER_TO_PURSUER ];
  PursuerCoordM.PursuerToMagLeader -> RoutingC.RoutingReceive[ PROTOCOL_PURSUER_TO_MAG_LEADER ];
  PursuerCoordM.ERoute -> SpanTreeC;
  PursuerCoordM.MagPositionAttr -> MagDataAttrM;
  PursuerCoordM.MsgBuffers -> MsgBuffersC;
}

