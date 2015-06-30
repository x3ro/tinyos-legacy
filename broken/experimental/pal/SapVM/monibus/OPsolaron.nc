
includes Mate;

configuration OPsolaron {
  provides interface MateBytecode;
}
implementation {
  components OPsolaronM, MStacksProxy;

  MateBytecode = OPsolaronM;
  OPsolaronM.Stacks -> MStacksProxy;
}
