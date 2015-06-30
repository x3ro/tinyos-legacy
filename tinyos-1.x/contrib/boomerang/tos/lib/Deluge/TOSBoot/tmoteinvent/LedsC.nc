configuration LedsC {
  provides interface StdControl;
  provides interface Leds;
}
implementation {
  components HPLUSART0M, LedsM;

  StdControl = LedsM;
  Leds = LedsM;
  LedsM.HPLUSARTControl -> HPLUSART0M;
}
