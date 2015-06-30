
includes DefineCC1000;

configuration LowPowerStateC
{
  provides interface StdControl;
}
implementation
{
  components LowPowerStateM
#if defined(RADIO_CC1000)
           , OnOffC
#endif
	   , TimerC
	   , LedsC
	   ;

  StdControl = LowPowerStateM;
#if defined(RADIO_CC1000)
  LowPowerStateM.OnOff -> OnOffC.OnOff;
#endif
  LowPowerStateM.Timer -> TimerC.Timer[unique("Timer")];
  LowPowerStateM.Leds -> LedsC;
}

