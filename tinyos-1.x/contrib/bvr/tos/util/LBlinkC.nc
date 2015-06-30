configuration LBlinkC 
{
  provides interface LBlink;
  provides interface StdControl;
}

implementation {
  components LBlinkM
#ifdef LBLINK_ON
             , LedsC as Leds
#else
             , NoLeds as Leds
#endif
             , TimerC
             ;

  LBlink = LBlinkM;
  StdControl = LBlinkM;

  LBlinkM.Leds -> Leds;
  LBlinkM.Timer -> TimerC.Timer[unique("Timer")];
  LBlinkM.TimerControl -> TimerC.StdControl;
}
