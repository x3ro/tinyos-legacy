configuration OPmnegate {
  provides interface MateBytecode;
}
implementation {
  components MOParith;

  MateBytecode = MOParith.Unary;
}
