/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
#ifdef NDEBUG
module MotlleDebug { }
implementation {
  int x;
}
#else
configuration MotlleDebug { }
implementation {
  components DebugC;
  components MOParithM, MOPrelM, MemoryM, GenericComm, TimerC;

  MOParithM.Debug -> DebugC;
  MOPrelM.Debug -> DebugC;
  MemoryM.Debug -> DebugC;

  DebugC.SendMsg -> GenericComm.SendMsg[22];
  DebugC.Timer -> TimerC.Timer[unique("Timer")];
}
#endif
