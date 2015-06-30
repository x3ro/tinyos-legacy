#ifdef NDEBUG
module MotlleDebug { }
implementation {
  int x;
}
#else
configuration MotlleDebug { }
implementation {
  components DebugC;
  components MOParithM, MOPrelM, MemoryM, GenericComm;

  MOParithM.Debug -> DebugC;
  MOPrelM.Debug -> DebugC;
  MemoryM.Debug -> DebugC;

  DebugC.SendMsg -> GenericComm.SendMsg[22];
}
#endif
