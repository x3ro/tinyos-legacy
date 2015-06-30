//$Id: OPhrminner.nc,v 1.2 2005/06/22 09:22:34 neturner Exp $

/**
 * @author Neil E. Turner
 */

includes Mate;

configuration OPhrminner {
  provides interface MateBytecode;
}

implementation {
  components LedsC
    , MStacksProxy
    , MonibusC
    , OPhrminnerM
    ;

  MateBytecode = OPhrminnerM;

  OPhrminnerM.Leds -> LedsC;
  OPhrminnerM.MateBytecodePassThru -> MonibusC;
  OPhrminnerM.Stacks -> MStacksProxy;
}
