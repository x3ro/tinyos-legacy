configuration OPmwritedl {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.WriteDiscardLocal;
}
