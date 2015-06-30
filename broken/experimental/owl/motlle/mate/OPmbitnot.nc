configuration OPmbitnot {
  provides interface MateBytecode;
}
implementation {
  components MOParith;

  MateBytecode = MOParith.Unary;
}
