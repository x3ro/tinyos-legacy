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

//!! CalamariSetRangingCmd = CreateCommand[SystemCommand]( CommandHood, RangingSetMsg_t, Void_t, 58, 59 );
// !! CalamariSetRangingCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 58, 59 );

//!! CalamariToggleLedCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 60,61 );

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

//!! CalamariSendAllAnchorsCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 90, 91 );

//!! CalamariReportRangingValuesCmd = CreateCommand[SystemCommand]( CommandHood, uint16_t, Void_t, 92, 93 );

//!! CalamariRangingExchangeCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 94, 95 );

// 96, 97 used for GetCorrectionsCmd in CorrectionM.nc



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
    interface ShortestPathNodeAttrReflection as ShortestPathNodeRefl;
    interface RangingMovingWindowAttrReflection as RangingMovingWindowRefl;
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
    interface CalamariReportRangingValuesCmd;    
    interface CalamariStopCmd;
    interface CalamariStartCmd;
    interface CalamariResumeCmd;
    interface CalamariRangingCmd;
    interface CalamariRangingExchangeCmd;
    interface CalamariResetRangingCmd;
    interface CalamariShortestPathCmd;
    interface CalamariSendAllAnchorsCmd;
    interface CalamariResetShortestPathCmd;
    interface CalamariLocalizationCmd;
    interface CalamariResetLocalizationCmd;
    interface CalamariCorrectionCmd;
    interface CalamariResetCorrectionCmd;	
    interface CalamariToggleLedCmd;	
    interface CalamariSetRangingCmd;	
    command void setRanging( RangingSetMsg_t args );

    interface DiagMsg;

    interface SendMsg as RangingReportSend;
    interface SendMsg as RangingValuesSend;
    interface SendMsg as AnchorReportSend;
	
    interface MsgBuffers;
  }
}

