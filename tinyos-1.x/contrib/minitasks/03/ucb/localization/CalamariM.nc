/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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

// Authors: Kamin Whitehouse

includes common_structs;
includes polynomial; //these should not be necessary (for declared reflections in ranging)
includes moving_average;//these should not be necessary
includes Localization;
includes Routing;
includes Neighborhood;
includes AnchorHood;
includes Timer;
includes Config;

//!! CalamariRangeOnceCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 62, 63 );

//!! CalamariReportAnchorsCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 64, 65 );

//!! CalamariReportRangingCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 66, 67 );

//!! CalamariStopCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 68, 69 );
//!! CalamariStartCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 70, 71 );

//!! CalamariResumeCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 72, 73 );

//!! CalamariRangingCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 74, 75 );

//!! CalamariResetRangingCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 76, 77 );

//!! CalamariShortestPathCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 78, 79 );

//!! CalamariResetShortestPathCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 80, 81 );

//!! CalamariLocalizationCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 82, 83 );

//!! CalamariResetLocalizationCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 84, 85 );

//!! CalamariCorrectionCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 86, 87 );

//!! CalamariResetCorrectionCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 88, 89 );


module CalamariM
{
  provides
  {
    interface StdControl;
  }
  uses
  {

    interface LocationAttrReflection as LocationRefl;
    interface DistanceAttrReflection as DistanceRefl;
    interface RangingAttrReflection as RangingRefl;
    interface HopCountAttrReflection as HopCountRefl;
    interface LocationAttr;

    
    interface Neighborhood as AnchorHood;
    interface Neighborhood as RangingHood;

    interface StdControl as AnchorHoodControl;
    interface StdControl as RangingHoodControl;
    interface StdControl as LocalizationStdControl;

    interface Localization;
    interface Correction;

    interface Random;
    interface Leds;
    interface Timer;

    interface RangingControl;
    interface AnchorInfoPropagation;
    
    interface CalamariRangeOnceCmd;    
    interface CalamariReportAnchorsCmd;
    interface CalamariReportRangingCmd;    
    interface CalamariStopCmd;
    interface CalamariStartCmd;
    interface CalamariResumeCmd;
    interface CalamariRangingCmd;
    interface CalamariResetRangingCmd;
    interface CalamariShortestPathCmd;
    interface CalamariResetShortestPathCmd;
    interface CalamariLocalizationCmd;
    interface CalamariResetLocalizationCmd;
    interface CalamariCorrectionCmd;
    interface CalamariResetCorrectionCmd;	

    interface DiagMsg;

    interface SendMsg as RangingReportSend;
    interface SendMsg as AnchorReportSend;
	
    interface MsgBuffers;
  }
}

