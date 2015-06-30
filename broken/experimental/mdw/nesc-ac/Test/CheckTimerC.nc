configuration CheckTimerC {
  // Nothing
} implementation {

  //components Main, AbstractTimerM(), AbstractTimerM() as ATM2, ClockC, TimerClient;
  components Main, AbstractTimerC(4), AbstractTimerC(10) as ATC2, TimerClient, OtherTimerClient;
  //components Main, TimerC, TimerClient;

  //Main.StdControl -> AbstractTimerM;
  //Main.StdControl -> ATM2;
  Main.StdControl -> AbstractTimerC;
  Main.StdControl -> ATC2;
  //Main.StdControl -> TimerC;
  Main.StdControl -> TimerClient;
  Main.StdControl -> OtherTimerClient;

  //TimerClient.Timer -> AbstractTimerM;
  //TimerClient.Timer -> ATM2;
  TimerClient.Timer -> AbstractTimerC;
  OtherTimerClient.Timer -> ATC2;
  //TimerClient.Timer -> TimerC.Timer[unique("Timer")];

  //AbstractTimerM.Clock -> ClockC;
  //ATM2.Clock -> ClockC;

}
