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

includes DistributedTracking;
includes Bcast;
includes Drain;
includes DetectionEvent;

module DistributedTrackingM {
  provides {
    interface StdControl;
    interface Track;
  }
  uses interface Attribute<uint16_t> as PirSampleTimer @registry("PirSampleTimer");
#ifdef USE_PIRDETECT
  uses interface Attribute<uint16_t> as PIRDetectValue @registry("PIRDetectValue");
#endif
#ifdef USE_SIMPLE_THRESHOLD
  uses interface Attribute<uint16_t> as PIRRawThresh @registry("PIRRawThresh");
#endif
#ifdef USE_PIRRAWDRIVER 
  uses interface Attribute<uint16_t> as PIRRawValue @registry("PIRRawValue");
#endif
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
  uses interface Attribute<location_t> as Location @registry("Location");
#ifdef USE_REGISTRYSTORE
  uses interface RegistryStore;
#endif
#endif
#ifdef ADJUST_RF_POWER_FOR_TRACKING
  uses interface CC2420Control;
#endif
  uses interface Timer as PIRDelayedStartTimer;
  uses {
#ifdef SEND_TRACKING_DEBUG_MSGS
    interface SendMsg as SendTrackingDebugMsg;
#endif
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
    interface SendMsg as SendBacktrackingDebugMsg;
#endif
    interface SendMsg as ReportTrackSendMsg;
    interface Send as ReportTrackSend;
    interface SendMsg as SendBacktrackingMsg;
    interface ReceiveMsg as ReceiveBacktrackingMsg;
    interface SendMsg as BcastDeltas;
    interface ReceiveMsg as ReceiveTrackingDeltas;
#ifdef USE_FAKE_DETECTIONS
    interface ReceiveMsg as ReceiveFakeDetectionsMsg;
#endif

    interface Timer as TrackingTimer; 
    interface Timer as BacktrackingTimer;
#ifdef USE_BACKTRACKING_BACKOFF
    interface Timer as BacktrackingBackoffTimer;
#endif
#ifdef USE_TRACKING_BACKOFF
    interface Timer as TrackingBackoffTimer;
#endif
    interface Receive as ReceiveTrackingCmd;
#ifdef USE_DRIP
    interface Drip as FloodTrackingCmd;
#else
    interface SendMsg as FloodTrackingCmd;
#endif
#ifndef USE_TOSBASE_AS_HEARTBEAT
    interface Timer as CheckOnTimeSyncValidityTimer; 
#endif
  }
}

