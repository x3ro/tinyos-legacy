configuration FNbasic {
  provides {
    interface MateBytecode as FunctionP;
    interface MateBytecode as Apply;
    interface MateBytecode as Error;
    interface MateBytecode as GarbageCollect;
  }
}
implementation {
  components FNbasicM, MProxy, MOPcall;

  FunctionP = FNbasicM.FunctionP;
  Apply = FNbasicM.Apply;
  Error = FNbasicM.Error;
  GarbageCollect = FNbasicM.GarbageCollect;

  FNbasicM.S -> MProxy;
  FNbasicM.T -> MProxy;
  FNbasicM.E -> MProxy;
  FNbasicM.V -> MProxy;
  FNbasicM.GC -> MProxy;
  FNbasicM.Exec -> MOPcall.Exec;
}
