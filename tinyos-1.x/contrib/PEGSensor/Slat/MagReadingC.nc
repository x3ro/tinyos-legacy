
configuration MagReadingC
{
  provides interface StdControl;
}
implementation
{
  components MagReadingM
           , TimerC
#if defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
	   , HDMagMagC as MagC
#else
	   , MagC
#endif
	   ;

  StdControl = MagReadingM;

  MagReadingM.Timer -> TimerC.Timer[unique("Timer")];

  MagReadingM.MagSensor -> MagC;
  MagReadingM.MagAxesSpecific -> MagC;
  MagReadingM.MagSensorControl -> MagC;
}

