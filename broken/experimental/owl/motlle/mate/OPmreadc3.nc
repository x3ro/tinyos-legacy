configuration OPmreadc3 {
  provides interface MateBytecode;
}
implementation {
  components MOPvar;

  MateBytecode = MOPvar.ReadClosure3;
}
