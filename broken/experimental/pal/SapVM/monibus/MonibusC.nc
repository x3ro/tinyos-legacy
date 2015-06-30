//$Id: MonibusC.nc,v 1.4 2005/07/07 08:57:02 neturner Exp $

/**
 * @author Neil E. Turner
 */

includes Mate;

configuration MonibusC {
  provides {
    interface MateBytecode;
  }
}

implementation {
  components
    LedsC,
    MContextSynchProxy,
    MQueueProxy,
    MStacksProxy,
    MTypesProxy,
    MateEngine,
    MonibusHPLUARTC,
    MonibusM,
    TimerC;

  MateBytecode = MonibusM;

  MonibusM.EngineStatus -> MateEngine;
  MonibusM.Leds -> LedsC;
  MonibusM.Monibus -> MonibusHPLUARTC;
  MonibusM.NoResponseTimeout -> TimerC.Timer[unique("Timer")];
  MonibusM.Queue -> MQueueProxy;
  MonibusM.ResponseTimeout -> TimerC.Timer[unique("Timer")];
  MonibusM.Stacks -> MStacksProxy;
  MonibusM.StdControl <- MateEngine.SubControl;
  MonibusM.Synch -> MContextSynchProxy;
  MonibusM.TypeCheck -> MTypesProxy;
}
