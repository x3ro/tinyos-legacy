includes Mate;

configuration OPenablepin {
  provides interface MateBytecode;
}
implementation {
  components MDA300IO;

  MateBytecode = MDA300IO.EnableTrigger;
}
