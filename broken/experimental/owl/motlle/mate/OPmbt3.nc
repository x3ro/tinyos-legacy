configuration OPmbt3 {
  provides interface MateBytecode;
}
implementation {
  components MOPcontrol;

  MateBytecode = MOPcontrol.BranchIfTrue;
}
