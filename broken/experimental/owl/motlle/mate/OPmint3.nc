configuration OPmint3 {
  provides interface MateBytecode;
}
implementation {
  components MOPcst;

  MateBytecode = MOPcst.Int;
}
