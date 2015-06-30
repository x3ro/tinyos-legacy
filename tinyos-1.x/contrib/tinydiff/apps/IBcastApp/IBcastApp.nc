includes ibcast;

configuration IBcastApp
{
}
implementation
{
  components Main, IBcastAppM, IBcast, TxManC,
	     TimerC, LedsC, GenericComm, OCEEPROM, RandomLFSR, SamplerC;

  Main.StdControl -> IBcastAppM.StdControl;

  IBcastAppM.IBcastReceiveMsg -> IBcast.IBcastReceiveMsg;
  IBcastAppM.IBcastEnqueue -> IBcast.IBcastEnqueue;
  IBcastAppM.IBcastControl -> IBcast.StdControl;

  IBcastAppM.SamplerControl -> SamplerC.SamplerControl;
  IBcastAppM.AnalogSampler -> SamplerC.BufferAnalog;
  IBcastAppM.WindGustSampler -> SamplerC.BufferWind;
  IBcastAppM.RainSwitchSampler -> SamplerC.BufferRain;

  IBcastAppM.Timer -> TimerC.Timer[unique("Timer")];

  IBcastAppM.Leds -> LedsC.Leds;
  IBcastAppM.TxManControl -> TxManC.TxManControl;
  IBcastAppM.TxManStdControl -> TxManC.Control;
  IBcastAppM.OCEEPROMControl -> OCEEPROM.StdControl;
  IBcastAppM.CommControl -> GenericComm.Control;

  IBcastAppM.Random -> RandomLFSR.Random;

  TxManC.CommSendMsg -> GenericComm.SendMsg;

  //LedsRC.ReceiveMsg -> GenericComm.ReceiveMsg[LEDSRC_TYPE];
  //LedsRC.Enqueue -> TxManC.Enqueue;
}
