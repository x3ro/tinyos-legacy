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
  components MHandlerStoreProxy as Store, EWMAMultiHopRouter as Mhop;

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
