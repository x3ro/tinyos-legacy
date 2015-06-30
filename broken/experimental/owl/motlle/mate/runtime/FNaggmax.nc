configuration FNaggmax {
  provides {
    interface MateBytecode as MaxMake;
    interface MateBytecode as MaxBuffer;
    interface MateBytecode as MaxEpochUpdate;
    interface MateBytecode as MaxIntercept;
    interface MateBytecode as MaxSample;
    interface MateBytecode as MaxGet;
  }
}
implementation {
  components FNaggmaxM, MProxy, FNquery;

  MaxMake = FNaggmaxM.MaxMake;
  MaxBuffer = FNaggmaxM.MaxBuffer;
  MaxEpochUpdate = FNaggmaxM.MaxEpochUpdate;
  MaxIntercept = FNaggmaxM.MaxIntercept;
  MaxSample = FNaggmaxM.MaxSample;
  MaxGet = FNaggmaxM.MaxGet;

  FNaggmaxM.S -> MProxy;
  FNaggmaxM.T -> MProxy;
  FNaggmaxM.E -> MProxy;
  FNaggmaxM.V -> MProxy;

  FNaggmaxM.Q -> FNquery;
}
