/*<routing>

Top:

TOSAM 100:
  provides interface RoutingSendByAddress;
  BerkeleyAddressRoutingM;

TOSAM 101:
  provides interface RoutingSendByBroadcast;
  BerkeleyBroadcastRoutingM;

TOSAM 102:
  provides interface RoutingSendByLocation;
  BerkeleyLocationRouting2M;
  TagDestinationAddressRoutingM;  // for debugging
  TagSourceAddressRoutingM;  // for debugging

Bottom:
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
	   , NeighborhoodC
	   , LocalizationC
	   , TimedLedsC
	   ;

  StdControl = LocalizationC;

  ReliablePriorityRoutingSendM -> NoLeds.Leds;

  BerkeleyLocationRouting2M -> NeighborhoodC.TupleStore;
  BerkeleyLocationRouting2M -> NeighborhoodC.Neighbor_ucb_location_nak;
  BerkeleyLocationRouting2M -> NeighborhoodC.Neighbor_location;
  BerkeleyLocationRouting2M -> TimedLedsC.TimedLeds;
  BerkeleyAddressRoutingM -> NoLeds.Leds;

  TinyOSRoutingM -> NoLeds.Leds;
}

