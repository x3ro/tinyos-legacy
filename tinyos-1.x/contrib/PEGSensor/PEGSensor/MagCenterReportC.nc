
includes MagCenter;

configuration MagCenterReportC
{
  provides interface MagCenterReport;
}
implementation
{
  components MagCenterReportM
           , RoutingC
	   , MsgBuffersC
	   , SpanTreeCapsuleC
	   , MagDataAttrM
	   ;

  MagCenterReport = MagCenterReportM;

  MagCenterReportM.SendMagCenterBroadcast -> RoutingC.RoutingSendByBroadcast[ PROTOCOL_SENDMAG_CENTER_BROADCAST ];
  MagCenterReportM.SendMagCenterCroute -> SpanTreeCapsuleC.ERoute[ CAPSULE_SEND_MAGCENTER_CROUTE ];
  MagCenterReportM.MsgBuffers -> MsgBuffersC;
  MagCenterReportM.AlwaysInject -> RoutingC.RoutingReceive[ PROTOCOL_MAGCENTER_ALWAYS_INJECT ];
  MagCenterReportM.ClosestInject -> RoutingC.RoutingReceive[ PROTOCOL_MAGCENTER_CLOSEST_INJECT ];
  MagCenterReportM.MagPositionAttr -> MagDataAttrM;
  MagCenterReportM.MagPositionValid -> MagDataAttrM.PositionValid;
}