implementation {
  bool global_time_correct;
  TOS_Msg backtrackingMsgBuffer; // used to store a BacktrackingMsgBuffer
  TOS_Msg trackingCmdMsgBuffer; // used to store a TrackingCmdMsg
  TOS_Msg trackingMsgBuffer; // used to store a TrackingMsg
#ifdef SEND_TRACKING_DEBUG_MSGS
  TOS_Msg trackingDebugMsgBuffer; // used to store a TrackingDebugMsg
#endif
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
  TOS_Msg backtrackingDebugMsgBuffer; // used to store a TrackingDebugMsg
#endif
  TOS_Msg backtrackingMsgBuffer; // used to store a BacktrackingMsg
  TOS_Msg reportTrackMsgBuffer; // used to store a ReportTrackMsg

  float nbrBacktrackingDeltas[MAX_NBRHOOD_SIZE + 1];
  uint16_t nbrBacktrackingTracks[MAX_NBRHOOD_SIZE + 1][MAX_LOCATIONS_PER_MESSAGE];
  uint16_t backtrackingTime; 
  uint16_t numNbrsReportedBacktracking;

  float nbrTrackingDeltas[MAX_NBRHOOD_SIZE + 1];
  uint16_t track[MAX_LOCATIONS_PER_MESSAGE];
  uint32_t trackingPeriod;
  uint32_t backtrackingPeriod;
  bool trackingTimerInitialized;
  uint8_t trackingTimerPeriodsSinceTrackingInitiation;
  float bestTrackingDelta; 
  bool detectionOccured;
  uint16_t anyUpdateOccured;
  uint16_t numNbrTrackingMsgsReceived; // Just for debugging.

  float initialProb;
  float detectionProb;
  // this maps {0,..,MAX_NBRHOOD_SIZE} -> node id
  uint16_t nbrs[MAX_NBRHOOD_SIZE + 1]; 
  // this maps the same index used in nbrs -> a transition prob
  float transitionProbs[MAX_NBRHOOD_SIZE + 1]; 

  uint16_t bcastSeqNo;

  bool radioBusy;

  uint16_t numNodes;
  uint16_t numNodesSqrt;
  uint16_t trackLength;
  uint16_t numTrackingContinuations;
  // Tracking will not continue when currentTrackingContinuation is >= numTrackingContinuations
  uint16_t currentTrackingContinuation; 

  uint16_t TOSLocalAddressShiftedDown;

#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
  int32_t xLocation;
  int32_t yLocation;
  uint16_t currentNumNbrs;
#endif

  uint16_t lastConfidence;
  uint16_t myThreshold;

#ifdef USE_FAKE_DETECTIONS
  uint16_t fakeDetections[MAX_LOCATIONS_PER_MESSAGE];
#endif

/*********************************************
*
*  A few function declarations.
*
**********************************************/  

  task void StartBacktrackingTask();
  void initiateTracking();

/*********************************************
*
*  Some useful little functions.
*
**********************************************/  

#ifdef USE_BACKTRACKING_BACKOFF
  void SendBacktrackingMsgTaskDelayed() {
    uint32_t delay = 0;
    // XXX: This is terrible, but hopefully helps a bit:
    if ((TOS_LOCAL_ADDRESS % 3) == 0) {
      delay += 32;
    } else if ((TOS_LOCAL_ADDRESS % 3) == 1) {
      delay += 96;
    } else {
      delay += 160;
    }
    /*
      if (((((TOS_LOCAL_ADDRESS - (TOS_LOCAL_ADDRESS % 10)) / 10) % 10) % 2) == 0) {
      delay += 32;
      }
    */
    call BacktrackingBackoffTimer.start(TIMER_ONE_SHOT, delay);
  }
#endif

  uint16_t mapNodeIDToIndex(uint16_t nodeID) {
    uint16_t i;
    for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
      if (nbrs[i] == nodeID) {
        return i;
      }
    }
    return 0xffff;
  }

  void processTrackingCmd(TOS_MsgPtr msg, uint16_t payloadLen) {
    TOS_BcastMsg *bcastmsg = (TOS_BcastMsg *) &msg->data[0];
    TrackingCmdMsg* newestCmd = (TrackingCmdMsg *) &bcastmsg->data[0];

#ifdef USE_TOSBASE_AS_HEARTBEAT
    myThreshold = newestCmd->myThreshold;
#ifdef USE_SIMPLE_THRESHOLD
    call PIRRawThresh.set(myThreshold);
#endif
    if ((newestCmd->trackingPeriod > MIN_TRACKING_PERIOD) && (newestCmd->trackingPeriod < MAX_TRACKING_PERIOD)) {
      trackingPeriod = newestCmd->trackingPeriod;
    }
    if ((newestCmd->backtrackingPeriod > MIN_BACKTRACKING_PERIOD) && (newestCmd->backtrackingPeriod < MAX_BACKTRACKING_PERIOD)) {
      backtrackingPeriod = newestCmd->backtrackingPeriod;
    }
    if ((newestCmd->trackLength > 1) && (newestCmd->trackLength < MAX_TRACK_LENGTH)) {
      trackLength = newestCmd->trackLength;
    }
    bcastSeqNo = bcastmsg->seqno;
#if 1
    radioBusy = FALSE;
#endif
#else
    if (TOS_LOCAL_ADDRESS != NODE_ID_SHIFT) {
      bcastSeqNo = bcastmsg->seqno;
    }
#endif
    call TrackingTimer.stop();
    call BacktrackingTimer.stop();
    // XXX: Do I need this?
    memcpy(&trackingCmdMsgBuffer, msg, sizeof(TOS_Msg) - TOSH_DATA_LENGTH + payloadLen);
#ifdef USE_TOSBASE_AS_HEARTBEAT
    initiateTracking();
#else
    if (newestCmd->cmd == SINGLE_BACKTRACK) {
      post StartBacktrackingTask();
    } else if (newestCmd->cmd == START_TRACKING) {
      initiateTracking();
    }
#endif
  }

  void initiateTracking() {
    uint16_t i;
    TrackingMsg *trackingmsg = (TrackingMsg *) &trackingMsgBuffer.data[0];
    trackingTimerInitialized = FALSE;
    trackingTimerPeriodsSinceTrackingInitiation = 0;
    numNbrTrackingMsgsReceived = 0;
    trackingmsg->origin = TOS_LOCAL_ADDRESS;
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
    trackingmsg->xLocation = xLocation + 1;
    trackingmsg->yLocation = yLocation + 1;
    // build up the transitionProbs
#endif
    for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
      nbrTrackingDeltas[i] = logf(0);
    }
    for (i = 0; i < MAX_TRACK_LENGTH; i++) {
      track[i] = 0xffff;
    }
    call TrackingTimer.start(TIMER_REPEAT, trackingPeriod);
  }

/*********************************************
*
*  Tasks
*
**********************************************/

  task void SendBacktrackingMsgTask() {
    BacktrackingMsg *backtrackingmsg = (BacktrackingMsg *) &backtrackingMsgBuffer.data[0];
    int i;
    if (radioBusy == FALSE) {
#ifdef ADJUST_RF_POWER_FOR_TRACKING
      call CC2420Control.SetRFPower(5);
#endif
#if DO_NOT_SUPPRESS_EXTRA_BACKTRACKING_MSGS
      if (call SendBacktrackingMsg.send(track[trackLength - (backtrackingTime + 1)],
                                        sizeof(BacktrackingMsg),
                                        &backtrackingMsgBuffer) == SUCCESS) {
        radioBusy = TRUE;
        return;
      } 
#else
      if (call SendBacktrackingMsg.send(track[trackLength - (backtrackingTime + 1)],
                                        sizeof(BacktrackingMsg),
                                        &backtrackingMsgBuffer) == SUCCESS) {
        radioBusy = TRUE;
        return;
      }
#endif
    }
    post SendBacktrackingMsgTask();
  }

  task void FloodTrackingCmdTask() {
    TOS_BcastMsg *bcastmsg = (TOS_BcastMsg *) &trackingCmdMsgBuffer.data[0];
    TrackingCmdMsg *trackingcmdmsg = (TrackingCmdMsg *) &bcastmsg->data[0];
    if (!radioBusy) {
      trackingcmdmsg->requester = TOS_LOCAL_ADDRESS;
      if (call FloodTrackingCmd.send(TOS_BCAST_ADDR, 
                                     trackingCmdMsgBuffer.length, 
                                     &trackingCmdMsgBuffer) == SUCCESS) {
        bcastSeqNo++;
        bcastmsg->seqno = bcastSeqNo;
        radioBusy = TRUE;
        return;
      } 
    }
    post FloodTrackingCmdTask();
  }

  task void ReportTrackTask() {
    if (radioBusy == FALSE) {
      if (call ReportTrackSendMsg.send(TOS_DEFAULT_ADDR,
                                       sizeof(ReportTrackMsg),
                                       &reportTrackMsgBuffer) == SUCCESS) {
        radioBusy = TRUE;
        return;
      } 
    }
    post ReportTrackTask();
  }

