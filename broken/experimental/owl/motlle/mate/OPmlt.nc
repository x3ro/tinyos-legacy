configuration OPmlt {
  provides interface MateBytecode;
}
implementation {
  components MOPrel;

  MateBytecode = MOPrel.Rel;
}
