includes EpochScheduler;
includes AM;
configuration EpochSchedulerC {
  provides {
    interface EpochScheduler[uint8_t id];
    interface StdControl as ESControl;
  }

  uses {
    interface TimeSetListener;
  }
}

implementation {

  components UsefulTimeC, ServiceSchedulerM;
  components EpochSchedulerM, LedsC; 

  EpochSchedulerM.Leds -> LedsC;

  // Rewire the service scheduler with a better timing component
  EpochSchedulerM.Time -> UsefulTimeC.Time;
  ServiceSchedulerM.TimeUtil -> UsefulTimeC.TimeUtil;

  ServiceSchedulerM.Time -> UsefulTimeC.Time;
  ServiceSchedulerM.AbsoluteTimer -> 
    UsefulTimeC.AbsoluteTimer[unique("AbsoluteTimer")];

  EpochSchedulerM.ServiceScheduler -> ServiceSchedulerM.ServiceScheduler;
  ESControl = ServiceSchedulerM.SchedulerClt;

  ServiceSchedulerM.Services -> EpochSchedulerM.StdControl;

  ESControl = EpochSchedulerM.ESControl;
  EpochScheduler = EpochSchedulerM;
  TimeSetListener = EpochSchedulerM.TimeSetListener;

}
