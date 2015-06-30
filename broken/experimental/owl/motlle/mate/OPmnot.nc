configuration OPmnot {
  provides interface MateBytecode;
}
implementation {
  components MOPnotM, MProxy;

  MateBytecode = MOPnotM;
  MOPnotM.S -> MProxy;
  MOPnotM.T -> MProxy;
}
