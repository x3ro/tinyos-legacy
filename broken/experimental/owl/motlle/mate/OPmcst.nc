configuration OPmcst {
  provides interface MateBytecode;
}
implementation {
  components MOPcst;

  MateBytecode = MOPcst.Cst;
}
