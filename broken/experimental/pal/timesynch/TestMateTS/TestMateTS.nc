includes TimeTest;

configuration TestMateTS {

}
implementation {
  components Main, TimerC, SynchTimerContextM, LedsC;
#ifdef PLATFORM_PC
  components SimTime as Time;
#else
  components GenericComm, TimeSyncC as Time;
#endif
  
  Main.StdControl -> TimerC;
  Main.StdControl -> SynchTimerContextM;
  Main.StdControl -> Time;
  SynchTimerContextM.SubControlTimer -> TimerC;
  SynchTimerContextM.GlobalTime -> Time;
  SynchTimerContextM.ClockTimer -> TimerC.Timer[unique("Timer")];
  SynchTimerContextM.Leds -> LedsC;

#ifndef PLATFORM_PC
  Main.StdControl -> GenericComm;
  SynchTimerContextM.Send -> GenericComm.SendMsg[AM_TIMETESTMSG];
#endif
}
