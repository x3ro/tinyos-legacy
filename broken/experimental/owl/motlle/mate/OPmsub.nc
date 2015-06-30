configuration OPmsub {
  provides interface MateBytecode;
}
implementation {
  components MOParith;

  MateBytecode = MOParith.Arith;
}
