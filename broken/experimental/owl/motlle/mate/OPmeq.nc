configuration OPmeq {
  provides interface MateBytecode;
}
implementation {
  components MOPeqM, MProxy;

  MateBytecode = MOPeqM;
  MOPeqM.S -> MProxy;
  MOPeqM.T -> MProxy;
}
