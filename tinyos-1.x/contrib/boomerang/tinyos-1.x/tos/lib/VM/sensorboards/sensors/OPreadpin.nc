includes Mate;

configuration OPreadpin {
  provides interface MateBytecode;
}
implementation {
  components MDA300IO;

  MateBytecode = MDA300IO.ReadPin;
}