#ifdef SEND_BACKTRACKING_DEBUG_MSGS
  task void SendBacktrackingDebugMsgTask() {    
    BacktrackingDebugMsg *backtrackingdebugmsg = \
      (BacktrackingDebugMsg *) &backtrackingDebugMsgBuffer.data[0];
    int i;
    for (i = trackLength; i < MAX_LOCATIONS_PER_MESSAGE; i++) {
      backtrackingdebugmsg->track[i] = nbrs[i - trackLength];
    }
    if (!radioBusy) {
      if (call SendBacktrackingDebugMsg.send(0xffff,
                                             sizeof(BacktrackingDebugMsg),
                                             &backtrackingDebugMsgBuffer) == SUCCESS) {
        radioBusy = TRUE;
        return;
      }
    }
    post SendBacktrackingDebugMsgTask();
  }
#endif

#ifdef SEND_TRACKING_DEBUG_MSGS
  task void SendTrackingDebugMsgTask() {    
    TrackingDebugMsg *trackingdebugmsg = (TrackingDebugMsg *) &trackingDebugMsgBuffer.data[0];
    int i;
    for (i = trackLength; i < MAX_TRACK_LENGTH; i++) {
      trackingdebugmsg->track[i] = nbrs[i - trackLength];
    }
    if (!radioBusy) {
      if (call SendTrackingDebugMsg.send(0xffff,
                                         sizeof(TrackingDebugMsg),
                                         &trackingDebugMsgBuffer) == SUCCESS) {
        radioBusy = TRUE;
        return;
      }
    }
    post SendTrackingDebugMsgTask();
  }
#endif

  task void StartBacktrackingTask() {
    int i,j;
    BacktrackingMsg *backtrackingmsg = (BacktrackingMsg *) &backtrackingMsgBuffer.data[0];
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
    BacktrackingDebugMsg *backtrackingdebugmsg = \
      (BacktrackingDebugMsg *) &backtrackingDebugMsgBuffer.data[0];
    for (i = 0; i < sizeof(BacktrackingDebugMsg); i++) {
      backtrackingDebugMsgBuffer.data[i] = 0;
    }
#endif
    for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
      nbrBacktrackingDeltas[i] = logf(0);
      for (j = 0; j < trackLength; j++) {
        nbrBacktrackingTracks[i][j] = 0xffff;
      }
    }
    for (i = 0; i < MAX_LOCATIONS_PER_MESSAGE; i++) {
      backtrackingmsg->track[i] = 0xffff;
    }
    numNbrsReportedBacktracking = 0;
    backtrackingTime = 0;
    backtrackingmsg->backtrackingTime = 0;
    backtrackingmsg->origin = TOS_LOCAL_ADDRESS;
    backtrackingmsg->delta = bestTrackingDelta;
    backtrackingmsg->track[trackLength - 1] = TOS_LOCAL_ADDRESS;
#if 1
    backtrackingmsg->track[trackLength - 2] = track[trackLength - 1];;
#endif
#ifdef DO_NOT_SUPPRESS_EXTRA_BACKTRACKING_MSGS
    if (track[trackLength - 1] == TOS_LOCAL_ADDRESS) {
      numNbrsReportedBacktracking = 1;
      nbrBacktrackingTracks[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)][trackLength - 1] = \
        track[trackLength - 1];
      nbrBacktrackingDeltas[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)] = backtrackingmsg->delta;
    }
#ifdef USE_BACKTRACKING_BACKOFF
    SendBacktrackingMsgTaskDelayed();
#else
    post SendBacktrackingMsgTask();
#endif
#else
    if (track[trackLength - 1] == TOS_LOCAL_ADDRESS) {
      numNbrsReportedBacktracking = 1;
      nbrBacktrackingTracks[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)][trackLength - 1] = \
        track[trackLength - 1];
      nbrBacktrackingDeltas[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)] = backtrackingmsg->delta;
    } else {
#ifdef USE_BACKTRACKING_BACKOFF
      SendBacktrackingMsgTaskDelayed();
#else
      post SendBacktrackingMsgTask();
#endif
    }
#endif
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
    for (i = 0; i < trackLength; i++) {
      backtrackingdebugmsg->track[i] = backtrackingmsg->track[i];
    }
    backtrackingdebugmsg->time = backtrackingTime;
    backtrackingdebugmsg->origin = TOS_LOCAL_ADDRESS;
    post SendBacktrackingDebugMsgTask();
