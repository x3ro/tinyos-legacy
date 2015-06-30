configuration OPmreadl3 {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.ReadLocal3;
}
