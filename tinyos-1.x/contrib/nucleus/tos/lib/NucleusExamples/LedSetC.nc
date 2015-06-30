//$Id: LedSetC.nc,v 1.1 2005/07/06 01:48:34 gtolle Exp $

configuration LedSetC {
}
implementation {
  components LedSetM, LedsC;
  LedSetM.Leds -> LedsC;
}
