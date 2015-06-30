includes Config;
includes Routing;

configuration testMagC
{
}
implementation
{
  components Main, testMagM, TimerM, HDMagMagC as MagC;
  components ConfigC, RoutingC;

  Main.StdControl -> testMagM.StdControl;

  testMagM.TimerControl -> TimerM.StdControl;
  testMagM.MagControl -> MagC.StdControl;
  testMagM.MagSensor -> MagC;
  testMagM.Timer -> TimerM.Timer[unique("Timer")];
}

