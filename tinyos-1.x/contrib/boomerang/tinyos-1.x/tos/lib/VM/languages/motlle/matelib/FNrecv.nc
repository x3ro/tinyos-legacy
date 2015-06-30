/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNrecv {
  provides {
    interface MateBytecode as ReceivedMsg;
  }
}
implementation {
  components FNrecvM, MProxy, MContextSynchProxy as ContextSynch, MateEngine as VM;
  components MHandlerStoreProxy as Store;
  components GenericComm as Comm;

  ReceivedMsg = FNrecvM.ReceivedMsg;

  FNrecvM.S -> MProxy;
  FNrecvM.T -> MProxy;
  FNrecvM.E -> MProxy;

  FNrecvM.Synch -> ContextSynch;
  FNrecvM.ReceiveHandler -> Store.HandlerStore[MATE_HANDLER_RECEIVE];
  FNrecvM.Analysis -> ContextSynch;

  VM.SubControl -> FNrecvM;
  VM.SubControl -> Comm;

  FNrecvM.ReceiveMsg -> Comm.ReceiveMsg[AM_MOTLLEMSG];
}
