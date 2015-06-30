
includes Region;
includes RadioRegion;

configuration RadioRegion {
  provides {
    interface Region;
    interface TupleSpace;
    interface Reduce;
    interface StdControl;
  }
} implementation {

  components Main, RadioRegionInternal, TimerC;

  Region = RadioRegionInternal.Region;
  TupleSpace = RadioRegionInternal.TupleSpace[REGION_TYPE_RADIO];
  Reduce = RadioRegionInternal.Reduce[REGION_TYPE_RADIO];

  RadioRegionInternal.ReduceTimer[REGION_TYPE_RADIO] -> TimerC.Timer[unique("Timer")];
  RadioRegionInternal.ReduceRegion[REGION_TYPE_RADIO] -> RadioRegionInternal.Region;

  StdControl = RadioRegionInternal;
} 
