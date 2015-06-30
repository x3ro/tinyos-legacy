configuration OPmwritedg {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.WriteDiscardGlobal;
}
