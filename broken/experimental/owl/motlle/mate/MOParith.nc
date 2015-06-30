configuration MOParith {
  provides {
    interface MateBytecode as Arith;
    interface MateBytecode as Unary;
  }
}
implementation {
  components MOParithM, MProxy;

  Arith = MOParithM.Arith;
  Unary = MOParithM.Unary;

  MOParithM.S -> MProxy;
  MOParithM.T -> MProxy;
  MOParithM.E -> MProxy;
}
