configuration OPmclearl {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.ClearLocal;
}
