configuration TestTimer {
} implementation {
  components Main, TestTimerM,
    AbstractTimerC() as Timer1, AbstractTimerC() as Timer2;

  Main.StdControl -> TestTimerM;
  Main.StdControl -> Timer1;
  Main.StdControl -> Timer2;

  TestTimerM.Timer -> Timer1;
  TestTimerM.Timer -> Timer2;

}
