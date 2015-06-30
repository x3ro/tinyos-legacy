configuration WaveC
{
  provides interface Wave;
  provides interface StdControl;
}
implementation
{
  components WaveM, TimerC, LogicalTime, RandomLFSR, DiagMsgC;


  StdControl = WaveM.StdControl;
  StdControl = LogicalTime;
  Wave = WaveM.Wave;
  WaveM.Timer -> TimerC.Timer[unique("Timer")];
  WaveM.Random -> RandomLFSR.Random;
  WaveM.Time -> LogicalTime.Time;
  WaveM.DiagMsg -> DiagMsgC;
    
}
