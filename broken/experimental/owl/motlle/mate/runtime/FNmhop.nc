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
  components EWMAMultiHopRouter as Mhop, GenericCommPromiscuous as Comm, QueuedSend;
  components CC1000RadioC as Radio, HPLPowerManagementM;

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
  Mhop.SendMsg[AM_MOTLLE_MHOPMSG] -> QueuedSend.SendMsg[AM_MOTLLE_MHOPMSG];

  FNmhopM.CommControl -> Comm;
  FNmhopM.CC1000Control -> Radio;
  FNmhopM.PowerMgmtEnable -> HPLPowerManagementM.Enable;
#ifndef NOLPL
  FNmhopM.LowPowerListening -> Radio;
#endif
}
