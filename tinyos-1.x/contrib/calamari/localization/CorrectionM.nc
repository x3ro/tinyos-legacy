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
includes Neighborhood;
includes AnchorHood;

//!! Config 107 { location_t uncorrectedLocation = { pos:{x:65535u, y:65535u }, stdv:{x:65535u, y:65535u}}; }

//!! UncorrectedDistanceAttr = CreateAttribute( distance_t = {distance:0, stdv:65535u} );
//!! UncorrectedDistanceRefl = CreateReflection( AnchorHood, UncorrectedDistanceAttr, FALSE, 235, 236 );

//!! GetCorrectionsCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Void_t, 96, 97 );

module CorrectionM
{
  provides
  {
    interface StdControl;
    interface Correction;
  }
  uses
  {
    interface LocationAttr;
    interface LocationAttrReflection as LocationRefl;
    interface DistanceAttrReflection as DistanceRefl; //this is defined in the ranging component that you use
    interface Neighborhood as AnchorHood;

    interface UncorrectedDistanceAttr;
    interface StdControl as UncorrectedDistanceAttrControl;
    interface UncorrectedDistanceAttrReflection as UncorrectedDistanceRefl;
    interface GetCorrectionsCmd;	

    interface Localization;

    interface ReceiveMsg;
    interface SendMsg;
    interface SendMsg as CorrectionReportSendMsg;
    interface DiagMsg;
    interface Leds;
    interface Timer;
    interface Random;
  }
}

