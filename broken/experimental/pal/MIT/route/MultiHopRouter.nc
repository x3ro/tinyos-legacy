includes MultiHop;

configuration MultiHopRouter {
  
  provides {
    interface StdControl;
    // The interface are as parameterised by the active message id
	// only the 10 active message ids defined MultiHop.h are supported.
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface Send[uint8_t id];
    interface RouteControl;
    interface RouteQuery;
  }

}

implementation {
  
  // Uncomment for use with mh6
  components WMEWMAMultiHopRouter;

  StdControl = WMEWMAMultiHopRouter;
  Receive = WMEWMAMultiHopRouter;
  Send = WMEWMAMultiHopRouter;
  Intercept = WMEWMAMultiHopRouter.Intercept;
  Snoop = WMEWMAMultiHopRouter.Snoop;
  RouteControl = WMEWMAMultiHopRouter;
  RouteQuery = WMEWMAMultiHopRouter;
  Receive = WMEWMAMultiHopRouter;

}
