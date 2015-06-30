/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author Michael Manzo <mpm@eecs.berkeley.edu>
 */

/*
 *
 * Based on the algorithm presented in the following:
 * Songhwai Oh and Shankar Sastry, "Tracking on a Graph," in Proc. of the Fourth International
 * Conference on Information Processing in Sensor Networks (IPSN05), Los Angeles, CA, April 2005. 
 *
*/

includes DistributedTracking;

configuration DistributedTrackingC {
  provides {
    interface StdControl;
    interface Track;
  }
}

implementation {
  components RegistryC;
#ifdef USE_REGISTRYSTORE
  components RegistryStoreC;
#endif
  components
    DistributedTrackingM,
    GenericComm, 
    DrainC as RouteToPoint,
#ifdef USE_DRIP
    DripC,
#endif
    Bcast,
    BcastM,
#ifdef ADJUST_RF_POWER_FOR_TRACKING
    CC2420RadioC,
#endif
    TimerC;

  StdControl = DistributedTrackingM;
#ifdef USE_DRIP
  // XXX: connect up drip...
#endif
  StdControl = Bcast;
  StdControl = RouteToPoint;

  Track = DistributedTrackingM;

#ifdef USE_REGISTRYSTORE
  DistributedTrackingM.RegistryStore -> RegistryStoreC.RegistryStore;
#endif

  // the ReportTrack interface should be connected to a
  // point-to-point routing protocal. For now, I just 
  // use a multihop algorithm to send to the base station.
  DistributedTrackingM.ReportTrackSendMsg -> RouteToPoint.SendMsg[AM_REPORTTRACKMSG];
  DistributedTrackingM.ReportTrackSend -> RouteToPoint.Send[AM_REPORTTRACKMSG];
  DistributedTrackingM.SendBacktrackingMsg -> GenericComm.SendMsg[AM_BACKTRACKINGMSG];
  DistributedTrackingM.ReceiveBacktrackingMsg -> GenericComm.ReceiveMsg[AM_BACKTRACKINGMSG];
  DistributedTrackingM.BcastDeltas -> GenericComm.SendMsg[AM_TRACKINGMSG];
  DistributedTrackingM.ReceiveTrackingDeltas -> GenericComm.ReceiveMsg[AM_TRACKINGMSG];
#ifdef USE_FAKE_DETECTIONS
  DistributedTrackingM.ReceiveFakeDetectionsMsg -> GenericComm.ReceiveMsg[AM_FAKEDETECTIONSMSG];
#endif
#ifdef SEND_TRACKING_DEBUG_MSGS
  DistributedTrackingM.SendTrackingDebugMsg -> GenericComm.SendMsg[AM_TRACKINGDEBUGMSG];
#endif
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
  DistributedTrackingM.SendBacktrackingDebugMsg -> GenericComm.SendMsg[AM_BACKTRACKINGDEBUGMSG];
#endif

#ifdef USE_TRACKING_BACKOFF
  DistributedTrackingM.TrackingBackoffTimer -> TimerC.Timer[unique("Timer")];  
#endif

#ifdef USE_BACKTRACKING_BACKOFF
  DistributedTrackingM.BacktrackingBackoffTimer -> TimerC.Timer[unique("Timer")];  
#endif

  DistributedTrackingM.TrackingTimer -> TimerC.Timer[unique("Timer")];  
  DistributedTrackingM.BacktrackingTimer -> TimerC.Timer[unique("Timer")];  

#ifdef USE_DRIP
  DripC.DripState[AM_TRACKCMDMSG] ->
    DripStateC.DripState[unique("DripState")];
  DistributedTrackingM.ReceiveTrackCmd -> DripC.Receive[AM_TRACKCMDMSG];
  DistributedTrackingM.FloodTrackCmd -> DripC.Drip[AM_TRACKCMDMSG];
#endif
  DistributedTrackingM.FloodTrackingCmd -> GenericComm.SendMsg[AM_TRACKCMDMSG];
  Bcast.ReceiveMsg[AM_TRACKCMDMSG] -> GenericComm.ReceiveMsg[AM_TRACKCMDMSG];
  DistributedTrackingM.ReceiveTrackingCmd -> Bcast.Receive[AM_TRACKCMDMSG];

#ifdef USE_SIMPLE_THRESHOLD
  DistributedTrackingM.PIRRawThresh -> RegistryC.PIRRawThresh;
#endif
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
  DistributedTrackingM.Location -> RegistryC.Location;
#endif
  DistributedTrackingM.PirSampleTimer -> RegistryC.PirSampleTimer;
#ifdef USE_PIRDETECT
  DistributedTrackingM.PIRDetectValue -> RegistryC.PIRDetectValue;
#endif
#ifdef USE_PIRRAWDRIVER
  DistributedTrackingM.PIRRawValue -> RegistryC.PIRRawValue;
#endif
  DistributedTrackingM.PIRDelayedStartTimer -> TimerC.Timer[unique("Timer")];
#ifndef USE_TOSBASE_AS_HEARTBEAT
  DistributedTrackingM.CheckOnTimeSyncValidityTimer -> TimerC.Timer[unique("Timer")];  
#endif

#ifdef ADJUST_RF_POWER_FOR_TRACKING
  DistributedTrackingM.CC2420Control -> CC2420RadioC;
#endif

  //DistributedTrackingM.SendMsg -> RouteToPoint.SendMsg[AM_DETECTIONEVENTMSG];

}
