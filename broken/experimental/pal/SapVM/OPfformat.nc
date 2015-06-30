includes Mate;

configuration OPfformat {
  provides interface MateBytecode;
}

implementation {
  components FSMateC;

  MateBytecode = FSMateC.FFormat;
}
