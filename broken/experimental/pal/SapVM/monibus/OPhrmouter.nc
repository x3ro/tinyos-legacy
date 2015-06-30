//$Id: OPhrmouter.nc,v 1.2 2005/06/22 09:22:34 neturner Exp $

/**
 * @author Neil E. Turner
 */

includes Mate;

configuration OPhrmouter {
  provides interface MateBytecode;
}

implementation {
  components LedsC
    , MStacksProxy
    , MonibusC
    , OPhrmouterM
    ;

  MateBytecode = OPhrmouterM;

  OPhrmouterM.Leds -> LedsC;
  OPhrmouterM.MateBytecodePassThru -> MonibusC;
  OPhrmouterM.Stacks -> MStacksProxy;
}
