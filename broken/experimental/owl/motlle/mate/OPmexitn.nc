configuration OPmexitn {
  provides interface MateBytecode;
}
implementation {
  components MOPpop;

  MateBytecode = MOPpop.ExitN;
}
