/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	SoundToLed.nc
**
**	Purpose:	Set up wiring for SoundToLed.nc
**				For more information look at SoundToLedM.nc.
**				Tests microphone for presence of 4kHz tone.
**
**	Future:
**
*********************************************************/
configuration SoundToLed {
// this module does not provide any interface
}
implementation {
  components Main, SoundToLedM, TimerC, LedsC, MicC;

  Main.StdControl -> SoundToLedM.StdControl;
  Main.StdControl -> TimerC;
  SoundToLedM.Timer -> TimerC.Timer[unique("Timer")];
  SoundToLedM.Leds -> LedsC;
  SoundToLedM.MicControl -> MicC;
  SoundToLedM.Mic -> MicC;
  SoundToLedM.MicADC -> MicC;
  
}
