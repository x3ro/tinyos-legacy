configuration FNaggavg {
  provides {
    interface MateBytecode as AvgMake;
    interface MateBytecode as AvgBuffer;
    interface MateBytecode as AvgEpochUpdate;
    interface MateBytecode as AvgIntercept;
    interface MateBytecode as AvgSample;
    interface MateBytecode as AvgGet;
  }
}
implementation {
  components FNaggavgM, MProxy, FNquery;

  AvgMake = FNaggavgM.AvgMake;
  AvgBuffer = FNaggavgM.AvgBuffer;
  AvgEpochUpdate = FNaggavgM.AvgEpochUpdate;
  AvgIntercept = FNaggavgM.AvgIntercept;
  AvgSample = FNaggavgM.AvgSample;
  AvgGet = FNaggavgM.AvgGet;

  FNaggavgM.S -> MProxy;
  FNaggavgM.T -> MProxy;
  FNaggavgM.E -> MProxy;
  FNaggavgM.V -> MProxy;

  FNaggavgM.Q -> FNquery;
}
