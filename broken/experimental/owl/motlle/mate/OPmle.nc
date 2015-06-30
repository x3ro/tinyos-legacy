configuration OPmle {
  provides interface MateBytecode;
}
implementation {
  components MOPrel;

  MateBytecode = MOPrel.Rel;
}
