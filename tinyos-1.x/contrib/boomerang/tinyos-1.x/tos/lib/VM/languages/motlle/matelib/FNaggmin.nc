/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
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
