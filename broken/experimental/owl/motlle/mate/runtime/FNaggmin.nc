configuration FNaggmin {
  provides {
    interface MateBytecode as MinMake;
    interface MateBytecode as MinBuffer;
    interface MateBytecode as MinEpochUpdate;
    interface MateBytecode as MinIntercept;
    interface MateBytecode as MinSample;
    interface MateBytecode as MinGet;
  }
}
implementation {
  components FNaggminM, MProxy, FNquery;

  MinMake = FNaggminM.MinMake;
  MinBuffer = FNaggminM.MinBuffer;
  MinEpochUpdate = FNaggminM.MinEpochUpdate;
  MinIntercept = FNaggminM.MinIntercept;
  MinSample = FNaggminM.MinSample;
  MinGet = FNaggminM.MinGet;

  FNaggminM.S -> MProxy;
  FNaggminM.T -> MProxy;
  FNaggminM.E -> MProxy;
  FNaggminM.V -> MProxy;

  FNaggminM.Q -> FNquery;
}
