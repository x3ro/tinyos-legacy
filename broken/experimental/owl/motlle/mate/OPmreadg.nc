configuration OPmreadg {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.ReadGlobal;
}
