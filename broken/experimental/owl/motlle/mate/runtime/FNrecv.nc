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
