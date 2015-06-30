configuration OPmbf3 {
  provides interface MateBytecode;
}
implementation {
  components MOPcontrol;

  MateBytecode = MOPcontrol.BranchIfFalse;
}
