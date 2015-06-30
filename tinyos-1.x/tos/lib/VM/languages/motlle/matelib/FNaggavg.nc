/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
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
