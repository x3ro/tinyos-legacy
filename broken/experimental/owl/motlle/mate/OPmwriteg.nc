configuration OPmwriteg {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.WriteGlobal;
}
