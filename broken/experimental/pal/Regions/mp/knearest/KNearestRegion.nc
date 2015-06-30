
includes Region;
includes RadioRegion;
includes KNearestRegion;

configuration KNearestRegion {
  provides {
    interface Region;
    interface TupleSpace;
    interface Reduce;
  }
} implementation {

  components Main, KNRegionM, RadioRegionInternal, TuningC, 
    Location2DC, TimerC as Timer, LedsC, GenericComm as Comm, QueuedSend;

  Region = KNRegionM;
  TupleSpace = RadioRegionInternal.TupleSpace[REGION_TYPE_KNEAREST];
  Reduce = RadioRegionInternal.Reduce[REGION_TYPE_KNEAREST];

  RadioRegionInternal.ReduceTimer[REGION_TYPE_KNEAREST] -> Timer.Timer[unique("Timer")];
  RadioRegionInternal.ReduceRegion[REGION_TYPE_KNEAREST] -> KNRegionM;

  Main.StdControl -> Comm;
  Main.StdControl -> Timer;
  Main.StdControl -> KNRegionM;

  KNRegionM.Tuning -> TuningC;
  KNRegionM.Leds -> LedsC;
  KNRegionM.Location2D -> Location2DC;
  KNRegionM.Timer -> Timer.Timer[unique("Timer")];
  KNRegionM.SendMsg -> QueuedSend.SendMsg[AM_KNEARESTREGION_BEACONMSG];
  KNRegionM.ReceiveMsg -> Comm.ReceiveMsg[AM_KNEARESTREGION_BEACONMSG];

} 
