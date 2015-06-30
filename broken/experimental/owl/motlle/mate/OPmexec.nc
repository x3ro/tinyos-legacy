configuration OPmexec {
  provides interface MateBytecode;
}
implementation {
  components MOPcall;

  MateBytecode -> MOPcall.Exec;
}
