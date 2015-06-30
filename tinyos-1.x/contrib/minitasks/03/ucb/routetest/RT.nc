
configuration RT {
}
implementation {
  components Main, RTM, TimerC, SpanTreeC;

  Main.StdControl -> RTM;
  Main.StdControl -> TimerC;
  Main.StdControl -> SpanTreeC;  

  RTM.Timer -> TimerC.Timer[unique("Timer")];
  RTM.TreeRoute -> SpanTreeC;
}