#endif
    call BacktrackingTimer.start(TIMER_REPEAT, backtrackingPeriod);
  }

  task void BcastDeltasTask() {    
    if (radioBusy == FALSE) {
#ifdef ADJUST_RF_POWER_FOR_TRACKING
      call CC2420Control.SetRFPower(5);
#endif
      if (call BcastDeltas.send(TOS_BCAST_ADDR, 
                                sizeof(TrackingMsg), 
                                &trackingMsgBuffer) == SUCCESS) {
        radioBusy = TRUE;
        return;
      }
    }
    post BcastDeltasTask();
  }
  
/*********************************************
*
*  Commands and events
*
**********************************************/

  command result_t StdControl.init() {
    TrackingCmdMsg *trackingcmdmsg;
    int i, j;
    float selfTransitionProb = 0.2;
    anyUpdateOccured = 0;
#ifdef USE_FAKE_DETECTIONS
    for (i = 0; i < MAX_LOCATIONS_PER_MESSAGE; i++) {
      fakeDetections[i] = 65535;
    }
#endif
#ifdef USE_SIMPLE_THRESHOLD
    myThreshold = 3000;
#else
    myThreshold = 50;
#endif
#if 0
    trackLength = MAX_TRACK_LENGTH;
#else
    trackLength = 4;
#endif
    bcastSeqNo = 0;
    radioBusy = FALSE;
    detectionOccured = FALSE;
    memset(&trackingCmdMsgBuffer, 0x00, sizeof(TOS_Msg));
    memset(&trackingMsgBuffer, 0x00, sizeof(TOS_Msg));
#ifdef SEND_TRACKING_DEBUG_MSGS
    memset(&trackingDebugMsgBuffer, 0x00, sizeof(TOS_Msg));
#endif
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
    memset(&backtrackingDebugMsgBuffer, 0x00, sizeof(TOS_Msg));
#endif
    memset(&backtrackingMsgBuffer, 0x00, sizeof(TOS_Msg));
    memset(&reportTrackMsgBuffer, 0x00, sizeof(TOS_Msg));
    backtrackingTime = trackLength - 1;
    trackingPeriod = DEFAULT_TRACKING_PERIOD;
    backtrackingPeriod = DEFAULT_BACKTRACKING_PERIOD;
    trackingcmdmsg = (TrackingCmdMsg *) &trackingCmdMsgBuffer.data[0];
    for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
      transitionProbs[i] = 0;
      nbrs[i] = 0xffff;
    }    
    for (j = 0; j < MAX_NBRHOOD_SIZE + 1; j++) {
      transitionProbs[j] = (float) 0;
    }
    transitionProbs[0] = selfTransitionProb;
    nbrs[0] = TOS_LOCAL_ADDRESS;
    currentNumNbrs = 1;
    detectionProb = 0.7;
#ifdef USE_DRIP
    call Drip.init();
#endif
    for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
      nbrBacktrackingDeltas[i] = logf(0);
      for (j = 0; j < MAX_LOCATIONS_PER_MESSAGE; j++) {
        nbrBacktrackingTracks[i][j] = 0xffff;
      }
    }
    for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
      nbrTrackingDeltas[i] = 0;
    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
    int i;
    location_t myLocation;
#ifdef USE_REGISTRYSTORE
    if (call RegistryStore.restore(ATTRIBUTE_LOCATION)) {
      myLocation = call Location.get();
      if ((myLocation.x == 0xffff) || (myLocation.y == 0xffff) || 
          ((myLocation.x % 5) != 0) || ((myLocation.y % 5) != 0) || 
          ((myLocation.x == 0) && (myLocation.y == 0) && (TOS_LOCAL_ADDRESS != 1151))) {
        xLocation = -1;
        yLocation = -1;
      } else {
        xLocation = myLocation.x;
        yLocation = myLocation.y;
      }
    } else {
      xLocation = -1;
      yLocation = -1;
    }
#else
    xLocation = -1;
    yLocation = -1;
    for (i = 0; i < 300; i++) {
      if (locations[i][0] == TOS_LOCAL_ADDRESS) {
        xLocation = (int32_t) locations[i][1];
        yLocation = (int32_t) locations[i][2];
        break;
      }
    }
#endif
#endif
#ifdef ADJUST_RF_POWER_FOR_TRACKING
    call CC2420Control.SetRFPower(20);
#endif
#ifdef USE_SIMPLE_THRESHOLD
    call PIRRawThresh.set(DEFAULT_SIMPLE_THRESHOLD);
#endif
    call PIRDelayedStartTimer.start(TIMER_ONE_SHOT, 512);
#ifdef USE_TOSBASE_AS_HEARTBEAT
    return SUCCESS;
#else
    return call CheckOnTimeSyncValidityTimer.start(TIMER_ONE_SHOT, 
						   PERIOD_TO_WAIT_FOR_TIME_SYNC_VALIDITY);
#endif
  }

  command result_t StdControl.stop() {
#ifdef USE_TOSBASE_AS_HEARTBEAT
    return rcombine(call BacktrackingTimer.stop(),  
                     call TrackingTimer.stop());
#else
    return rcombine3(call BacktrackingTimer.stop(),  
                     call TrackingTimer.stop(), 
                     call CheckOnTimeSyncValidityTimer.stop());
#endif
  }

