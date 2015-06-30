//$Id: OPhrmvolt.nc,v 1.2 2005/06/22 09:22:34 neturner Exp $

/**
 * @author Neil E. Turner
 */

includes Mate;

configuration OPhrmvolt {
  provides interface MateBytecode;
}

implementation {
  components LedsC
    , MStacksProxy
    , MonibusC
    , OPhrmvoltM
    ;

  MateBytecode = OPhrmvoltM;

  OPhrmvoltM.Leds -> LedsC;
  OPhrmvoltM.MateBytecodePassThru -> MonibusC;
  OPhrmvoltM.Stacks -> MStacksProxy;
}
