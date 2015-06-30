/*<routing>
Top:
Bottom:
</routing>*/

/*

Top:

TOSAM 100:
  provides interface RoutingSendByAddress;
  BerkeleyAddressRoutingM;

TOSAM 101:
  provides interface RoutingSendByBroadcast;
  BerkeleyBroadcastRoutingM;

Bottom:
  LocalLoopbackRoutingM;
  ReliablePriorityRoutingSendM;
  IgnoreDuplicateRoutingM;
  IgnoreNonlocalRoutingM;

</routing>*/


includes Routing;

configuration RoutingC
{
}
implementation
{
  //components LedsC, NoLeds;
  //ReliablePriorityRoutingSendM -> NoLeds.Leds;
  //BerkeleyAddressRoutingM -> NoLeds.Leds;
  //TinyOSRoutingM -> NoLeds.Leds;
}

