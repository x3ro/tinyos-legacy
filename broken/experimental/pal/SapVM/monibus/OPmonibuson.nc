
includes Mate;

configuration OPmonibuson {
  provides interface MateBytecode;
}
implementation {
  components OPmonibusonM, MStacksProxy;

  MateBytecode = OPmonibusonM;
  OPmonibusonM.Stacks -> MStacksProxy;
}
