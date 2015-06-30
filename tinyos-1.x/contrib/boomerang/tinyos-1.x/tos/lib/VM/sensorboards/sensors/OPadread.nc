includes Mate;

configuration OPadread {
  provides interface MateBytecode;
}
implementation {
  components MDA300AD;

  MateBytecode = MDA300AD.Adread;
}
