/*<routing>

Top:

TOSAM 100:
  provides interface RoutingSendByImplicit as RoutingSendBySingleBroadcast;
  BerkeleySingleBroadcastRoutingM;

TOSAM 101:
  provides interface RoutingSendByBroadcast;
  BerkeleyBroadcastRoutingM;

TOSAM 102:
  provides interface RoutingSendByAddress;
  BerkeleyAddressRoutingM;

Bottom:
  LocalLoopbackRoutingM;
  ReliablePriorityRoutingSendM;
  RSSILocalizationRoutingM;
  IgnoreDuplicateRoutingM;
  IgnoreNonlocalRoutingM;
  TagRoutingProtocolM;

</routing>*/


includes Routing;

configuration RoutingC
{
}
implementation
{
  components LedsC
           , NoLeds
	   , MsgBuffersC
	   , SystemGenericCommC as GenericComm
	   ;

  ReliablePriorityRoutingSendM -> NoLeds.Leds;

  BerkeleyBroadcastRoutingM -> MsgBuffersC.MsgBuffers;
  LocalLoopbackRoutingM -> MsgBuffersC.MsgBuffers;

  TinyOSRoutingM -> NoLeds.Leds;
}

