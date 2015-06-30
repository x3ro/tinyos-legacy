configuration TestTimeSyncC {

}
implementation {
  components Main, TimeSyncC, 
    WMEWMAMultiHopRouter as MHSnoopRtr,
    TestTimeSyncM, UsefulTimeC,
    EpochSchedulerC, LedsC;

  Main.StdControl -> EpochSchedulerC.ESControl;
  Main.StdControl -> TimeSyncC;
  Main.StdControl -> MHSnoopRtr;
  Main.StdControl -> TestTimeSyncM;

  TimeSyncC.TimeSyncAuthority -> TestTimeSyncM.TimeSyncAuthority;    

  TestTimeSyncM.RouteControl ->  MHSnoopRtr.RouteControl;
  TestTimeSyncM.TimeSync -> TimeSyncC;
  TestTimeSyncM.TimeSetListener -> UsefulTimeC.TimeSetListener;
  TestTimeSyncM.Time -> UsefulTimeC.Time;

  TestTimeSyncM.Leds -> LedsC;

  TestTimeSyncM.Epoch ->
    EpochSchedulerC.EpochScheduler[unique("EpochScheduler")];
}
