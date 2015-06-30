/*<routing>

Top:

TOSAM 100:
  provides interface RoutingSendByAddress;
  BerkeleyAddressRoutingM;

TOSAM 101:
  provides interface RoutingSendByBroadcast;
  BerkeleyBroadcastRoutingM;

Bottom:
  ReliablePriorityRoutingSendM;
  IgnoreDuplicateRoutingM;
  IgnoreNonlocalRoutingM;

</routing>*/


includes Localization;
includes Routing;
includes Neighbor;

configuration RoutingC
{
}
implementation
{
  components LedsC, NoLeds;

  ReliablePriorityRoutingSendM -> NoLeds.Leds;
  TinyOSRoutingM -> NoLeds.Leds;
}

