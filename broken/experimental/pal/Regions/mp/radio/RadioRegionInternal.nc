
includes Region;
includes RadioRegion;

configuration RadioRegionInternal {
  provides {
    interface Region;
    interface TupleSpace[uint8_t type];
    interface Reduce[uint8_t type];
    interface StdControl;
  }
  uses {
    interface Timer as ReduceTimer[uint8_t type];
    interface Region as ReduceRegion[uint8_t type];
  }
} implementation {

  components Main, RRRegionM, RRTupleSpaceM, RRReduceM, TuningC, 
    TimerC as Timer, LedsC, GenericComm as Comm, QueuedSend;

  Region = RRRegionM.Region;
  TupleSpace = RRTupleSpaceM.TupleSpace;
  Reduce = RRReduceM.Reduce;

  ReduceTimer = RRReduceM.Timer;
  ReduceRegion = RRReduceM.Region;

  Main.StdControl -> Comm;
  Main.StdControl -> Timer;
  Main.StdControl -> RRRegionM;
  Main.StdControl -> RRTupleSpaceM;

  StdControl = RRTupleSpaceM;
  StdControl = RRRegionM;
  
  RRRegionM.Tuning -> TuningC;
  RRRegionM.Leds -> LedsC;
  RRRegionM.Timer -> Timer.Timer[unique("Timer")];
  RRRegionM.SendMsg -> Comm.SendMsg[AM_RADIOREGION_BEACONMSG];
  RRRegionM.ReceiveMsg -> Comm.ReceiveMsg[AM_RADIOREGION_BEACONMSG];

  RRTupleSpaceM.Tuning -> TuningC;
  RRTupleSpaceM.SendMsg -> QueuedSend.SendMsg[AM_RADIOREGION_TSMSG];
  RRTupleSpaceM.ReceiveMsg -> Comm.ReceiveMsg[AM_RADIOREGION_TSMSG];

  RRReduceM.Tuning -> TuningC;
  RRReduceM.TupleSpace -> RRTupleSpaceM;


} 
