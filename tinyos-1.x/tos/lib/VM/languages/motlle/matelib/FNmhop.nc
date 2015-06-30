/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include <MotlleMultihop.h>

configuration FNmhop {
  provides {
    interface MateBytecode as InterceptMsg;
    interface MateBytecode as SnoopMsg;
    interface MateBytecode as MhopSend;
    interface MateBytecode as Parent;
    interface MateBytecode as Depth;
    interface MateBytecode as MhopSetUpdate;
    interface MateBytecode as MhopSetForwarding;
  }
}
implementation {
  components FNmhopM, MProxy, MContextSynchProxy as ContextSynch, MateEngine as VM;
  components MHandlerStoreProxy as Store;
  components ROUTER as Mhop, GenericCommPromiscuous as Comm, QueuedSend;
#ifdef LPL
  components CC1000RadioC as Radio, HPLPowerManagementM;

  FNmhopM.LowPowerListening -> Radio;
  FNmhopM.PowerMgmtEnable -> HPLPowerManagementM.Enable;
#endif

  InterceptMsg = FNmhopM.InterceptMsg;
  SnoopMsg = FNmhopM.SnoopMsg;
  MhopSend = FNmhopM.MhopSend;
  Parent = FNmhopM.Parent;
  Depth = FNmhopM.Depth;
  MhopSetUpdate = FNmhopM.MhopSetUpdate;
  MhopSetForwarding = FNmhopM.MhopSetForwarding;

  FNmhopM.S -> MProxy;
  FNmhopM.T -> MProxy;
  FNmhopM.E -> MProxy;

  FNmhopM.Synch -> ContextSynch;
  FNmhopM.EngineStatus -> VM;
  FNmhopM.InterceptHandler -> Store.HandlerStore[MATE_HANDLER_INTERCEPT];
  FNmhopM.SnoopHandler -> Store.HandlerStore[MATE_HANDLER_SNOOP];
  FNmhopM.Analysis -> ContextSynch;

  VM.SubControl -> FNmhopM;
  VM.SubControl -> Mhop;

  FNmhopM.RouteControl -> Mhop;
  FNmhopM.Send -> Mhop.Send[AM_MOTLLE_MHOPMSG];
  FNmhopM.Intercept -> Mhop.Intercept[AM_MOTLLE_MHOPMSG];
  FNmhopM.Snoop -> Mhop.Snoop[AM_MOTLLE_MHOPMSG];
  Mhop.ReceiveMsg[AM_MOTLLE_MHOPMSG] -> Comm.ReceiveMsg[AM_MOTLLE_MHOPMSG];
#ifdef ROUTER_NEEDS_SEND
  Mhop.SendMsg[AM_MOTLLE_MHOPMSG] -> QueuedSend.SendMsg[AM_MOTLLE_MHOPMSG];
#endif

  FNmhopM.CommControl -> Comm;
}
