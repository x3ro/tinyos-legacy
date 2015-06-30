configuration TestEpochSchedulerC
{
}

implementation {
  components UsefulTimeC;

  components Main, 
    TestEpochSchedulerM, TimerC, LedsC;

  components EpochSchedulerC;

  Main.StdControl -> TestEpochSchedulerM.StdControl;
  Main.StdControl -> TimerC;

  TestEpochSchedulerM.Leds -> LedsC;
  TestEpochSchedulerM.Timer -> TimerC.Timer[unique("Timer")];

  Main.StdControl -> EpochSchedulerC.ESControl;

  TestEpochSchedulerM.Time -> UsefulTimeC;

  TestEpochSchedulerM.EpochScheduler1 -> 
    EpochSchedulerC.EpochScheduler[unique("EpochScheduler")];
  TestEpochSchedulerM.EpochScheduler2 -> 
    EpochSchedulerC.EpochScheduler[unique("EpochScheduler")];

#ifdef TIME_SYNC
  components TimeSyncM;

  
#endif
}