#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
  event void Location.updated(location_t location) {
    // Required by compiler. Do nothing.
    return;
  }
#endif

  event void PirSampleTimer.updated(uint16_t period) {
    // Required by compiler. Do nothing.
    return;
  }
#ifdef USE_PIRDETECT
  event void PIRDetectValue.updated(uint16_t data) {
    lastConfidence = data;
    if (data > myThreshold) {
      detectionOccured = TRUE;      
    } else {
      detectionOccured = FALSE;
    }
  }
#endif

#ifdef USE_SIMPLE_THRESHOLD
  event void PIRRawThresh.updated(uint16_t data) {
    // required by compiler
    return;
  }
#endif

#ifdef USE_PIRRAWDRIVER
  event void PIRRawValue.updated( uint16_t data ) {
#ifdef SEND_TRACKING_DEBUG_MSGS
    /*
      if (!radioBusy) {
      if (call SendTrackingDebugMsg.send(0xffaa,
      sizeof(TrackingDebugMsg),
      &trackingDebugMsgBuffer) == SUCCESS) {
      radioBusy = TRUE;
      } else {
      radioBusy = FALSE;
      }
    }
    */
#endif
    anyUpdateOccured++;
    lastConfidence = data;
    if (data > myThreshold) {
      detectionOccured = TRUE;      
    } else {
      detectionOccured = FALSE;
    }
  }
#endif

#ifdef USE_FAKE_DETECTIONS
  event TOS_MsgPtr ReceiveFakeDetectionsMsg.receive(TOS_MsgPtr msg) {
    int i;
    FakeDetectionsMsg *fakedetectionsmsg = (FakeDetectionsMsg *) &msg->data[0];    
    for (i = 0; i < MAX_LOCATIONS_PER_MESSAGE; i++) {
      fakeDetections[i] = fakedetectionsmsg->detections[i];
    }
    return msg;
  }
#endif

  event TOS_MsgPtr ReceiveTrackingCmd.receive(TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
    // Surprisingly, payloadLen doesn't get set by the radio stack. Seems like
    // it should, since it can calculate the payload length from the total
    // size of the message and the size of the header, both of which it knows.
    payloadLen = sizeof(TOS_BcastMsg);
    processTrackingCmd(msg, payloadLen);
    return msg;
  }

  command result_t Track.startSingleTrackReport() {
    TOS_BcastMsg *bcastmsg = (TOS_BcastMsg *) &trackingCmdMsgBuffer.data[0];
    TrackingCmdMsg *trackingcmdmsg = (TrackingCmdMsg *) &bcastmsg->data[0];
    trackingcmdmsg->cmd = SINGLE_BACKTRACK;
    post FloodTrackingCmdTask();
    return SUCCESS;
  }

#ifdef USE_DRIP
    call FloodTrackingCmd.change();
    return SUCCESS;
    }    
#endif
  
  event result_t SendBacktrackingMsg.sendDone(TOS_MsgPtr msg, result_t success) {
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
    /*
      if (call SendBacktrackingDebugMsg.send(0xffff,
      sizeof(BacktrackingDebugMsg),
      &backtrackingDebugMsgBuffer) == SUCCESS) {
      radioBusy = TRUE;
      } else {
      radioBusy = FALSE;
      }
    */
#endif
    radioBusy = FALSE;
    return SUCCESS;
  }

  event result_t PIRDelayedStartTimer.fired() {
    call PirSampleTimer.set(102);
    return SUCCESS;
  }

  event result_t BcastDeltas.sendDone(TOS_MsgPtr msg, result_t success) {
    radioBusy = FALSE;
#ifdef SEND_TRACKING_DEBUG_MSGS
    post SendTrackingDebugMsgTask();
#endif
    return SUCCESS;
  }

  event result_t TrackingTimer.fired() {
    int i, j;
    uint16_t bestNbr = 0;
    TrackingMsg *trackingmsg = (TrackingMsg *) &trackingMsgBuffer.data[0];
#ifdef SEND_TRACKING_DEBUG_MSGS
    TrackingDebugMsg *trackingdebugmsg = (TrackingDebugMsg *) &trackingDebugMsgBuffer.data[0];
#endif
    // not >= trackLength -1 since we need it to send the tracking msg for trackLength - 1
    if (trackingTimerPeriodsSinceTrackingInitiation >= trackLength) {
      call TrackingTimer.stop();
#ifndef USE_TOSBASE_AS_HEARTBEAT
      if (TOS_LOCAL_ADDRESS == NODE_ID_SHIFT) {
        call Track.startSingleTrackReport();
      }
#else
      post StartBacktrackingTask();
#endif
      return SUCCESS;
    }
    if (!trackingTimerInitialized) {
      trackingTimerInitialized = TRUE;
      return SUCCESS;
    }
#ifdef USE_FAKE_DETECTIONS
    if (fakeDetections[trackingTimerPeriodsSinceTrackingInitiation] == TOS_LOCAL_ADDRESS) {
      detectionOccured = TRUE;
    } else {
      detectionOccured = FALSE;
    }
#endif
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
    if (currentNumNbrs <= 1) {
      trackingmsg->xLocation = xLocation + 1;
      trackingmsg->yLocation = yLocation + 1;
      trackingmsg->trackingTime = trackingTimerPeriodsSinceTrackingInitiation;
      trackingTimerPeriodsSinceTrackingInitiation++;
      trackingmsg->delta = logf(0);
      trackingmsg->detectionOccured = detectionOccured;
      trackingmsg->bestNbr = 0xffff;
#ifdef SEND_TRACKING_DEBUG_MSGS
      trackingdebugmsg->numNbrTrackingMsgsReceived = numNbrTrackingMsgsReceived;
      trackingdebugmsg->currentNumNbrs = currentNumNbrs;
      trackingdebugmsg->lastConfidence = lastConfidence;
      trackingdebugmsg->anyUpdateOccured = anyUpdateOccured;
#endif
      anyUpdateOccured = 0;
      detectionOccured = FALSE;
      for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
        nbrTrackingDeltas[i] = logf(0);
      }
      nbrTrackingDeltas[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)] = logf(0);
