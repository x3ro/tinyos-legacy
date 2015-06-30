/**
 * 
 **/

configuration PLDIDemo {
}
implementation {
  components Main, PLDIDemoM, Multihop, AbstractTimerC(), LedsC, Photo;

  Main.StdControl -> PLDIDemoM.StdControl;
  Main.StdControl -> Photo;

  PLDIDemoM.ADC -> Photo;
  PLDIDemoM.Timer -> AbstractTimerC;
  PLDIDemoM.Leds -> LedsC; 
  PLDIDemoM.Send -> Multihop;
}

