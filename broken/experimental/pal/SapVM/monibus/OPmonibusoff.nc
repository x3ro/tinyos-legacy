
includes Mate;

configuration OPmonibusoff {
  provides interface MateBytecode;
}
implementation {
  components OPmonibusoffM, MStacksProxy;

  MateBytecode = OPmonibusoffM;
  OPmonibusoffM.Stacks -> MStacksProxy;
}