#ifdef USE_TRACKING_BACKOFF
      if ((TOS_LOCAL_ADDRESS % 3) == 0) {
        call TrackingBackoffTimer.start(TIMER_ONE_SHOT, 100);
      } else if ((TOS_LOCAL_ADDRESS % 3) == 1) {
        call TrackingBackoffTimer.start(TIMER_ONE_SHOT, 200);
      } else {
        call TrackingBackoffTimer.start(TIMER_ONE_SHOT, 300);
      }
#else
      post BcastDeltasTask();
#endif
      return SUCCESS;
    }
#endif
    if (trackingTimerPeriodsSinceTrackingInitiation == 0) {
      trackingmsg->lastBestDelta = logf(0);
      if (detectionOccured) {
        bestTrackingDelta = logf(0.7);
      } else {
        bestTrackingDelta = logf(0.3);
      }
    } else {
      bestTrackingDelta = logf(0);      
      for (j = 0; j < MAX_NBRHOOD_SIZE + 1; j++) {          
        if (transitionProbs[j] > 0) {
          if (nbrTrackingDeltas[j] > bestTrackingDelta) {
            bestTrackingDelta = nbrTrackingDeltas[j];
            bestNbr = j;
          } 
        } 
      }
      trackingmsg->lastBestDelta = bestTrackingDelta;
      if (detectionOccured) {
        bestTrackingDelta = nbrTrackingDeltas[bestNbr] +	
          logf(transitionProbs[bestNbr] *                 
               detectionProb);
      } else { 
        bestTrackingDelta = nbrTrackingDeltas[bestNbr] +	
          logf(transitionProbs[bestNbr] *                 
               (1 - detectionProb));
      } 
      track[trackingTimerPeriodsSinceTrackingInitiation] = nbrs[bestNbr];
    }
#ifdef SEND_TRACKING_DEBUG_MSGS
    for (i = 0; i < trackLength; i++) {
      trackingdebugmsg->track[i] = track[i];
    }
    trackingdebugmsg->time = trackingTimerPeriodsSinceTrackingInitiation;
    trackingdebugmsg->origin = TOS_LOCAL_ADDRESS;
#endif
    trackingmsg->trackingTime = trackingTimerPeriodsSinceTrackingInitiation;
    trackingTimerPeriodsSinceTrackingInitiation++;
    trackingmsg->delta = bestTrackingDelta;
    trackingmsg->detectionOccured = detectionOccured;
    trackingmsg->bestNbr = nbrs[bestNbr];
#ifdef SEND_TRACKING_DEBUG_MSGS
    trackingdebugmsg->numNbrTrackingMsgsReceived = numNbrTrackingMsgsReceived;
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
    trackingdebugmsg->currentNumNbrs = currentNumNbrs;
#endif
    trackingdebugmsg->lastConfidence = lastConfidence;
    trackingdebugmsg->anyUpdateOccured = anyUpdateOccured;
#endif
    anyUpdateOccured = 0;
    detectionOccured = FALSE;
    for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
      nbrTrackingDeltas[i] = logf(0);
    }
    nbrTrackingDeltas[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)] = bestTrackingDelta;
    numNbrTrackingMsgsReceived = 0;  
#ifdef USE_TRACKING_BACKOFF
    if ((TOS_LOCAL_ADDRESS % 3) == 0) {
      call TrackingBackoffTimer.start(TIMER_ONE_SHOT, 100);
    } else if ((TOS_LOCAL_ADDRESS % 3) == 1) {
      call TrackingBackoffTimer.start(TIMER_ONE_SHOT, 200);
    } else {
      call TrackingBackoffTimer.start(TIMER_ONE_SHOT, 300);
    }
#else
    post BcastDeltasTask();
