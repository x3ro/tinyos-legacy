configuration OPmwritec {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.WriteClosure;
}
