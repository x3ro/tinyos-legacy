abstract configuration AbstractTimerC(int foo) {
  provides interface StdControl;
  provides interface Timer;
} implementation {

  components AbstractTimerM(foo), AbstractTimerM(38+1) as BackupTimer, ClockC;

  AbstractTimerM.Clock -> ClockC;
  BackupTimer.Clock -> ClockC;

  StdControl = AbstractTimerM;
  StdControl = BackupTimer;
  Timer = AbstractTimerM;
  Timer = BackupTimer;
}
