includes TimeSync;

configuration TimeSyncC {
  uses {
    interface TimeSyncAuthority;

    interface PiggyBack as TimeSyncPiggy;
  }
  provides {
    interface StdControl;
    interface TimeSync;
    interface SourceAddress;
  }
}
implementation {
  components TimeSyncM, TimerC, 
    GenericCommPromiscuous as Comm, 
    UsefulTimeC,
    PowerArbiterC,
    RandomLFSR, 
    LedsC,
    EpochSchedulerC;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  components CC1000RadioIntM;

  TimeSyncM.RadioSendCoordinator -> CC1000RadioIntM.RadioSendCoordinator;
  TimeSyncM.RadioReceiveCoordinator -> CC1000RadioIntM.RadioReceiveCoordinator;
#endif

  StdControl = TimeSyncM.StdControl;
  StdControl = TimerC.StdControl;
  StdControl = EpochSchedulerC.ESControl;
  StdControl = Comm.Control;

  TimeSyncM.SendMsg -> Comm.SendMsg[TIME_SYNC_AM];
  TimeSyncM.ReceiveMsg -> Comm.ReceiveMsg[TIME_SYNC_AM];

  TimeSyncM.TransmitTimer -> TimerC.Timer[unique("Timer")];
 
  TimeSyncM.Time -> UsefulTimeC.Time;
  TimeSyncM.TimeSet -> UsefulTimeC.TimeSet;
  TimeSyncM.TimeSetListener -> UsefulTimeC.TimeSetListener;

  TimeSyncM.TinyTimeInterval -> UsefulTimeC.TinyTimeInterval;

  TimeSyncM.TimeSyncPiggy = TimeSyncPiggy;

  TimeSyncM.TimeSyncAuth = TimeSyncAuthority;
  TimeSyncM.TimeSyncEpoch -> 
    EpochSchedulerC.EpochScheduler[unique("EpochScheduler")];

  TimeSyncM.Random -> RandomLFSR;

  TimeSyncM.Leds -> LedsC;

  TimeSyncM.PowerArbiter -> 
    PowerArbiterC.PowerArbiter[unique("PowerArbiter")];

  TimeSync = TimeSyncM;
  SourceAddress = TimeSyncM;
}
