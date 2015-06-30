configuration ShortestPath {
  provides {
    interface RouteHeader;
    interface RouteState;
  }
  uses {
    interface CommNotifier;
  }
}

implementation {
  components ShortestPathM, Main, RouteHelper, RandomLFSR, TimerWrapper, LedsC, VirtualComm;
  Main.StdControl -> ShortestPathM.StdControl;
  RouteHeader = ShortestPathM.RouteHeader;
  CommNotifier = ShortestPathM.CommNotifier;
  RouteState = ShortestPathM.RouteState;
  ShortestPathM.RouteHelp -> RouteHelper.RouteHelp;
  ShortestPathM.Timer -> TimerWrapper.Timer[unique("Timer")];
  ShortestPathM.OffsetTimer -> TimerWrapper.Timer[unique("Timer")];
  ShortestPathM.Random -> RandomLFSR.Random;
  ShortestPathM.Leds -> LedsC.Leds;

}
