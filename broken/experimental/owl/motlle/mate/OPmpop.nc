configuration OPmpop {
  provides interface MateBytecode;
}
implementation {
  components MOPpop;

  MateBytecode = MOPpop.Pop;
}