#endif
  return SUCCESS;
  }
  
  event TOS_MsgPtr ReceiveTrackingDeltas.receive(TOS_MsgPtr m) {
    TrackingMsg *trackingmsg = (TrackingMsg *) &m->data[0];
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
    int32_t receivedXLocation;
    int32_t receivedYLocation;
#endif    
    if (mapNodeIDToIndex(trackingmsg->origin) != 0xffff) {
      numNbrTrackingMsgsReceived++;  
      nbrTrackingDeltas[mapNodeIDToIndex(trackingmsg->origin)] = trackingmsg->delta;
    }
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
    else {
      if (currentNumNbrs < MAX_NBRHOOD_SIZE) {
        if ((xLocation != -1) && (yLocation != -1)) {
          if ((trackingmsg->xLocation != 0) && (trackingmsg->yLocation != 0)) {
            receivedXLocation = trackingmsg->xLocation - 1;
            receivedYLocation = trackingmsg->yLocation - 1;
            if (((receivedXLocation % 5) == 0) && ((receivedYLocation % 5) == 0)) {
              if ((((receivedXLocation - xLocation) * (receivedXLocation - xLocation)) + 
                   ((receivedYLocation - yLocation) * (receivedYLocation - yLocation))) 
                  < NBRS_RADIUS) {
                nbrs[currentNumNbrs] = trackingmsg->origin;
                transitionProbs[currentNumNbrs] = .2; // XXX: Not correct, but simple.
                currentNumNbrs++;
              }
            }
          }
        }
      }
    }
#endif
    return m;
  }  

  event TOS_MsgPtr ReceiveBacktrackingMsg.receive(TOS_MsgPtr m) {
    int i;
    BacktrackingMsg *backtrackingmsg = (BacktrackingMsg *) &m->data[0];
    if (backtrackingmsg->backtrackingTime == backtrackingTime) {
      if (mapNodeIDToIndex(backtrackingmsg->origin) != 0xffff) {
#if 0
        // not necessary if the addr field is correct (i.e. not 65535):
        if (backtrackingmsg->track[trackLength - (backtrackingTime + 2)] == TOS_LOCAL_ADDRESS) {
#endif
          numNbrsReportedBacktracking++;        
          nbrBacktrackingDeltas[mapNodeIDToIndex(backtrackingmsg->origin)] = backtrackingmsg->delta;
#if 0
          for (i = 1; i <= backtrackingTime + 2; i++) {
            nbrBacktrackingTracks[mapNodeIDToIndex(backtrackingmsg->origin)][trackLength - i] = \
              backtrackingmsg->track[trackLength - i];
          }
#else
          for (i = trackLength - (backtrackingTime + 1); i <= trackLength - 1; i++) {
            nbrBacktrackingTracks[mapNodeIDToIndex(backtrackingmsg->origin)][i] = \
              backtrackingmsg->track[i];
              //backtrackingmsg->track[trackLength - i];
          }
#endif
#if 0
        }
#endif
      }
    }
    return m;
  }

#ifdef USE_BACKTRACKING_BACKOFF
  event result_t BacktrackingBackoffTimer.fired() {
    post SendBacktrackingMsgTask();
    return SUCCESS;
  }
#endif

#ifdef USE_TRACKING_BACKOFF
  event result_t TrackingBackoffTimer.fired() {
    post BcastDeltasTask();
    return SUCCESS;
  }
#endif

  event result_t BacktrackingTimer.fired() {
    ReportTrackMsg *reporttrackmsg;
    BacktrackingMsg *backtrackingmsg = (BacktrackingMsg *) &backtrackingMsgBuffer.data[0];
    uint16_t Len;
    int i,j;
    uint8_t bestTrack = 0;
    float bestBacktrackingDelta = logf(0);
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
    BacktrackingDebugMsg *backtrackingdebugmsg = \
      (BacktrackingDebugMsg *) &backtrackingDebugMsgBuffer.data[0];
    for (i = 0; i < sizeof(BacktrackingDebugMsg); i++) {
      backtrackingDebugMsgBuffer.data[i] = 0;
    }
#endif
    backtrackingTime++;
    if (backtrackingTime >= trackLength) {
      call BacktrackingTimer.stop();
      call TrackingTimer.stop(); // XXX: Shouldn't be needed, but also shouldn't hurt.
#ifdef USE_TOSBASE_AS_HEARTBEAT
      // Do nothing and wait for the TOSBase to send a cmd.
#else
      initiateTracking();
#endif
      return SUCCESS;
    }
#ifdef CALCULATE_NEIGHBORS_BY_DISTANCE
    if (currentNumNbrs == 1) {
      return SUCCESS;
    }
#endif
    if (numNbrsReportedBacktracking > 0) {
      backtrackingmsg->numNbrsReportedBacktracking = numNbrsReportedBacktracking;
      numNbrsReportedBacktracking = 0;
      for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
        if (bestBacktrackingDelta < nbrBacktrackingDeltas[i]) {
          bestTrack = i;
          bestBacktrackingDelta = nbrBacktrackingDeltas[i];
        }
      }    
      if (backtrackingTime >= trackLength - 1) {
        reporttrackmsg = (ReportTrackMsg *) call ReportTrackSend.getBuffer(&reportTrackMsgBuffer,&Len);
        for (i = 1; i < MAX_LOCATIONS_PER_MESSAGE; i++) {
          if (i < trackLength) {
            reporttrackmsg->track[i] = nbrBacktrackingTracks[bestTrack][i];
          } else {
            reporttrackmsg->track[i] = 0xffff;
          }
        }
        reporttrackmsg->track[0] = TOS_LOCAL_ADDRESS;
        reporttrackmsg->seqNo = bcastSeqNo;
        reporttrackmsg->delta = bestTrackingDelta;
        post ReportTrackTask();
        return SUCCESS;
      } 
      // here backtrackingTime < trackLength - 1
      // Clear out backtrackingmsg->track:
      for (i = 0; i < trackLength; i++) {
        backtrackingmsg->track[i] = 0xffff;
      }
      // Copy over the best track received, which includes this
      // node's address at the index trackLength - backtrackingTime:
      for (i = trackLength - backtrackingTime; i <= trackLength - 1; i++) {
        backtrackingmsg->track[i] = nbrBacktrackingTracks[bestTrack][i];
      }
      backtrackingmsg->track[trackLength - (backtrackingTime + 1)] = TOS_LOCAL_ADDRESS;
#if 1
      backtrackingmsg->track[trackLength - (backtrackingTime + 2)] = \
        track[trackLength - (backtrackingTime + 1)];
#endif
      backtrackingmsg->delta = bestBacktrackingDelta;
      backtrackingmsg->backtrackingTime = backtrackingTime;
      for (i = 0; i < MAX_NBRHOOD_SIZE + 1; i++) {
        nbrBacktrackingDeltas[i] = logf(0);
        for (j = 0; j < trackLength; j++) {
          nbrBacktrackingTracks[i][j] = 0xffff;
        }
      }
#ifdef DO_NOT_SUPPRESS_EXTRA_BACKTRACKING_MSGS
      if (track[trackLength - (backtrackingTime + 1)] == TOS_LOCAL_ADDRESS) {
        numNbrsReportedBacktracking = 1;
        for (i = 1; i <= backtrackingTime + 1; i++) {
          nbrBacktrackingTracks[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)][trackLength - i] = \
            backtrackingmsg->track[trackLength - i];
        }
        nbrBacktrackingDeltas[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)] = backtrackingmsg->delta;
      }
