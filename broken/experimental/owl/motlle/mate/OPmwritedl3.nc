configuration OPmwritedl3 {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.WriteDiscardLocal3;
}
