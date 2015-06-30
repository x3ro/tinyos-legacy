configuration OPmba3 {
  provides interface MateBytecode;
}
implementation {
  components MOPcontrol;

  MateBytecode = MOPcontrol.Branch;
}
