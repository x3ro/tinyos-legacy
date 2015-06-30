configuration TestMMDetector {

}
implementation {
  components Main,
    TimeSyncC, 
    WMEWMAMultiHopRouter as Router,
    TestMMDetectorM,
    TimerC, 
    RollCallC;

  Main.StdControl -> TestMMDetectorM.StdControl;
  Main.StdControl -> TimeSyncC.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> Router;

  Main.StdControl -> RollCallC;

  TestMMDetectorM.RouteControl -> Router;
  // TestMMDetectorM.RouteControl -> TestMMDetectorM.DummyRC;

  TimeSyncC.TimeSyncPiggy -> TestMMDetectorM.PiggyBack;

  TestMMDetectorM.SourceAddress -> TimeSyncC.SourceAddress;
  //TestMMDetectorM.SourceAddress -> TestMMDetectorM.DummySA;

  RollCallC.RouteControl -> Router;
  //RollCallC.RouteControl -> TestMMDetectorM.DummyRC;
  RollCallC.HeartBeatHandler -> TestMMDetectorM.HeartBeatHandler;

  TimeSyncC.TimeSyncAuthority -> TestMMDetectorM.TimeSyncAuthority;

  TestMMDetectorM.Timer -> TimerC.Timer[unique("Timer")];

}
