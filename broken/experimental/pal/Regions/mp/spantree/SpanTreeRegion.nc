
includes Region;
includes RadioRegion;
includes SpanTreeRegion;

configuration SpanTreeRegion {
  provides {
    interface Region;
    interface TupleSpace;
    interface Reduce;
    interface SendMsg as SendToParent;
    interface SendMsg as SendToRoot;
    interface ReceiveMsg as ReceiveAtParent;
    interface ReceiveMsg as ReceiveAtRoot;
  }
} implementation {

  components Main, STRegionM, STTupleSpaceM, RadioRegionInternal, TuningC, 
    TimerC as Timer, GenericCommPromiscuous as Comm, QueuedSend,
    BroadcastComm, RandomLFSR;

  Region = STRegionM;
  SendToParent = STRegionM.SendToParent;
  SendToRoot = STRegionM.SendToRoot;
  ReceiveAtParent = STRegionM.ReceiveAtParent;
  ReceiveAtRoot = STRegionM.ReceiveAtRoot;
  TupleSpace = STTupleSpaceM;
  Reduce = RadioRegionInternal.Reduce[REGION_TYPE_SPANTREE];

  Main.StdControl -> STRegionM;
  Main.StdControl -> STTupleSpaceM;
  Main.StdControl -> BroadcastComm;
  Main.StdControl -> Comm;
  Main.StdControl -> Timer;

  RadioRegionInternal.ReduceTimer[REGION_TYPE_SPANTREE] -> Timer.Timer[unique("Timer")];
  RadioRegionInternal.ReduceRegion[REGION_TYPE_SPANTREE] -> STRegionM;

  STRegionM.Tuning -> TuningC;
  STRegionM.Timer -> Timer.Timer[unique("Timer")];
  STRegionM.SendBeacon -> QueuedSend.SendMsg[AM_SPANTREEREGION_BEACONMSG];
  STRegionM.ReceiveBeacon -> Comm.ReceiveMsg[AM_SPANTREEREGION_BEACONMSG];
  STRegionM.SendParent -> QueuedSend.SendMsg[AM_SPANTREEREGION_PARENTMSG];
  STRegionM.ReceiveParent -> Comm.ReceiveMsg[AM_SPANTREEREGION_PARENTMSG];
  STRegionM.SendRoot -> QueuedSend.SendMsg[AM_SPANTREEREGION_ROOTMSG];
  STRegionM.ReceiveRoot -> Comm.ReceiveMsg[AM_SPANTREEREGION_ROOTMSG];
  STRegionM.CommControl -> Comm;
  STRegionM.Random -> RandomLFSR;

  STTupleSpaceM.Tuning -> TuningC;
  STTupleSpaceM.BroadcastSend -> BroadcastComm.SendMsg;
  STTupleSpaceM.BroadcastReceive -> BroadcastComm.ReceiveMsg;

} 
