configuration OPmvcheck4 {
  provides interface MateBytecode;
}
implementation {
  components MOPtypecheck;

  MateBytecode = MOPtypecheck.VarCheck;
}

