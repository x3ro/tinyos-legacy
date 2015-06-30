includes Mate;

configuration OPfread {
  provides interface MateBytecode;
}

implementation {
  components FSMateC;

  MateBytecode = FSMateC.FRead;
}
