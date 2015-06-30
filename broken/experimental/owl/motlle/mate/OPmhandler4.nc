configuration OPmhandler4 {
  provides interface MateBytecode;
  provides interface MateBytecodeLock;
}
implementation {
  components MOPhandlerM, MOPcall, MProxy;

  MateBytecode = MOPhandlerM.ExecHandler;
  MateBytecodeLock = MOPhandlerM.ExecHandlerLocks;

  MOPhandlerM.Exec -> MOPcall.Exec;
  MOPhandlerM.G -> MProxy;
  MOPhandlerM.GC -> MProxy;
  MOPhandlerM.S -> MProxy;
  MOPhandlerM.T -> MProxy;
}
