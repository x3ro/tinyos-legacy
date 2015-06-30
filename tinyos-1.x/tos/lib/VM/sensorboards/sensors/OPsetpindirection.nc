includes Mate;

configuration OPsetpindirection {
  provides interface MateBytecode;
}
implementation {
  components MDA300IO;

  MateBytecode = MDA300IO.SetPinDirection;
}
