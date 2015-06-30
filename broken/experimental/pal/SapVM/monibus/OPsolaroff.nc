
includes Mate;

configuration OPsolaroff {
  provides interface MateBytecode;
}
implementation {
  components OPsolaroffM, MStacksProxy;

  MateBytecode = OPsolaroffM;
  OPsolaroffM.Stacks -> MStacksProxy;
}
