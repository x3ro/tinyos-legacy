includes Mate;

configuration OPwritepin {
  provides interface MateBytecode;
}
implementation {
  components MDA300IO;

  MateBytecode = MDA300IO.WritePin;
}
