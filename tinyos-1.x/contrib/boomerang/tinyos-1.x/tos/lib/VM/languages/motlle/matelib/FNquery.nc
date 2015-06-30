/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "MotlleMultihop.h"

configuration FNquery {
  provides {
    interface MateBytecode as Epoch;
    interface MateBytecode as NextEpoch;
    interface MateBytecode as SnoopEpoch;
    interface QueryAgg;
  }
}
implementation {
  components FNqueryM, MProxy, MContextSynchProxy as ContextSynch, MateEngine as VM;
  components MHandlerStoreProxy as Store, ROUTER as Mhop;

  Epoch = FNqueryM.Epoch;
  NextEpoch = FNqueryM.NextEpoch;
  SnoopEpoch = FNqueryM.SnoopEpoch;
  QueryAgg = FNqueryM;

  FNqueryM.S -> MProxy;
  FNqueryM.T -> MProxy;
  FNqueryM.E -> MProxy;
  FNqueryM.GC -> MProxy;

  FNqueryM.Synch -> ContextSynch;
  FNqueryM.EpochChangeHandler -> Store.HandlerStore[MATE_HANDLER_EPOCHCHANGE];
  FNqueryM.Analysis -> ContextSynch;

  FNqueryM.RouteControl -> Mhop;

  VM.SubControl -> FNqueryM;
}
