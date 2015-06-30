//$Id: OPmonib.nc,v 1.9 2005/06/22 09:22:34 neturner Exp $

/**
 * @author Neil E. Turner
 */

includes Mate;

configuration OPmonib {
  provides interface MateBytecode;
}

implementation {
  components LedsC
    , MStacksProxy
    , MonibusC
    , OPmonibusM
    ;

  MateBytecode = OPmonibusM;

  OPmonibusM.Leds -> LedsC;
  OPmonibusM.MateBytecodePassThru -> MonibusC;
  OPmonibusM.Stacks -> MStacksProxy;
}
