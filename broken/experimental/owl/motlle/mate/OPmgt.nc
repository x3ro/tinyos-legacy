configuration OPmgt {
  provides interface MateBytecode;
}
implementation {
  components MOPrel;

  MateBytecode = MOPrel.Rel;
}
