configuration OPmreturn {
  provides interface MateBytecode;
}
implementation {
  components MOPcall;

  MateBytecode = MOPcall.Return;
}
