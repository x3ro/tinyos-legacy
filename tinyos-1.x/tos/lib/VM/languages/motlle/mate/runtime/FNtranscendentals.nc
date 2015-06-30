/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNtranscendentals {
  provides {
    interface MateBytecode as Sqrt;
    interface MateBytecode as Sin;
    interface MateBytecode as Cos;
    interface MateBytecode as Tan;
    interface MateBytecode as Asin;
    interface MateBytecode as Acos;
    interface MateBytecode as Atan;
    interface MateBytecode as Exp;
    interface MateBytecode as Log;
    interface MateBytecode as Expt;
  }
}
implementation {
  components FNtranscendentalsM, MProxy;

  Sqrt = FNtranscendentalsM.Sqrt;
  Sin = FNtranscendentalsM.Sin;
  Cos = FNtranscendentalsM.Cos;
  Tan = FNtranscendentalsM.Tan;
  Asin = FNtranscendentalsM.Asin;
  Acos = FNtranscendentalsM.Acos;
  Atan = FNtranscendentalsM.Atan;
  Exp = FNtranscendentalsM.Exp;
  Log = FNtranscendentalsM.Log;
  Expt = FNtranscendentalsM.Expt;

  FNtranscendentalsM.S -> MProxy;
  FNtranscendentalsM.T -> MProxy;
  FNtranscendentalsM.E -> MProxy;
}
