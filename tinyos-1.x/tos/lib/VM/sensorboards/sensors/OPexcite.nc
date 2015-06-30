includes Mate;

configuration OPexcite {
  provides interface MateBytecode;
}
implementation {
  components MDA300AD;

  MateBytecode = MDA300AD.Excite;
}
