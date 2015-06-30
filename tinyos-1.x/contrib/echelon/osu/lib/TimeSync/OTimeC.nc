includes OTime;

configuration OTimeC {
  provides interface OTime;
  provides interface StdControl;
  }

implementation
{
  components AlarmC, SysTimeC, OTimeM, LedsC;

  StdControl = OTimeM;
  OTime = OTimeM;
  OTimeM.Alarm -> AlarmC.Alarm[unique("Alarm")];
  OTimeM.SysTime -> SysTimeC.SysTime;
  OTimeM.Leds -> LedsC;
}