implementation
{
  enum {
    STATE_IDLE,
    STATE_RANGING,
    STATE_RANGING_ONCE,
    STATE_SHORTEST_PATH,
    STATE_LOCALIZATION,
    STATE_CORRECTION
  };
    
  uint8_t state;
  uint8_t oldState;
  uint16_t oldTimerRate;
  uint8_t batchNumber=0;
  
  TOS_Msg msg;

  bool timerSet = FALSE;
  bool timerWasSet = FALSE;
  
  task void doLocalization() {
    dbg(DBG_USR2,"CALAMARI : telling localization to calculate location estimate\n");
    call Localization.estimateLocation();
  }

  task void pushCorrectionInfo() {
    dbg(DBG_USR3, "CALAMARI: pushing correction info\n");
    call Correction.sendCorrections();
  }

  task void pushManagementInfo() {
    dbg(DBG_USR3, "CALAMARI: pushing anchor info\n");
    call AnchorHood.refresh();
  }

  command result_t StdControl.init() {
    state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    timerSet = FALSE;
    return call Timer.stop();
  }
  
  event result_t Timer.fired() {
    timerSet = FALSE;
    if (state == STATE_SHORTEST_PATH) {
      post pushManagementInfo();
    } else if (state == STATE_CORRECTION) {
      post pushCorrectionInfo();
    }
    
    return SUCCESS;
  }

  //calling this function means that my correction factors just changed, so
  //I need to re-broadcast them ONCE (barring link failures).
  //I will wait a while to see if they change again, and if not I will
  //just send.
  event void Correction.initiateCorrectionPropagation() {
    if( state != STATE_CORRECTION) {
      state=STATE_CORRECTION;
      if( call DiagMsg.record() == SUCCESS ) {
	call DiagMsg.str("SP/CrctnPhsesClided");
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.send();
      }
    }
    if(timerSet == TRUE){
      call Timer.stop();
    }
    call Timer.start(TIMER_ONE_SHOT,(call Random.rand() & G_Config.managementTimerMask) + G_Config.managementTimerBase);
    timerSet = TRUE;
    
  }

  
  //calling this function means that my shortest path just changed, so
  //I need to re-broadcast it ONCE (barring link failures).
  //I will wait a while to see if it changes again, and if not I will
  //just send.
  event void AnchorInfoPropagation.initiateAnchorPropagation() {
    if( state != STATE_SHORTEST_PATH) {
      state=STATE_SHORTEST_PATH;
      if( call DiagMsg.record() == SUCCESS ) {
	call DiagMsg.str("SP/RgngPhsesClided");
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.send();
      }
    }
    if(timerSet == TRUE){
      call Timer.stop();
    }
    call Timer.start(TIMER_ONE_SHOT,(call Random.rand() & G_Config.managementTimerMask) + G_Config.managementTimerBase);
    timerSet = TRUE;
  }
  
  event void AnchorHood.removingNeighbor( nodeID_t id ){}
  event void AnchorHood.addedNeighbor( nodeID_t id ){}

  //this command has been deprecated
/*    event void CalamariResetCmd.receiveCall( CalamariResetCmdArgs_t args ) { */
/*      /*    call Timer.stop(); */
/*      timerSet = FALSE; */
/*      state = STATE_RANGING; */
/*      call Leds.redToggle(); */
/*      call AnchorHood.purge(); */
/*      call RangingHood.purge(); */
/*      call Localization.resetLocation(); */
/*      call AnchorHoodControl.stop(); */
/*      call RangingHoodControl.stop(); */
/*      call LocalizationStdControl.stop(); */
/*      call AnchorHoodControl.start(); */
/*      call RangingHoodControl.start(); */
/*      call LocalizationStdControl.start();*/
    
/*      if( call DiagMsg.record() == SUCCESS ) { */
/*        call DiagMsg.str("reset deprecated"); */
/*        call DiagMsg.uint16(TOS_LOCAL_ADDRESS); */
/*        call DiagMsg.send(); */
/*      } */
/*      call CalamariResetCmd.dropReturn(); */
/*    } */
  
  event void CalamariStopCmd.receiveCall( CalamariStopCmdArgs_t args ) {
      call Timer.stop();
      timerWasSet=timerSet;
      timerSet = FALSE;
      call Leds.redToggle();
      if(state == STATE_RANGING){
	call RangingControl.stop(); //is this the right thing to do, Chris?
      } else if (state == STATE_SHORTEST_PATH) {
	oldTimerRate=(call Random.rand() & G_Config.managementTimerMask) + G_Config.managementTimerBase;
      } else if (state == STATE_CORRECTION) {
	oldTimerRate=(call Random.rand() & G_Config.managementTimerMask) + G_Config.managementTimerBase;
      }
      oldState=state;
      state = STATE_IDLE;
      if( call DiagMsg.record() == SUCCESS ) {
	call DiagMsg.str("stop");
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.send();
      }
      call CalamariStopCmd.dropReturn();
  }
  
  event void CalamariStartCmd.receiveCall( CalamariStartCmdArgs_t args ) {
    call Leds.redToggle();
    state = STATE_RANGING;
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("start");
      call DiagMsg.uint8(state);
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call Timer.start(TIMER_ONE_SHOT,G_Config.RangingStartDelay.rangingStartDelayBase);
    timerSet = TRUE;
    call CalamariStartCmd.dropReturn();
  }
  
  event void CalamariResumeCmd.receiveCall( CalamariResumeCmdArgs_t args ) {
    call Leds.redToggle();
    if(state==STATE_IDLE){ //if this node didn't "stop" or another cmd was already called on it, don't do anything
      state = oldState;
      if( call DiagMsg.record() == SUCCESS ) {
	call DiagMsg.str("resume");
	call DiagMsg.uint8(state);
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.send();
      }
      if(state == STATE_RANGING && batchNumber <= G_Config.RangingParameters.numberOfBatches)
	call RangingControl.range(batchNumber);
      if(!timerSet && timerWasSet) {
	call Timer.start(TIMER_ONE_SHOT,oldTimerRate);
	timerSet = TRUE;
      }
      call CalamariResumeCmd.dropReturn();
    }
  }

  event result_t RangingControl.rangingDone(result_t result) {
    if(state != STATE_RANGING_ONCE &&
       ++batchNumber <= G_Config.RangingParameters.numberOfBatches) {
      if(state == STATE_RANGING)  // it isn't paused
	call RangingControl.range(batchNumber);
    } else 
      state = STATE_IDLE;
    return SUCCESS;
  }
  
  event void CalamariResetRangingCmd.receiveCall( CalamariResetRangingCmdArgs_t args) {
    call Leds.redToggle();
    call RangingControl.stop();
    state = STATE_IDLE;
    batchNumber = 0;
    call RangingHood.purge();
    call RangingHoodControl.stop();
    call RangingHoodControl.start();
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("range reset");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariResetRangingCmd.dropReturn();
  }
  
  event void CalamariRangingCmd.receiveCall( CalamariRangingCmdArgs_t args ) {
    call Leds.redToggle();
    state = STATE_RANGING;
    batchNumber++;
    call RangingControl.range(batchNumber);
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("range start");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariRangingCmd.dropReturn();
  }

  event void CalamariRangeOnceCmd.receiveCall( CalamariRangeOnceCmdArgs_t args ) {
    call Leds.redToggle();
    state = STATE_RANGING_ONCE;
    call RangingControl.rangeOnce();
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("range once");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariRangeOnceCmd.dropReturn();
  }

  event void CalamariShortestPathCmd.receiveCall( CalamariShortestPathCmdArgs_t args ) {
    state=STATE_SHORTEST_PATH;
    //when this command is called, only the anchors send info.  when
    //the other nodes receive it, they signal initiateAnchorPropagation
    if(G_Config.LocationInfo.isAnchor){
            post pushManagementInfo();
    }
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("ShortestPath");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariShortestPathCmd.dropReturn();
  }

  event void CalamariResetShortestPathCmd.receiveCall( CalamariResetShortestPathCmdArgs_t args ) {
    call Timer.stop();
    timerSet = FALSE;
    call Leds.redToggle();
    call AnchorHood.purge();
    call AnchorHoodControl.stop();
    call AnchorHoodControl.start();
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("reset ShortestPaths");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariResetShortestPathCmd.dropReturn();
  }

  event void CalamariLocalizationCmd.receiveCall( CalamariLocalizationCmdArgs_t args ) {
    post doLocalization();
    call CalamariLocalizationCmd.dropReturn();
  }
  event void CalamariResetLocalizationCmd.receiveCall( CalamariResetLocalizationCmdArgs_t args ) {
    call Leds.redToggle();
    call Localization.resetLocation();
    call LocalizationStdControl.stop();
    call LocalizationStdControl.start();
    
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("reset Localization");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariResetLocalizationCmd.dropReturn();
  }

  event void CalamariCorrectionCmd.receiveCall( CalamariCorrectionCmdArgs_t args ) {
    //when this command is called, only the anchors send info.  when
    //the other nodes receive it, they signal initiateAnchorPropagation
    if(G_Config.LocationInfo.isAnchor){
      call Correction.calculateCorrections();
      post pushCorrectionInfo();
    }
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("Correction");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariCorrectionCmd.dropReturn();
  }
  event void CalamariResetCorrectionCmd.receiveCall( CalamariResetCorrectionCmdArgs_t args ) {
    call Timer.stop();
    timerSet = FALSE;
    call Leds.redToggle();

    call Correction.reset();
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("reset Correction");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.send();
    }
    call CalamariResetCorrectionCmd.dropReturn();
  }

  /*************** COMMANDS TO REPORT STATE *******************/
  
  task void reportRangingHood() {
    uint16_t numNeighbors = call RangingHood.numNeighbors();
    uint8_t i=0;
    uint16_t actuator=0;
    distance_t distance;
    RangingReportMsg_t *report = (RangingReportMsg_t *)msg.data;

    if(numNeighbors > MAX_NUM_REPORTED_RANGING_NEIGHBORS)
      numNeighbors = MAX_NUM_REPORTED_RANGING_NEIGHBORS;
        
    report->addr = TOS_LOCAL_ADDRESS;
    report->numberOfNeighbors = numNeighbors;
    for(i=0;i<numNeighbors;i++) {
      actuator = call RangingHood.getNeighbor(i);
      distance = call RangingRefl.get(actuator);
      report->neighbors[i].addr = (uint8_t) actuator;
      report->neighbors[i].dist = distance.distance;
    }
    call RangingReportSend.send(TOS_BCAST_ADDR, sizeof(RangingReportMsg_t), &msg);
  }

  event result_t RangingReportSend.sendDone(TOS_MsgPtr smsg, result_t success) {
    return SUCCESS;
  }

  event void CalamariReportRangingCmd.receiveCall( CalamariReportRangingCmdArgs_t args ) {
    call Leds.redToggle();
    post reportRangingHood();
    call CalamariReportRangingCmd.dropReturn();
  }

  // UPDATE THIS TO TRANSMIT HOP COUNTS
  task void reportAnchorHood() {
    uint16_t numAnchors = call AnchorHood.numNeighbors();
    uint8_t i=0;
    AnchorReportMsg_t *report = (AnchorReportMsg_t *)msg.data;

    if(numAnchors > MAX_NUM_REPORTED_ANCHORS)
      numAnchors = MAX_NUM_REPORTED_ANCHORS;
        
    report->addr = TOS_LOCAL_ADDRESS;
    report->numberOfAnchors = numAnchors;
    for(i=0;i<numAnchors;i++) {
      uint16_t anchor = call AnchorHood.getNeighbor(i);
      distance_t anchorDistance=call DistanceRefl.get(anchor);
      uint8_t hopCount = call HopCountRefl.get(anchor);
      report->anchors[i].addr = anchor;
      report->anchors[i].hopCount = hopCount;
      report->anchors[i].dist = anchorDistance.distance;
    }
    call AnchorReportSend.send(TOS_BCAST_ADDR, sizeof(AnchorReportMsg_t), &msg);

  }

  event result_t AnchorReportSend.sendDone(TOS_MsgPtr smsg, result_t success) {
    return SUCCESS;
  }

  event void CalamariReportAnchorsCmd.receiveCall( CalamariReportAnchorsCmdArgs_t args ) {
    call Leds.redToggle();
    post reportAnchorHood();
    call CalamariReportAnchorsCmd.dropReturn();
  } 
 
  event void RangingHood.addedNeighbor( nodeID_t id ){}
  event void RangingHood.removingNeighbor( nodeID_t id ){}

  event void LocationAttr.updated() {}
  event void LocationRefl.updated(nodeID_t id, location_t value) {}
  event void DistanceRefl.updated(nodeID_t id, distance_t value) {}
  event void RangingRefl.updated(nodeID_t id, distance_t value) {}
  event void HopCountRefl.updated(nodeID_t id, uint8_t value) {}
  
  event void CalamariRangeOnceCmd.receiveReturn( nodeID_t node, CalamariRangeOnceCmdReturn_t rets ) {} 
  event void CalamariReportRangingCmd.receiveReturn( nodeID_t node, CalamariReportRangingCmdReturn_t rets ) {}
  event void CalamariReportAnchorsCmd.receiveReturn( nodeID_t node, CalamariReportAnchorsCmdReturn_t rets ) {}
  event void CalamariStopCmd.receiveReturn( nodeID_t node, CalamariStopCmdReturn_t rets ) {}
  event void CalamariStartCmd.receiveReturn( nodeID_t node, CalamariStartCmdReturn_t rets ) {} 
  event void CalamariResumeCmd.receiveReturn( nodeID_t node, CalamariResumeCmdReturn_t rets ) {} 
  event void CalamariRangingCmd.receiveReturn( nodeID_t node, CalamariRangingCmdReturn_t rets ) {} 
  event void CalamariResetRangingCmd.receiveReturn( nodeID_t node, CalamariResetRangingCmdReturn_t rets ) {} 
  event void CalamariShortestPathCmd.receiveReturn( nodeID_t node, CalamariShortestPathCmdReturn_t rets ) {} 
  event void CalamariResetShortestPathCmd.receiveReturn( nodeID_t node, CalamariResetShortestPathCmdReturn_t rets ) {} 
  event void CalamariLocalizationCmd.receiveReturn( nodeID_t node, CalamariLocalizationCmdReturn_t rets ) {} 
  event void CalamariResetLocalizationCmd.receiveReturn( nodeID_t node, CalamariResetLocalizationCmdReturn_t rets ) {} 
  event void CalamariCorrectionCmd.receiveReturn( nodeID_t node, CalamariCorrectionCmdReturn_t rets ) {} 
  event void CalamariResetCorrectionCmd.receiveReturn( nodeID_t node, CalamariResetCorrectionCmdReturn_t rets ) {} 

}
