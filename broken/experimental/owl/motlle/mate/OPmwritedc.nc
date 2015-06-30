configuration OPmwritedc {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.WriteDiscardClosure;
}
