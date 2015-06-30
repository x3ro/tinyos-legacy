configuration OPmexecg4 {
  provides interface MateBytecode;
}
implementation {
  components MOPcall;

  MateBytecode = MOPcall.ExecGlobal;
}
