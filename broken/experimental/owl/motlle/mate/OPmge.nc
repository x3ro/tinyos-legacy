configuration OPmge {
  provides interface MateBytecode;
}
implementation {
  components MOPrel;

  MateBytecode = MOPrel.Rel;
}
