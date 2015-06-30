configuration OPmreadl {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.ReadLocal;
}
