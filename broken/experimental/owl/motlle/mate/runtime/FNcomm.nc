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
