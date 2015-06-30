configuration FNreal {
  provides {
    interface MateBytecode as NumberP;
    interface MateBytecode as FloatP;
    interface MateBytecode as Truncate;
    interface MateBytecode as Ceiling;
    interface MateBytecode as Floor;
  }
}
implementation {
  components FNrealM, MProxy;

  NumberP = FNrealM.NumberP;
  FloatP = FNrealM.FloatP;
  Truncate = FNrealM.Truncate;
  Ceiling = FNrealM.Ceiling;
  Floor = FNrealM.Floor;

  FNrealM.S -> MProxy;
  FNrealM.T -> MProxy;
  FNrealM.E -> MProxy;
}
