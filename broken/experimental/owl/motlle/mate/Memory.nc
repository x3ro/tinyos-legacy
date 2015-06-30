configuration Memory
{
  provides {
    interface StdControl;
    interface MateHandlerStore as HandlerStore[uint8_t id];
    interface MotlleGC as GC;
    interface MotlleGlobals as G;
    interface MotlleStack as S;
  }
  uses interface MotlleFrame[uint8_t kind];
}
implementation {
  components MemoryM, MProxy, MContextSynchProxy, MVirusProxy, MateEngine;
  components HPLPowerManagementM;

  StdControl = MemoryM;
  HandlerStore = MemoryM;
  GC = MemoryM;
  G = MemoryM;
  S = MemoryM;
  MotlleFrame = MemoryM;

  MemoryM.V -> MProxy;
  MemoryM.T -> MProxy;
  MemoryM.E -> MProxy;

  MemoryM.Virus -> MVirusProxy;
  MemoryM.EngineControl <- MateEngine.EngineControl;

  MemoryM.PowerMgmtEnable -> HPLPowerManagementM.Enable;
}
