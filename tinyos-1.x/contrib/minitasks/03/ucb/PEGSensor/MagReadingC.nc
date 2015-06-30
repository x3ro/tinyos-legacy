
configuration MagReadingC
{
  provides interface StdControl;
}
implementation
{
  components MagReadingM
           , TimerC
           , TickSensorC
#if defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
	   , HDMagMagC as MagC
#else
	   , MagC
#endif
	   , MagDataAttrM
	   , SystemGenericCommC
	   ;

  StdControl = MagReadingM;

  MagReadingM.Timer -> TimerC.Timer[unique("Timer")];
  MagReadingM.TickSensor -> TickSensorC;

  MagReadingM.U16Sensor -> MagC;
  MagReadingM.MagAxesSpecific -> MagC;
  MagReadingM.MagSensorControl -> MagC;
  MagReadingM.MagSensorValid -> MagC;

  MagReadingM.MagReadingAttr -> MagDataAttrM;
  MagReadingM.MagReadingValid -> MagDataAttrM.ReadingValid;

  MagReadingM.RadioQuellTimer -> TimerC.Timer[unique("Timer")];
  MagReadingM.RadioSending -> SystemGenericCommC;
}

