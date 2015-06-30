configuration OPmscheck4 {
  provides interface MateBytecode;
}
implementation {
  components MOPtypecheck;

  MateBytecode = MOPtypecheck.StackCheck;
}

