/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNarith {
  provides {
    interface MateBytecode as IntegerP;
    interface MateBytecode as NumberP;
    interface MateBytecode as RealP;
    interface MateBytecode as Max;
    interface MateBytecode as Min;
    interface MateBytecode as Abs;
  }
}
implementation {
  components FNarithM, MProxy;

  IntegerP = FNarithM.IntegerP;
  NumberP = FNarithM.NumberP;
  RealP = FNarithM.RealP;
  Max = FNarithM.Max;
  Min = FNarithM.Min;
  Abs = FNarithM.Abs;

  FNarithM.S -> MProxy;
  FNarithM.T -> MProxy;
  FNarithM.E -> MProxy;
}
