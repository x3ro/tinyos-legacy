
configuration PollC
{
  provides interface Poll;
}
implementation
{
  components Main, PollM, TimerC;
  Main.StdControl -> PollM.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Poll = PollM;
  PollM.Timer -> TimerC.Timer[unique("Timer")];
}