implementation
{

  bool locEquals(location_t loc1, location_t loc2);
  bool distEquals(distance_t loc1, distance_t loc2);
  
  TOS_Msg msgBuffer; //isn't there a better way to do this, now?
  correction_t correctionFactor[MAX_MEMBERS_AnchorHood];
  uint8_t numCorrectionFactors;
  uint8_t numRetriesLeft;
  bool timerSet;
  bool sendPending;
  bool toBeRebroadcast;

  typedef struct{
    uint8_t src;
    uint8_t numCorrectionFactors;
    correction_t correctionFactor[MAX_MEMBERS_AnchorHood];
  } CorrectionMsg;
  
  command result_t StdControl.init()
    {
      int i;
      for(i=0;i<MAX_MEMBERS_AnchorHood;i++){
	correctionFactor[i].sourceAnchor=255u;
	correctionFactor[i].correctedAnchor=255u;
	correctionFactor[i].correction=65535u;
      }
      numCorrectionFactors=0;
      numRetriesLeft=0;
      timerSet=FALSE;
      sendPending=FALSE;
      toBeRebroadcast=TRUE;
      call UncorrectedDistanceAttrControl.init();
      return SUCCESS;
    }

  command result_t StdControl.start()
    {
      call UncorrectedDistanceAttrControl.start();
      return SUCCESS;
    }

  command result_t StdControl.stop() {
    call UncorrectedDistanceAttrControl.stop();
    return SUCCESS;
  }

  float inline square(float f){ return f*f;}

  void correctLocation (){
    int i,j;
    nodeID_t anchorID;
    uint16_t correction;
    distance_t newDistance, oldDistance;
    //make sure that uncorrectedLocation is set
    if(locEquals(G_Config.uncorrectedLocation, G_DefaultConfig.uncorrectedLocation)){
      G_Config.uncorrectedLocation=G_Config.LocationInfo.localizedLocation;
    }
    
    for(i=0;i<call AnchorHood.numNeighbors();i++){
      anchorID = call AnchorHood.getNeighbor(i);
      //make sure that all UncorrectedDistanceRefl are set
      if(distEquals(call UncorrectedDistanceRefl.get(anchorID),G_default_node_AnchorHood.data_UncorrectedDistanceRefl)){
	call UncorrectedDistanceRefl.scribble(anchorID, call DistanceRefl.get(anchorID));
      }
      //Choose correction factor
      correction=32768u;
      for(j=0;j<numCorrectionFactors;j++){
	if(correctionFactor[j].correctedAnchor==anchorID){
	  correction=correctionFactor[j].correction;
	}
      }
      //set DistanceRefl to UncorrectedDistance*correction
      oldDistance = call UncorrectedDistanceRefl.get(anchorID);
      newDistance.distance = (uint16_t) (oldDistance.distance * (correction/32768.0));
      newDistance.stdv=oldDistance.stdv;
      call DistanceRefl.scribble(anchorID, newDistance);
    }
    
    //run multilateration
    call Localization.estimateLocation();
  }

  event result_t Timer.fired(){
    if(sendPending==TRUE) return SUCCESS;
    if(numRetriesLeft > 0){
      call Correction.sendCorrectionsNow();
    } else {
      call Timer.stop();
      timerSet=FALSE;
    }
    return SUCCESS;
  }

  command void Correction.reset() {
    int i;
    nodeID_t anchorID;
    numRetriesLeft=0;
    call Timer.stop();
    timerSet=FALSE;
    call StdControl.init();
    
    if(!locEquals(G_Config.uncorrectedLocation, G_DefaultConfig.uncorrectedLocation)){
      G_Config.LocationInfo.localizedLocation = G_Config.uncorrectedLocation;
    }
    
    for(i=0;i<call AnchorHood.numNeighbors();i++){
      anchorID = call AnchorHood.getNeighbor(i);
      if(!distEquals(call UncorrectedDistanceRefl.get(anchorID),G_default_node_AnchorHood.data_UncorrectedDistanceRefl)){
	call DistanceRefl.scribble(anchorID, call UncorrectedDistanceRefl.get(anchorID));
      }
    }    
  }

  command void Correction.calculateCorrections() {
    if(G_Config.LocationInfo.isAnchor){
      int i;
      nodeID_t anchorID;
      location_t anchorLocation; 
      distance_t anchorDistance;
      float trueDistance;
      numCorrectionFactors=0;
      for(i=0;i<call AnchorHood.numNeighbors();i++){
	anchorID = call AnchorHood.getNeighbor(i);
	anchorLocation = call LocationRefl.get(anchorID);
	anchorDistance = call DistanceRefl.get(anchorID);
	trueDistance = sqrt( square((float)G_Config.LocationInfo.localizedLocation.pos.x-(float)anchorLocation.pos.x)
			     +square((float)G_Config.LocationInfo.localizedLocation.pos.y-(float)anchorLocation.pos.y));
	correctionFactor[i].sourceAnchor=(uint8_t)TOS_LOCAL_ADDRESS;
	correctionFactor[i].correctedAnchor=(uint8_t)anchorID;
	if(anchorID != TOS_LOCAL_ADDRESS)
	  correctionFactor[i].correction = (uint16_t) ((trueDistance/anchorDistance.distance)*32768u);
	else // send out "1" for yourself
	  correctionFactor[i].correction = 32768u;
	numCorrectionFactors++;
      }
    }
  }

  float min(float a, float b){
    return a<b?a:b;
  }

  command void Correction.stop() {
    numRetriesLeft=0;
    call Timer.stop();
    timerSet=FALSE;
  }

  command void Correction.startSendingCorrections() {
    numRetriesLeft = G_Config.txRetry;
    call Timer.start(TIMER_REPEAT, G_Config.txDelay +  (call Random.rand() & G_Config.txDelayMask));
    timerSet=TRUE;
  }

  command void Correction.sendCorrectionsNow() {
    uint8_t i;
    CorrectionMsg* cMsg = (CorrectionMsg*)(&(msgBuffer.data));
    if(G_Config.LocationInfo.isAnchor){
      call Correction.calculateCorrections();
    }
    cMsg->src = (uint8_t) TOS_LOCAL_ADDRESS;
    cMsg->numCorrectionFactors=(uint8_t)min((float)numCorrectionFactors, 27.0/sizeof(correction_t));
    //send out all correction factors
    if(cMsg->numCorrectionFactors==0) return;
    for(i=0;i<cMsg->numCorrectionFactors;i++){
      cMsg->correctionFactor[i]=correctionFactor[i];
    }
    if(toBeRebroadcast==FALSE){
      if(call CorrectionReportSendMsg.send(TOS_BCAST_ADDR,sizeof(CorrectionMsg), &msgBuffer) == SUCCESS){
	sendPending==TRUE;
      }
    }
    else { //this send is the default
      if(call SendMsg.send(TOS_BCAST_ADDR,sizeof(CorrectionMsg), &msgBuffer) == SUCCESS){
	sendPending==TRUE;
      }
    }
    toBeRebroadcast=TRUE;
  }

  void reportCorrections() {
    toBeRebroadcast=FALSE;
    call Correction.sendCorrectionsNow();
  }


  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    bool alreadyExists;
    uint8_t i,j;
    distance_t d;
    uint16_t distanceToExistingAnchor, distanceToNewAnchor;
    CorrectionMsg* cMsg = (CorrectionMsg*)(&(msg->data));
    //check out all correction factors and see if I want them
    if(timerSet==TRUE){
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, G_Config.txDelay +  (call Random.rand() & G_Config.txDelayMask));
    }
    if(G_Config.LocationInfo.isAnchor) return msg;
    for(i=0;i<cMsg->numCorrectionFactors;i++){
      alreadyExists=FALSE;
      //if both the source and the corrected anchors are in my anchor hood
      if(call AnchorHood.isNeighbor((uint16_t)cMsg->correctionFactor[i].sourceAnchor) &&
	 call AnchorHood.isNeighbor((uint16_t)cMsg->correctionFactor[i].correctedAnchor)){
	for(j=0;j<numCorrectionFactors;j++){
	  //if I already have a correction for this anchor, see if
	  //this one is from a closer anchor
	  if(correctionFactor[j].correctedAnchor == ((uint16_t)cMsg->correctionFactor[i].correctedAnchor)){
	    d=call UncorrectedDistanceRefl.get((uint16_t)correctionFactor[j].sourceAnchor);
	    distanceToExistingAnchor=d.distance;
	    d=call UncorrectedDistanceRefl.get((uint16_t)cMsg->correctionFactor[i].sourceAnchor);
	    distanceToNewAnchor=d.distance;
	    if(distanceToNewAnchor < distanceToExistingAnchor){
	      correctionFactor[j]=cMsg->correctionFactor[i];
	      numRetriesLeft = G_Config.txRetry;
	      if(timerSet==FALSE){
		call Timer.start(TIMER_REPEAT, G_Config.txDelay +  (call Random.rand() & G_Config.txDelayMask));
		timerSet=TRUE;
	      }
	      correctLocation();
	    }
	    alreadyExists=TRUE;
	    break;
	  }
	}
	//if this correction doesn't already exist, see if there is space
	if(numCorrectionFactors<MAX_MEMBERS_AnchorHood && alreadyExists==FALSE){
	  correctionFactor[numCorrectionFactors++]=cMsg->correctionFactor[i];
	  numRetriesLeft = G_Config.txRetry;
	  if(timerSet==FALSE){
	    call Timer.start(TIMER_REPEAT, G_Config.txDelay +  (call Random.rand() & G_Config.txDelayMask));
	    timerSet=TRUE;
	  }
	  correctLocation();
	}
      }	  
    }
    return msg;
  }  

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success){
    numRetriesLeft--;
    sendPending=FALSE;
    return SUCCESS;
  }

  event result_t CorrectionReportSendMsg.sendDone(TOS_MsgPtr msg, result_t success){
    sendPending=FALSE;
    return SUCCESS;
  }

  
  event void GetCorrectionsCmd.receiveCall( GetCorrectionsCmdArgs_t args ) {
    reportCorrections();
    call GetCorrectionsCmd.dropReturn();
  }
  event void GetCorrectionsCmd.receiveReturn( nodeID_t node, GetCorrectionsCmdReturn_t rets ) {} 

  event void LocationAttr.updated( ){
  }
 
  event void LocationRefl.updated( nodeID_t id, location_t value ){
  }
 
  event void DistanceRefl.updated( nodeID_t id, distance_t value ){
  }
 
  event void AnchorHood.removingNeighbor( nodeID_t id ){}
  event void AnchorHood.addedNeighbor( nodeID_t id ){}

  event void UncorrectedDistanceAttr.updated( ){
  }
 
  event void UncorrectedDistanceRefl.updated( nodeID_t id, distance_t value ){
  }

  bool locEquals(location_t loc1, location_t loc2){
    if(loc1.pos.x==loc2.pos.x &&
       loc1.pos.y == loc2.pos.y &&
       loc1.stdv.x == loc2.stdv.x &&
       loc1.stdv.y == loc2.stdv.y)
      return TRUE;
    else
      return FALSE;
  }
  bool distEquals(distance_t loc1, distance_t loc2){
    if(loc1.distance==loc2.distance &&
       loc1.stdv == loc2.stdv)
      return TRUE;
    else 
      return FALSE;
  }

}















