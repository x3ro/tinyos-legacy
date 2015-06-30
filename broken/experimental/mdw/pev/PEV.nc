configuration PEV {
} implementation {

  components Main, PEVM, AbstractTimerC(), LedsC, Photo;

  Main.StdControl -> PEVM.StdControl;

  PEVM.SendToRoot -> Multihop.Send;
  PEVM.Leds -> LedsC;
  PEVM.ADC -> Photo;
  PEVM.Timer -> AbstractTimerC;

}
