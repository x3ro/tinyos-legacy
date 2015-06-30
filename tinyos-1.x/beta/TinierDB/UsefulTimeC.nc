configuration UsefulTimeC {
  provides {
    interface Time;
    interface TimeSet;
    interface TimeUtil;
    interface TimeSetListener;
    interface TinyTimeInterval;
    interface AbsoluteTimer[uint8_t id];
  }
} 
implementation {

  //#define DEBUG

#ifndef DEBUG
  components Main, UsefulTimeM, 
    SimpleTime, TimeUtilC, 
    TimerC, LedsC;

  Main.StdControl -> UsefulTimeM.StdControl;
  Main.StdControl -> TimerC;

  TimeUtil = TimeUtilC;

  UsefulTimeM.TimeSetExternal -> SimpleTime.TimeSet;
  UsefulTimeM.TimeUtil -> TimeUtilC;
  UsefulTimeM.Timer -> TimerC.Timer[unique("Timer")];
  UsefulTimeM.Leds -> LedsC;

  AbsoluteTimer = UsefulTimeM.AbsoluteTimer;
  Time = UsefulTimeM.Time;
  TimeSet = UsefulTimeM.TimeSet;
  TimeSetListener = UsefulTimeM.TimeSetListener;
  TinyTimeInterval = UsefulTimeM.TinyTimeInterval;

#else
  components Main,LogicalTime;

  Main.StdControl -> LogicalTime;

  AbsoluteTimer = LogicalTime;
  Time = LogicalTime;
  TimeSet = LogicalTime;
  TimeUtil = LogicalTime;
#endif

}
