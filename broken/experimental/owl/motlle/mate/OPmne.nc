configuration OPmne {
  provides interface MateBytecode;
}
implementation {
  components MOPneM, MProxy;

  MateBytecode = MOPneM;
  MOPneM.S -> MProxy;
  MOPneM.T -> MProxy;
}
