/*<routing>

Top:

TOSAM 101:
  provides interface RoutingSendByBroadcast;
  BerkeleyBroadcastRoutingM;

Bottom:
  //TagSourceAddressRoutingM;  // for debugging
  LocalLoopbackRoutingM;
  ReliablePriorityRoutingSendM;
  IgnoreDuplicateRoutingM;
  IgnoreNonlocalRoutingM;  // it's significant that Nonlocal is below Duplicate

</routing>*/


includes Routing;

configuration RoutingC
{
}
implementation
{
  components LedsC
           , NoLeds
	   ;

  ReliablePriorityRoutingSendM -> NoLeds.Leds;
  TinyOSRoutingM -> NoLeds.Leds;
}

