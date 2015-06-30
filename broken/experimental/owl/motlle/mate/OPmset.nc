configuration OPmset {
  provides interface MateBytecode;
}
implementation {
  components MOPidx;

  MateBytecode = MOPidx.Set;
}