#ifdef USE_BACKTRACKING_BACKOFF
      SendBacktrackingMsgTaskDelayed();
#else
      post SendBacktrackingMsgTask();
#endif
#else
      if (track[trackLength - (backtrackingTime + 1)] == TOS_LOCAL_ADDRESS) {
        numNbrsReportedBacktracking = 1;
        for (i = 1; i <= backtrackingTime + 1; i++) {
          nbrBacktrackingTracks[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)][trackLength - i] = \
            backtrackingmsg->track[trackLength - i];
        }
        nbrBacktrackingDeltas[mapNodeIDToIndex(TOS_LOCAL_ADDRESS)] = backtrackingmsg->delta;
      } else {
#ifdef USE_BACKTRACKING_BACKOFF
        SendBacktrackingMsgTaskDelayed();
#else
        post SendBacktrackingMsgTask();
#endif
      }
#endif
    }
#ifdef SEND_BACKTRACKING_DEBUG_MSGS
    for (i = 0; i < trackLength; i++) {
      backtrackingdebugmsg->track[i] = backtrackingmsg->track[i];
    }
    backtrackingdebugmsg->time = backtrackingTime;
    backtrackingdebugmsg->origin = TOS_LOCAL_ADDRESS;
    post SendBacktrackingDebugMsgTask();
#endif    
    return SUCCESS;
  }

#ifdef SEND_BACKTRACKING_DEBUG_MSGS
  event result_t SendBacktrackingDebugMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    radioBusy = FALSE;
    return SUCCESS;
  }
#endif

#ifdef SEND_TRACKING_DEBUG_MSGS
  event result_t SendTrackingDebugMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    radioBusy = FALSE;
    return SUCCESS;
  }
#endif

  event result_t ReportTrackSend.sendDone(TOS_MsgPtr msg, result_t success) {
    radioBusy = FALSE;
    return SUCCESS;
  }

  event result_t ReportTrackSendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    radioBusy = FALSE;
    return SUCCESS;
  }

#ifdef USE_DRIP
  event result_t FloodTrackingCmd.rebroadcastRequest(TOS_MsgPtr msg, void *pData) {
    memcpy(pData, 
           &trackingCmdMsgBuffer, 
           sizeof(TOS_Msg) - TOSH_DATA_LENGTH + sizeof(DistributedTrackingingCmdMsg));
    call FloodTrackingCmd.rebroadcast(msg, pData, sizeof(TrackingCmdMsg));
  }
  // ... do something else for Drip?
#endif

  event result_t FloodTrackingCmd.sendDone(TOS_MsgPtr msg, result_t success) {
    TOS_BcastMsg *bcastmsg = (TOS_BcastMsg *) &msg->data[0];
    TrackingCmdMsg* trackingcmdmsg = (TrackingCmdMsg *) &bcastmsg->data[0];
    radioBusy = FALSE;
    if (trackingcmdmsg->requester == TOS_LOCAL_ADDRESS) {
      if (trackingcmdmsg->cmd == SINGLE_BACKTRACK) {
        post StartBacktrackingTask();
      } else if (trackingcmdmsg->cmd == START_TRACKING) {
        initiateTracking();
      }
    }
    return SUCCESS;
  }

#ifndef USE_TOSBASE_AS_HEARTBEAT
  event result_t CheckOnTimeSyncValidityTimer.fired() {
    TrackingCmdMsg *trackingcmdmsg;
    TOS_BcastMsg *bcastmsg = (TOS_BcastMsg *) &trackingCmdMsgBuffer.data[0];
    trackingcmdmsg = (TrackingCmdMsg *) &bcastmsg->data[0];
    call CheckOnTimeSyncValidityTimer.stop();
    if (TOS_LOCAL_ADDRESS == NODE_ID_SHIFT) {
      trackingcmdmsg->cmd = START_TRACKING;
      post FloodTrackingCmdTask();
    }
    return SUCCESS;
  }
#endif

}
