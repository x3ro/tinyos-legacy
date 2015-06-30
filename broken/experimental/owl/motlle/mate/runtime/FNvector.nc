configuration FNvector {
  provides {
    interface MateBytecode as VectorP;
    interface MateBytecode as MakeVector;
    interface MateBytecode as VectorLength;
    interface MateBytecode as VectorFillB;
    interface MateBytecode as Vector;
  }
}
implementation {
  components FNvectorM, MProxy;

  VectorP = FNvectorM.VectorP;
  MakeVector = FNvectorM.MakeVector;
  VectorLength = FNvectorM.VectorLength;
  VectorFillB = FNvectorM.VectorFillB;
  Vector = FNvectorM.Vector;

  FNvectorM.S -> MProxy;
  FNvectorM.T -> MProxy;
  FNvectorM.E -> MProxy;
  FNvectorM.V -> MProxy;
}
