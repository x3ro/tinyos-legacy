configuration OPmwritel {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.WriteLocal;
}
