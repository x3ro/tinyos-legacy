/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
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
