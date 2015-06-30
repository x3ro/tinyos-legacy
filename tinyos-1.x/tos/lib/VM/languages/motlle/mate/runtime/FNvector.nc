/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNvector {
  provides {
    interface MateBytecode as VectorP;
    interface MateBytecode as MakeVector;
    interface MateBytecode as VectorLength;
    interface MateBytecode as VectorFillB;
    interface MateBytecode as Vector;
  }
}
implementation {
  components FNvectorM, MProxy;

  VectorP = FNvectorM.VectorP;
  MakeVector = FNvectorM.MakeVector;
  VectorLength = FNvectorM.VectorLength;
  VectorFillB = FNvectorM.VectorFillB;
  Vector = FNvectorM.Vector;

  FNvectorM.S -> MProxy;
  FNvectorM.T -> MProxy;
  FNvectorM.E -> MProxy;
  FNvectorM.V -> MProxy;
}
