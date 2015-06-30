configuration Test 
{
}
implementation 
{
  components Main,TimerC,TimeUtilC,LedsC,GlobalAbsoluteTimerC,TestM;

  Main.StdControl -> GlobalAbsoluteTimerC.StdControl;  
  Main.StdControl -> TestM.StdControl;
  Main.StdControl -> TimerC;
  TestM.GlobalAbsoluteTimer -> GlobalAbsoluteTimerC.GlobalAbsoluteTimer[unique("AbsoluteTimer")];  
  TestM.TimeUtil -> TimeUtilC;
  TestM.Leds     -> LedsC;   
  TestM.Timer ->TimerC.Timer[unique("Timer")];
  
}

