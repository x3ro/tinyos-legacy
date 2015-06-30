configuration OPmexec4 {
  provides interface MateBytecode;
}
implementation {
  components MOPcall;

  MateBytecode = MOPcall.Exec;
}
