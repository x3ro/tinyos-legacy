includes Mate;

configuration OPstamp {
  provides interface MateBytecode;
  provides interface MateBytecodeLock;
}

implementation {
  components InternalFlashC;
  components DataCacheM, MStacksProxy, MTypesProxy, MErrorProxy, MLocksProxy;
  components MBufferProxy;
  components TimeSyncC;
  components MateEngine as VM;
  //components TimerC;

  MateBytecodeLock = DataCacheM;
  MateBytecode = DataCacheM.Stamp;
  DataCacheM.IFlash -> InternalFlashC;
  //VM.SubControl -> DataCacheM.StdControl;
  DataCacheM.Stacks -> MStacksProxy;
  DataCacheM.Buffer -> MBufferProxy;
  DataCacheM.TypeCheck -> MTypesProxy;
  DataCacheM.Error -> MErrorProxy;

  DataCacheM.Locks -> MLocksProxy;
  DataCacheM.EngineStatus -> VM;
  DataCacheM.GlobalTime -> TimeSyncC;
  //DataCacheM.LocalTime -> TimerC;
}
