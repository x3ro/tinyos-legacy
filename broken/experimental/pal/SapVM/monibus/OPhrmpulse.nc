//$Id: OPhrmpulse.nc,v 1.3 2005/06/22 09:22:34 neturner Exp $

/**
 * @author Neil E. Turner
 */

includes Mate;

configuration OPhrmpulse {
  provides interface MateBytecode;
}

implementation {
  components LedsC
    , MStacksProxy
    , MonibusC
    , OPhrmpulseM
    ;
    
  MateBytecode = OPhrmpulseM;

  OPhrmpulseM.Leds -> LedsC;
  OPhrmpulseM.MateBytecodePassThru -> MonibusC;
  OPhrmpulseM.Stacks -> MStacksProxy;
}
