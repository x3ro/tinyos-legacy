/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNbasic {
  provides {
    interface MateBytecode as FunctionP;
    interface MateBytecode as SymbolP;
    interface MateBytecode as Apply;
    interface MateBytecode as Error;
    interface MateBytecode as GarbageCollect;
  }
}
implementation {
  components FNbasicM, MProxy, MOPcall;

  FunctionP = FNbasicM.FunctionP;
  SymbolP = FNbasicM.SymbolP;
  Apply = FNbasicM.Apply;
  Error = FNbasicM.Error;
  GarbageCollect = FNbasicM.GarbageCollect;

  FNbasicM.S -> MProxy;
  FNbasicM.T -> MProxy;
  FNbasicM.E -> MProxy;
  FNbasicM.V -> MProxy;
  FNbasicM.GC -> MProxy;
  FNbasicM.Exec -> MOPcall.Exec;
}
