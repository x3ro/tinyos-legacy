/**
 * 
 **/

configuration PLDIDemoOld {
}
implementation {
  components Main, PLDIDemoM, MultihopOld as Multihop, TimerC, LedsC, Photo;

  Main.StdControl -> PLDIDemoM.StdControl;
  Main.StdControl -> Photo;

  PLDIDemoM.ADC -> Photo;
  PLDIDemoM.Timer -> TimerC.Timer[unique("Timer")];
  PLDIDemoM.Leds -> LedsC; // NoLeds;
  PLDIDemoM.Send -> Multihop;
}

