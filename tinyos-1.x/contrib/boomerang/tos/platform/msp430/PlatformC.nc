/**
 * Responsible for initializing the platform on boot.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration PlatformC {
  provides interface Init;
  uses interface Init as ArbiterInits;
}
implementation {
  components Main;
  components PlatformP;
  components HPLInitC;
  components MSP430DCOCalibC; //periodic recalibration of the DCO

  Init = PlatformP;
  ArbiterInits = PlatformP;

  PlatformP.hplInit -> HPLInitC;
}

