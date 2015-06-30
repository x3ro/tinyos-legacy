configuration OPmref {
  provides interface MateBytecode;
}
implementation {
  components MOPidx;

  MateBytecode = MOPidx.Ref;
}
