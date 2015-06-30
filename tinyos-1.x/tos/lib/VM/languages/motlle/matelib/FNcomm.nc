/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNcomm {
  provides {
    interface MateBytecode as Encode;
    interface MateBytecode as Decode;
    interface MateBytecode as Send;
  }
}
implementation {
  components FNcommM, MProxy, MContextSynchProxy, GenericComm, QueuedSend;
  components MateEngine as VM;

  Encode = FNcommM.Encode;
  Decode = FNcommM.Decode;
  Send = FNcommM.Send;

  FNcommM.S -> MProxy;
  FNcommM.T -> MProxy;
  FNcommM.E -> MProxy;
  FNcommM.V -> MProxy;
  FNcommM.GC -> MProxy;

  FNcommM.Synch -> MContextSynchProxy;
  FNcommM.EngineStatus -> VM;
  FNcommM.SendPacket -> QueuedSend.SendMsg[AM_MOTLLEMSG];
  FNcommM.sendDone <- GenericComm.sendDone;
}
