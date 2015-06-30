configuration FNarith {
  provides {
    interface MateBytecode as IntegerP;
    interface MateBytecode as Max;
    interface MateBytecode as Min;
    interface MateBytecode as Abs;
  }
}
implementation {
  components FNarithM, MProxy;

  IntegerP = FNarithM.IntegerP;
  Max = FNarithM.Max;
  Min = FNarithM.Min;
  Abs = FNarithM.Abs;

  FNarithM.S -> MProxy;
  FNarithM.T -> MProxy;
  FNarithM.E -> MProxy;
}
