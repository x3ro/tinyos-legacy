configuration FNstring {
  provides {
    interface MateBytecode as StringP;
    interface MateBytecode as MakeString;
    interface MateBytecode as StringLength;
    interface MateBytecode as StringFillB;
  }
}
implementation {
  components FNstringM, MProxy;

  StringP = FNstringM.StringP;
  MakeString = FNstringM.MakeString;
  StringLength = FNstringM.StringLength;
  StringFillB = FNstringM.StringFillB;

  FNstringM.S -> MProxy;
  FNstringM.T -> MProxy;
  FNstringM.E -> MProxy;
}
