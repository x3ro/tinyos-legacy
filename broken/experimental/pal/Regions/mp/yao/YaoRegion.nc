/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

includes Region;
includes YaoRegion;
includes RadioRegion;
includes KNearestRegion;

/**
 * YaoRegion: An approximate planar mesh based on a pruned Yao graph.
 * See YaoRegionM.nc for details.
 */
configuration YaoRegion {
  provides {
    interface Region;
    interface TupleSpace;
    interface Reduce;
  }
} implementation {

  components Main, TimerC as Timer, TuningC, YaoRegionM, Location2DC, 
    KNearestRegion, RadioRegionInternal, LedsC, GenericComm as Comm, 
    QueuedSend;

  Region = YaoRegionM;
  TupleSpace = RadioRegionInternal.TupleSpace[REGION_TYPE_YAO];
  Reduce = RadioRegionInternal.Reduce[REGION_TYPE_YAO];

  //RadioRegionInternal.ReduceTimer[REGION_TYPE_KNEAREST] -> Timer.Timer[unique("Timer")];
  //RadioRegionInternal.ReduceRegion[REGION_TYPE_KNEAREST] -> YaoRegionM;
  
  Main.StdControl -> Comm;
  Main.StdControl -> Timer;
  Main.StdControl -> YaoRegionM;

  YaoRegionM.Tuning -> TuningC;
  YaoRegionM.TimerGetTS -> Timer.Timer[unique("Timer")];
  YaoRegionM.TimerGetLoc -> Timer.Timer[unique("Timer")];
  YaoRegionM.TimerWaitInvalid -> Timer.Timer[unique("Timer")];
  YaoRegionM.Location2D -> Location2DC;
  YaoRegionM.TupleSpace -> KNearestRegion.TupleSpace;
  YaoRegionM.RadioRegion -> KNearestRegion.Region;
  YaoRegionM.SendPickEdgeMsg -> QueuedSend.SendMsg[AM_YAOREGION_PICKEDGEMSG];
  YaoRegionM.ReceivePickEdgeMsg -> Comm.ReceiveMsg[AM_YAOREGION_PICKEDGEMSG];
  YaoRegionM.SendInvalidateMsg -> QueuedSend.SendMsg[AM_YAOREGION_INVALIDATEMSG];
  YaoRegionM.ReceiveInvalidateMsg -> Comm.ReceiveMsg[AM_YAOREGION_INVALIDATEMSG];

  RadioRegionInternal.ReduceTimer[REGION_TYPE_YAO] -> Timer.Timer[unique("Timer")];
  RadioRegionInternal.ReduceRegion[REGION_TYPE_YAO] -> YaoRegionM;

} 
