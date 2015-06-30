includes Mate;

configuration OPfwrite {
  provides interface MateBytecode;
}

implementation {
  components FSMateC;

  MateBytecode = FSMateC.FWrite;
}