implementation
{
  enum {
    STATE_IDLE,
    STATE_RANGING,
    STATE_RANGING_EXCHANGE,
    STATE_RANGING_ONCE,
    STATE_SHORTEST_PATH,
    STATE_LOCALIZATION,
    STATE_CORRECTION
  };
    
  uint8_t state;
  uint8_t oldState;
  uint16_t oldTimerRate;
  
  TOS_Msg msg;
  uint8_t rangingValueReportIndex;
  uint8_t rangingValueReportNeighborIndex;
  uint8_t rangingValueReportType;

  bool timerSet = FALSE;
  bool timerWasSet = FALSE;

  uint8_t rangingNeighborsLeft = 0;
  bool rangingReportPending = FALSE;
  uint8_t anchorsLeft = 0;
  bool anchorReportPending = FALSE;
  
  task void doLocalization() {
    dbg(DBG_USR2,"CALAMARI : telling localization to calculate location estimate\n");
    call Localization.estimateLocation();
  }

  task void pushManagementInfo() {
    dbg(DBG_USR3, "CALAMARI: pushing anchor info\n");
    call AnchorHood.refresh();
  }

  task void sendAllAnchorsTask() {
    dbg(DBG_USR3, "CALAMARI: sending all anchor info\n");
    call AnchorInfoPropagation.sendAllAnchors();
  }

  command result_t StdControl.init() {
    state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    //    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    timerSet = FALSE;
    return call Timer.stop();
  }
  
  event result_t Timer.fired() {
    timerSet = FALSE;
    if(state == STATE_RANGING_EXCHANGE) {
      state = STATE_SHORTEST_PATH;
      post pushManagementInfo();
    } else if(state == STATE_SHORTEST_PATH) {
      state = STATE_IDLE;
      post doLocalization();
    }
    return SUCCESS;
  }

  event void AnchorInfoPropagation.overheardManagementMsg() {
    if(state == STATE_SHORTEST_PATH){
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT,G_Config.shortestPathTimeout);
    }
  }
  
  event void ShortestPathNodeRefl.updated(nodeID_t id, uint16_t value) {
    if(state==STATE_IDLE){
      state = STATE_SHORTEST_PATH;
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT,G_Config.shortestPathTimeout);
    }
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
    if(state == STATE_RANGING){
	call RangingControl.stop(); //is this the right thing to do, Chris?
      } else if (state == STATE_SHORTEST_PATH) {
	call AnchorInfoPropagation.stop();
	//	oldTimerRate=(call Random.rand() & G_Config.managementTimerMask) + G_Config.managementTimerBase;
      } else if (state == STATE_CORRECTION) {
	call Correction.stop();
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
      if(state == STATE_RANGING)
	call RangingControl.range();
      if(!timerSet && timerWasSet) {
	call Timer.start(TIMER_ONE_SHOT,oldTimerRate);
	timerSet = TRUE;
      }
      call CalamariResumeCmd.dropReturn();
    }
  }

  event result_t RangingControl.rangingDone(result_t result) {
    if(!G_Config.initiateSchedule) {
      state = STATE_IDLE;
    } else if(G_Config.LocationInfo.isAnchor){
      state = STATE_RANGING_EXCHANGE;
      call Timer.start(TIMER_ONE_SHOT,G_Config.RangingExchangeParameters.anchorExchangeTimeout);
    } else { // not an anchor. get ready for shortest path
      state = STATE_SHORTEST_PATH;
    }
    return SUCCESS;
  }

  event result_t RangingControl.rangingOverheard() {
    if(G_Config.LocationInfo.isAnchor && state == STATE_RANGING_EXCHANGE) {
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT,G_Config.RangingExchangeParameters.anchorExchangeTimeout);
    }
    return SUCCESS;
  }

  
  event void CalamariResetRangingCmd.receiveCall( CalamariResetRangingCmdArgs_t args) {
    call Timer.stop();
    call RangingControl.reset();
    state = STATE_IDLE;
     call CalamariResetRangingCmd.dropReturn();
  }
  
  event void CalamariRangingCmd.receiveCall( CalamariRangingCmdArgs_t args ) {
    call Leds.redToggle();
    state = STATE_RANGING;
    call RangingControl.range();
    if( call DiagMsg.record() == SUCCESS && G_Config.rangingDebug ) {
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

  event void CalamariRangingExchangeCmd.receiveCall( CalamariRangingExchangeCmdArgs_t args ) {
    call Leds.redToggle();
    state = STATE_RANGING_EXCHANGE;
    call RangingControl.rangingExchange();
    call CalamariRangingExchangeCmd.dropReturn();
  }

  
  event void CalamariShortestPathCmd.receiveCall( CalamariShortestPathCmdArgs_t args ) {
    state=STATE_SHORTEST_PATH;
    //when this command is called, only the anchors send info.  when
    //the other nodes receive it, they signal initiateAnchorPropagation
    if(G_Config.LocationInfo.isAnchor){
      post pushManagementInfo();
    }
    call CalamariShortestPathCmd.dropReturn();
  }

  event void CalamariSendAllAnchorsCmd.receiveCall( CalamariSendAllAnchorsCmdArgs_t args ) {
    state=STATE_SHORTEST_PATH;
    post sendAllAnchorsTask();
    call CalamariSendAllAnchorsCmd.dropReturn();
  }


  event void CalamariResetShortestPathCmd.receiveCall( CalamariResetShortestPathCmdArgs_t args ) {
    call Timer.stop();
    state = STATE_IDLE;
    call AnchorInfoPropagation.reset();
    call CalamariResetShortestPathCmd.dropReturn();
  }

  event void CalamariLocalizationCmd.receiveCall( CalamariLocalizationCmdArgs_t args ) {
    post doLocalization();
    call CalamariLocalizationCmd.dropReturn();
  }
  event void CalamariResetLocalizationCmd.receiveCall( CalamariResetLocalizationCmdArgs_t args ) {
    call Localization.resetLocation();
    call LocalizationStdControl.stop();
    call LocalizationStdControl.start();
    call CalamariResetLocalizationCmd.dropReturn();
  }

  event void CalamariCorrectionCmd.receiveCall( CalamariCorrectionCmdArgs_t args ) {
    //when this command is called, only the anchors send info.  when
    //the other nodes receive it, they signal initiateAnchorPropagation
    if(G_Config.LocationInfo.isAnchor){
      state=STATE_CORRECTION;
      call Correction.startSendingCorrections();
    }
    call CalamariCorrectionCmd.dropReturn();
  }
  event void CalamariResetCorrectionCmd.receiveCall( CalamariResetCorrectionCmdArgs_t args ) {
    call Correction.reset();
    call CalamariResetCorrectionCmd.dropReturn();
  }

  event void Correction.sendCorrectionsDone() {
    if( state == STATE_CORRECTION) {
      state=STATE_IDLE;
    }
  }

  event void CalamariToggleLedCmd.receiveCall( CalamariToggleLedCmdArgs_t args ) {
    call Leds.redToggle();
    call CalamariToggleLedCmd.dropReturn();
  }

  event void CalamariSetRangingCmd.receiveCall( CalamariSetRangingCmdArgs_t args ) {
    call Leds.redToggle();
    call setRanging((RangingSetMsg_t)args);
    call CalamariSetRangingCmd.dropReturn();
  }

  /*************** COMMANDS TO REPORT STATE *******************/
  
  task void reportRangingValues() {
    uint8_t i=0,end=0;
    RangingReportValuesMsg_t *report = (RangingReportValuesMsg_t *)msg.data;
    uint16_t actuator = call RangingHood.getNeighbor(rangingValueReportNeighborIndex);
    moving_window_t window = call RangingMovingWindowRefl.get(actuator);

    end=rangingValueReportIndex+MAX_NUM_REPORTED_RANGING_VALUES > window.n ? window.n : rangingValueReportIndex+MAX_NUM_REPORTED_RANGING_VALUES;
        
    report->addr = TOS_LOCAL_ADDRESS;
    report->actuator = actuator;
    report->windowSize = window.n;
    report->firstIndex = rangingValueReportIndex;
    report->numberOfValues = end-rangingValueReportIndex;
    for(i=rangingValueReportIndex;i<rangingValueReportIndex+MAX_NUM_REPORTED_RANGING_VALUES;i++) {
      report->values[i-rangingValueReportIndex] = window.begin[i];
    }
    call RangingValuesSend.send(G_Config.debugAddr, sizeof(RangingReportValuesMsg_t), &msg);

    if(end>=window.n){
      rangingValueReportIndex=0; //start the next neighbor
    }
    else{
      rangingValueReportIndex=end;
    }
  }

  event result_t RangingValuesSend.sendDone(TOS_MsgPtr smsg, result_t success) {
    if(rangingValueReportIndex==0){//we are starting the next neighbor
      rangingValueReportNeighborIndex++;
    }
    if( rangingValueReportIndex>0 || (rangingValueReportNeighborIndex<call RangingHood.numNeighbors() && rangingValueReportType==0)){
      post reportRangingValues();
    }
    return SUCCESS;
  }

  event void CalamariReportRangingValuesCmd.receiveCall( CalamariReportRangingValuesCmdArgs_t args ) {
    uint16_t i,numNeighbors = call RangingHood.numNeighbors();
    rangingValueReportNeighborIndex=255;
    if(args==65535u) {//return all values
      rangingValueReportType=0;
      rangingValueReportNeighborIndex=0;
    }
    else {//only return this node
      rangingValueReportType=1;
      for(i=0;i<numNeighbors;i++){
	if(args==call RangingHood.getNeighbor(i))  {
	  rangingValueReportNeighborIndex=i;
	}
      }
    }
    rangingValueReportIndex=0;
    if(rangingValueReportNeighborIndex!=255){
      post reportRangingValues();
    }
    call CalamariReportRangingValuesCmd.dropReturn();
  }

  task void reportRangingHood() {
    uint16_t numNeighbors = call RangingHood.numNeighbors();
    uint8_t i=0,base=0;
    uint16_t actuator=0;
    distance_t distance;
    uint8_t neighborsThisMessage=0;
    RangingReportMsg_t *report = (RangingReportMsg_t *)msg.data;

    if(!rangingReportPending) {
      rangingNeighborsLeft = call RangingHood.numNeighbors();
    }

    if(rangingNeighborsLeft > MAX_NUM_REPORTED_RANGING_NEIGHBORS) {
      neighborsThisMessage = MAX_NUM_REPORTED_RANGING_NEIGHBORS;
      rangingReportPending = TRUE;
      rangingNeighborsLeft -= MAX_NUM_REPORTED_RANGING_NEIGHBORS;
    } else {
      neighborsThisMessage = rangingNeighborsLeft;
      rangingReportPending = FALSE;
      rangingNeighborsLeft = 0;
    }
        
    report->addr = TOS_LOCAL_ADDRESS;
    report->numberOfNeighbors = neighborsThisMessage;
    base=numNeighbors-rangingNeighborsLeft-neighborsThisMessage;
    for(i=base;i<base+MAX_NUM_REPORTED_RANGING_NEIGHBORS;i++) {
      actuator = call RangingHood.getNeighbor(i);
      distance = call RangingRefl.get(actuator);
      report->neighbors[i-base].addr = (uint8_t) actuator;
      report->neighbors[i-base].dist = distance.distance;
    }
    if(call RangingReportSend.send(G_Config.debugAddr, sizeof(RangingReportMsg_t), &msg) == FAIL) {
      rangingReportPending = FALSE;
      rangingNeighborsLeft = 0;
    }
      
  }

  event result_t RangingReportSend.sendDone(TOS_MsgPtr smsg, result_t success) {
    if(rangingReportPending)
      post reportRangingHood();
    return SUCCESS;
  }

  event result_t RangingControl.sendRangingExchange() {
    post reportRangingHood();
    return SUCCESS;
  }
  
  event void CalamariReportRangingCmd.receiveCall( CalamariReportRangingCmdArgs_t args ) {
    call Leds.redToggle();
    post reportRangingHood();
    call CalamariReportRangingCmd.dropReturn();
  }

  task void reportAnchorHood() {
    uint16_t numAnchors = call AnchorHood.numNeighbors();
    uint8_t i=0,base=0;
    uint8_t anchorsThisMessage=0;
    AnchorReportMsg_t *report = (AnchorReportMsg_t *)msg.data;

    if(!anchorReportPending) {
      anchorsLeft = call AnchorHood.numNeighbors();
    }

    if(anchorsLeft > MAX_NUM_REPORTED_ANCHORS) {
      anchorsThisMessage = MAX_NUM_REPORTED_ANCHORS;
      anchorReportPending = TRUE;
      anchorsLeft -= MAX_NUM_REPORTED_ANCHORS;
    } else {
      anchorsThisMessage = anchorsLeft;
      anchorReportPending = FALSE;
      anchorsLeft = 0;
    }  
      
    report->addr = TOS_LOCAL_ADDRESS;
    report->numberOfAnchors = anchorsThisMessage;
    base=numAnchors-anchorsLeft-anchorsThisMessage;
    for(i=base;i<base+MAX_NUM_REPORTED_ANCHORS;i++) {
      uint16_t anchor = call AnchorHood.getNeighbor(i);
      distance_t anchorDistance=call DistanceRefl.get(anchor);
      uint8_t hopCount = call HopCountRefl.get(anchor);
      uint16_t nextNode = call ShortestPathNodeRefl.get(anchor);
      report->anchors[i-base].addr = (uint8_t)anchor;
      report->anchors[i-base].dist = anchorDistance.distance;
      report->anchors[i-base].nextNode = (uint8_t) nextNode;
      report->anchors[i-base].hopCount = hopCount;
    }
    if(call AnchorReportSend.send(G_Config.debugAddr, sizeof(AnchorReportMsg_t), &msg) == FAIL) {
      anchorReportPending = FALSE;
      anchorsLeft = 0;
    }

  }
  
  event result_t AnchorReportSend.sendDone(TOS_MsgPtr smsg, result_t success) {
    if(anchorReportPending)
      post reportAnchorHood();
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
  event void RangingMovingWindowRefl.updated(nodeID_t id, moving_window_t value) {}
  
  event void CalamariRangeOnceCmd.receiveReturn( nodeID_t node, CalamariRangeOnceCmdReturn_t rets ) {} 
  event void CalamariReportRangingCmd.receiveReturn( nodeID_t node, CalamariReportRangingCmdReturn_t rets ) {}
  event void CalamariReportRangingValuesCmd.receiveReturn( nodeID_t node, CalamariReportRangingValuesCmdReturn_t rets ) {}
  event void CalamariReportAnchorsCmd.receiveReturn( nodeID_t node, CalamariReportAnchorsCmdReturn_t rets ) {}
  event void CalamariStopCmd.receiveReturn( nodeID_t node, CalamariStopCmdReturn_t rets ) {}
  event void CalamariStartCmd.receiveReturn( nodeID_t node, CalamariStartCmdReturn_t rets ) {} 
  event void CalamariResumeCmd.receiveReturn( nodeID_t node, CalamariResumeCmdReturn_t rets ) {} 
  event void CalamariRangingCmd.receiveReturn( nodeID_t node, CalamariRangingCmdReturn_t rets ) {} 
  event void CalamariRangingExchangeCmd.receiveReturn( nodeID_t node, CalamariRangingExchangeCmdReturn_t rets ) {} 
  event void CalamariResetRangingCmd.receiveReturn( nodeID_t node, CalamariResetRangingCmdReturn_t rets ) {} 
  event void CalamariShortestPathCmd.receiveReturn( nodeID_t node, CalamariShortestPathCmdReturn_t rets ) {} 
  event void CalamariSendAllAnchorsCmd.receiveReturn( nodeID_t node, CalamariSendAllAnchorsCmdReturn_t rets ) {} 
  event void CalamariResetShortestPathCmd.receiveReturn( nodeID_t node, CalamariResetShortestPathCmdReturn_t rets ) {} 
  event void CalamariLocalizationCmd.receiveReturn( nodeID_t node, CalamariLocalizationCmdReturn_t rets ) {} 
  event void CalamariResetLocalizationCmd.receiveReturn( nodeID_t node, CalamariResetLocalizationCmdReturn_t rets ) {} 
  event void CalamariCorrectionCmd.receiveReturn( nodeID_t node, CalamariCorrectionCmdReturn_t rets ) {} 
  event void CalamariResetCorrectionCmd.receiveReturn( nodeID_t node, CalamariResetCorrectionCmdReturn_t rets ) {} 
  event void CalamariToggleLedCmd.receiveReturn( nodeID_t node, CalamariToggleLedCmdReturn_t rets ) {} 
  event void CalamariSetRangingCmd.receiveReturn( nodeID_t node, CalamariSetRangingCmdReturn_t rets ) {} 

}
