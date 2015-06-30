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
// Date:    5/2/03

/*  This component chooses the N nodes that have the smallest 
	total error for location and ranging estimates.
	These nodes should be useful for localization.
	
	The sum of stdv values for both ranging and localization are used
	as the rank of each node.  Nodes with stdvs within 32cm (1 foot)
	of each other are considered to be the same (for stability and 
	memory savings).

	This component assumes this it is being used for a neighborhood
	that has a distance_t attribute, rssi moving average attribute, 
	location_t attribute and a rssiTxrCalibrationCoefficients attribute.
	The neighborhood it is managing should be called "AnchorHood".
	*/

includes common_structs;
includes polynomial;
includes moving_average;
includes Localization;
includes AnchorHood;
includes MostConfidentMultihopAnchors;

module MostConfidentMultihopAnchorsM
{
  provides
  {
    interface StdControl;
    interface NeighborhoodManager;
    interface AnchorInfoPropagation;
  }
  uses
  {
    interface RankAttrReflection as RankRefl;
    interface ShortestPathNodeAttrReflection as ShortestPathNodeRefl;
    interface ShortestPathAttrReflection as ShortestPathRefl;
    interface Leds;
    interface Random;

    //all of the interfaces below should be defined in your localization and ranging components
    interface LocationAttr;

    interface LocationAttrReflection as LocationRefl;
    interface DistanceAttrReflection as DistanceRefl;
    interface RangingAttrReflection as RangingRefl;
    interface HopCountAttrReflection as HopCountRefl;
    interface RangingCountAttrReflection as RangingCountRefl;
    
    interface TxDelayAttrReflection as TxDelayRefl;
    interface TxRetryAttrReflection as TxRetryRefl;

    interface Neighborhood as AnchorHood;
    interface Neighborhood as RangingHood;
    interface AnchorHood_private;
    interface NeighborhoodComm as ManagementComm;
    interface NeighborhoodComm as ManagementRequestComm;
    interface MsgBuffers;
    interface DiagMsg;
    interface Timer;
  }
}

implementation
{
  bool m_pushTask_pending;
  uint8_t currentAnchorPushed;//APS-specific
//  enum{RANK_THRESHOLD=1300};//set threshold high so we only prune uninitialized nodes
  uint8_t state;

  enum{IDLE=0, PUSHING=1};
  bool reskewingClock;

  typedef struct{
    nodeID_t anchorID;
    location_t location;
    distance_t shortestPath;
    uint8_t hopCount;
//	polynomialD1_t rssiTxrCoeffs;
  } ManagementMsg;

  typedef struct{
    uint16_t src;
    bool isNeighbor;
    nodeID_t anchorID;
    location_t location;
    distance_t shortestPath;
    distance_t rangeToSrc;
    distance_t rangeToAnchor;
    uint16_t rank;
    uint8_t hopCount;
    uint8_t numNeighbors;
  } ManagementMsgDebug;
    
  ManagementMsgDebug debug_m;
  ManagementMsgDebug debug_push;

  TOS_Msg mmsg_push;
  TOS_Msg mmsg_pull;

  
  task void debug_push_t();  
  task void debug_push_rec_t();
  task void push();
  void postPushTask();
  
  command result_t StdControl.init()
  {
    currentAnchorPushed=0;//APS-specific
    m_pushTask_pending=FALSE;
    reskewingClock=FALSE;
    call MsgBuffers.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start(TIMER_REPEAT, G_Config.txAnchorPeriod);
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  //RANK = mean(distance.stdv + location.stdv.x + location.stdv.y)/32
  uint16_t rankNeighbor(AnchorHood_t *neighbor){
//	return (neighbor->data_DistanceRefl.stdv + neighbor->data_LocationRefl.stdv.x + neighbor->data_LocationRefl.stdv.y)/96;
//    return (neighbor->data_DistanceRefl.stdv +neighbor->data_DistanceRefl.distance);
    return neighbor->data_DistanceRefl.distance;
  }

  command void NeighborhoodManager.prune() {
    uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
    for(i=0;i<numNeighbors;i++) {
      nodeID_t neighbor = call AnchorHood.getNeighbor(i);
      if(call RankRefl.get(neighbor) > G_Config.maxAnchorRank){
	call AnchorHood_private.removeID(neighbor);
      }
    }
  }

  void findMaxRankingNeighbor(nodeID_t *maxNode, uint16_t *rank) {
    uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
    uint16_t currRank;
    *maxNode=0;
    if(numNeighbors<MAX_MEMBERS_AnchorHood){ *rank=65535u; return;}
    *rank=0;

    for(i=0;i<numNeighbors;i++){
      nodeID_t neighbor = call AnchorHood.getNeighbor(i);
      currRank=call RankRefl.get(neighbor);
      if(currRank >= *rank){
	*maxNode=neighbor;
	*rank=currRank;
      }
    }
    dbg(DBG_USR2, "CLOSEST_NBR_MGR: max ranking neighbor is node %d with rank %d\n", *maxNode, *rank);
  }

  uint8_t findNextLowestHopCount(){
    nodeID_t anchorID;
    uint8_t min=255,i,numNeighbors=call AnchorHood.numNeighbors();
    //this function finds the lowest hop count of all anchors we are
    //currently trying to send.
    for(i=0;i<numNeighbors;i++){ 
      anchorID=call AnchorHood.getNeighbor(i);
      if(call TxRetryRefl.get (anchorID)>0 && call HopCountRefl.get(anchorID) < min){
	min=call HopCountRefl.get(anchorID);
      }
    }
    return min;
  }

  
  event result_t Timer.fired(){
    nodeID_t anchorID;
    uint8_t nextHop,i,numNeighbors=call AnchorHood.numNeighbors();
    //first, decrement all of the txDelay values for each anchor
    //then, find one that has 0 delay left and more than one retry
    //left, set currentAnchorPushing, and push()    
    if(reskewingClock==TRUE){
      call Timer.start(TIMER_REPEAT, G_Config.txAnchorPeriod);
      reskewingClock=FALSE;
    }
    nextHop=findNextLowestHopCount();
    if(!m_pushTask_pending){
      for(i=0;i<numNeighbors;i++){ 
	anchorID=call AnchorHood.getNeighbor(i);
	if(call TxDelayRefl.get (anchorID)>0 && call HopCountRefl.get(anchorID)==nextHop){ //wave code
	  if(call TxDelayRefl.get (anchorID)<G_Config.txAnchorPeriod){
	    call Timer.stop();
	    call Timer.start(TIMER_ONE_SHOT, call TxDelayRefl.get(anchorID));
	    reskewingClock=TRUE;
	    call TxDelayRefl.scribble(anchorID, 0);
	  }
	  else {
	    call TxDelayRefl.scribble(anchorID, call TxDelayRefl.get (anchorID)-G_Config.txAnchorPeriod );
	  }
	  return SUCCESS;
	}
      }
      for(i=0;i<numNeighbors;i++){ 
	anchorID=call AnchorHood.getNeighbor(i);
	if(call TxDelayRefl.get(anchorID)==0 && call TxRetryRefl.get(anchorID)>0 ){
	  currentAnchorPushed=i;
	  call TxDelayRefl.scribble(anchorID,G_Config.txDelay+ (call Random.rand() & G_Config.txDelayMask));
	  postPushTask();
	  call Leds.redToggle();
	  return SUCCESS;
	}
      }
    }
    return SUCCESS;
  }

  task void push()
  {
    ManagementMsg *managementMsg;
    //TOS_MsgPtr msg = call AnchorHood_private.lockMsgBuffer();
/*      TOS_MsgPtr msg = call MsgBuffers_alloc(); */
    TOS_MsgPtr msg = &mmsg_push;
    m_pushTask_pending = FALSE;
    if(state!=PUSHING) return;
    if( msg != 0 ) {
      managementMsg = (ManagementMsg*)initRoutingMsg( msg, sizeof(ManagementMsg) );
      if( managementMsg != 0 ) {
	debug_push.numNeighbors = call AnchorHood.numNeighbors();
	if( (call AnchorHood.numNeighbors()==0) || (currentAnchorPushed >= call AnchorHood.numNeighbors()) ) {
	  //call AnchorHood_private.unlockMsgBuffer( msg );
/*  	  call MsgBuffers.free( msg ); */
	  if(call DiagMsg.record()==SUCCESS){
	    call DiagMsg.str("AnchrPshFaild1");
	    call DiagMsg.send();
	  }
	  return;
	}
	managementMsg->anchorID=call AnchorHood.getNeighbor(currentAnchorPushed);//APS-specific
	managementMsg->location=call LocationRefl.get(managementMsg->anchorID);//APS-specific
	managementMsg->shortestPath=call DistanceRefl.get(managementMsg->anchorID);//APS-specific
	managementMsg->hopCount=call HopCountRefl.get(managementMsg->anchorID);
	
	debug_push.anchorID = managementMsg->anchorID;
	debug_push.location = managementMsg->location;
	debug_push.shortestPath = managementMsg->shortestPath;
	
//		  managementMsg->rssiTxrCoeffs=call RssiTxrCoeffsAttr.get();
	if(call ManagementComm.send(POTENTIAL_CONEIGHBORS, msg)==SUCCESS){
	  call Leds.redToggle();
	  dbg(DBG_USR3, "CLOSEST_NBR_MGR: sending  management info\n");
	  return;
	} else {
	  //call AnchorHood_private.unlockMsgBuffer( msg );
	  if(call DiagMsg.record()==SUCCESS){
	    call DiagMsg.str("AnchrPshFaild2");
	    call DiagMsg.send();
	  }
	  dbg(DBG_USR3, "CLOSEST_NBR_MGR: ERROR sending  management info\n");
	}
      }
      //call AnchorHood_private.unlockMsgBuffer( msg );
/*        call MsgBuffers.free( msg ); */
    }
  }
  
  void postPushTask() {
    if( m_pushTask_pending == FALSE ) {
      m_pushTask_pending = TRUE;
      state=PUSHING;
      post push();
    }
  }
  
  command void NeighborhoodManager.pushManagementInfo() {
    if(call AnchorHood.isNeighbor(TOS_LOCAL_ADDRESS)){
      call TxRetryRefl.scribble(TOS_LOCAL_ADDRESS,G_Config.txRetry);
      call TxDelayRefl.scribble(TOS_LOCAL_ADDRESS,G_Config.txDelay+ (call Random.rand() & G_Config.txDelayMask));
    }
  }

  command void AnchorInfoPropagation.sendAllAnchors() {
    uint8_t i=0,numAnchors = call AnchorHood.numNeighbors();
    nodeID_t neighbor;
    for(i=0;i<numAnchors;i++){
      neighbor = call AnchorHood.getNeighbor(i);
      call TxRetryRefl.scribble(neighbor,G_Config.txRetry);
      call TxDelayRefl.scribble(neighbor,G_Config.txDelay+ (call Random.rand() & G_Config.txDelayMask));
    }
  }

  command void AnchorInfoPropagation.stop() {
    uint8_t i=0,numAnchors = call AnchorHood.numNeighbors();
    nodeID_t neighbor;
    for(i=0;i<numAnchors;i++){
      neighbor = call AnchorHood.getNeighbor(i);
      call TxRetryRefl.scribble(neighbor,0);
      call TxDelayRefl.scribble(neighbor,0);
    }
  }

  command void AnchorInfoPropagation.reset() {
    call Timer.stop();
    reskewingClock = FALSE;
    call AnchorHood.purge();
    state = IDLE;
    if(G_Config.LocationInfo.isAnchor){
      AnchorHood_t me= G_default_node_AnchorHood;
      me.id = TOS_LOCAL_ADDRESS;
      me.data_DistanceRefl.distance=0;
      me.data_DistanceRefl.stdv=0;
      me.data_ShortestPathNodeRefl=TOS_LOCAL_ADDRESS;
      me.data_LocationRefl = call LocationAttr.get();
      me.data_HopCountRefl = 0;
      call AnchorHood_private.changeID(call AnchorHood.getNeighbor(0), TOS_LOCAL_ADDRESS, &me);
    }
    call Timer.start(TIMER_REPEAT, G_Config.txAnchorPeriod);
  }


  event result_t ManagementComm.sendDone( TOS_MsgPtr msg, result_t success ) {
    //call AnchorHood_private.unlockMsgBuffer( msg );
/*      call MsgBuffers.free(msg); */
    ManagementMsg *managementMsg = (ManagementMsg*)(msg->data);
    if(success==SUCCESS){
      call TxRetryRefl.scribble(managementMsg->anchorID, call TxRetryRefl.get(managementMsg->anchorID)-1);
    }
    call Leds.yellowToggle();
    //    post debug_push_t();
    return SUCCESS;
  }
  
/*  note the following weird semantics:  we can have multiple entries for the same neighbor,
	although each entry must have the shortest path distance to a different anchor.  Furthermore
	the same anchor cannot be in the neighborhood more than once, even if it is through multiple
	neighbors.  I.e. the neighbor is really the anchorID, and it has to have a unique entry.
	We are making the neighbor through which the shortest path is found to be the neighbor because
	that makes it easier to update and keep track of RSSI readings.*/
  void unpackManagementMsg(uint16_t src, TOS_MsgPtr msg ) {
    nodeID_t maxNeighbor;
    uint16_t maxRank,i,numNeighbors=call AnchorHood.numNeighbors(),retn=0;
    AnchorHood_t *oldAnchorInfo, candidate = G_default_node_AnchorHood;
    ManagementMsg *managementMsg = (ManagementMsg*)popFromRoutingMsg( msg, sizeof(ManagementMsg) );
    distance_t rangingData;

    signal AnchorInfoPropagation.overheardManagementMsg();

    //    call Leds.redToggle();
    debug_m.src = src;
    //    post debug_push_rec_t();

    for(i=0;i<numNeighbors;i++) {
      nodeID_t neighbor = call AnchorHood.getNeighbor(i);
      atomic{
	if(call TxRetryRefl.get(neighbor) > 0){
	  //wave code	  
	  if(call HopCountRefl.get(neighbor) > managementMsg->hopCount)
	    call TxDelayRefl.scribble(neighbor, (G_Config.txDelay + G_Config.txDelayMask)*G_Config.managementHopDelay);
	  else
	    call TxDelayRefl.scribble(neighbor, G_Config.txDelay +  (call Random.rand() & G_Config.txDelayMask));
	  //	  retn=1;
	}
      }
	//      if(retn)	  break;
    }

    if(!call RangingHood.isNeighbor(src)) {
      return; //if there is no ranging info, this cannot be a neighbor anchor
    }
    // if there is, see if we have enough ranging readings to feel confident about the ranging data
    rangingData=call RangingRefl.get(src);
    if (rangingData.distance==0) //(call RangingCountRefl.get(src) < G_Config.rangingCountMin) // 0 distance means invalid ranging data
      return;


    candidate.id=managementMsg->anchorID;
    candidate.data_LocationRefl=managementMsg->location;
//	candidate.data_RssiTxrCoeffsRefl=managementMsg->rssiTxrCoeffs;
    candidate.data_ShortestPathRefl=managementMsg->shortestPath;//APS-specific
    candidate.data_ShortestPathNodeRefl=src;//APS-specific
    candidate.data_DistanceRefl.distance=candidate.data_ShortestPathRefl.distance+rangingData.distance;
    candidate.data_DistanceRefl.stdv=candidate.data_ShortestPathRefl.stdv+rangingData.stdv;
    candidate.data_HopCountRefl = managementMsg->hopCount+1;// increment hop count on receive
    candidate.data_TxDelayRefl=G_Config.txDelay +  (call Random.rand() & G_Config.txDelayMask); //if we add this anchor, send it to everybody else, too
    candidate.data_TxRetryRefl=G_Config.txRetry;
    candidate.data_RankRefl=rankNeighbor(&candidate); //rank him, for comparison with the others
    
    debug_m.anchorID = managementMsg->anchorID;
    debug_m.location = managementMsg->location;
    debug_m.shortestPath = managementMsg->shortestPath;
    debug_m.rangeToSrc = rangingData;
    debug_m.rangeToAnchor = candidate.data_DistanceRefl;
    debug_m.hopCount = candidate.data_HopCountRefl;
    debug_m.rank = candidate.data_RankRefl;
	
    dbg(DBG_USR2, "CLOSEST_NBR_MGR: observed potential neighbor %d about %d with location x: %d, xStd: %d, y: %d, yStd: %d, distance: %d, dStdv: %d, and rank: %d\n", src, candidate.id, candidate.data_LocationRefl.pos.x, candidate.data_LocationRefl.stdv.x, candidate.data_LocationRefl.pos.y, candidate.data_LocationRefl.stdv.y, candidate.data_DistanceRefl.distance, candidate.data_DistanceRefl.stdv, candidate.data_RankRefl);

    oldAnchorInfo = call AnchorHood_private.getID(candidate.id);
    // NEED TO DECIDE HOW TO PRUNE OFF ANCHORS TOO FAR AWAY
    if(oldAnchorInfo!=0){
      if(call RankRefl.get(candidate.id) > candidate.data_RankRefl){
	call AnchorHood_private.removeID(candidate.id);
	call AnchorHood_private.addID(candidate.id, &candidate);
	return;
      }
      else{
	return;
      }
    }
	
    if(call AnchorHood.numNeighbors() < MAX_MEMBERS_AnchorHood) {
      call AnchorHood_private.addID(candidate.id, &candidate);
    } else {
      findMaxRankingNeighbor(&maxNeighbor, &maxRank);
      if(candidate.data_RankRefl < maxRank){
	
	call AnchorHood_private.changeID(maxNeighbor, candidate.id, &candidate);
      }
    }

    call NeighborhoodManager.prune();
    return;
  }


  event TOS_MsgPtr ManagementComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    uint8_t i,numNeighbors;
    dbg(DBG_USR2, "got management info msg from neighbor %d\n", src);
    state=IDLE;
    unpackManagementMsg(src, msg);
    dbg(DBG_USR2, "CLOSEST_NBR_MGR: neighborhood: ");
    numNeighbors = call AnchorHood.numNeighbors();
    for(i=0;i<numNeighbors;i++){dbg(DBG_USR2, "%d about %d ", call AnchorHood.getNeighbor(i), call ShortestPathNodeRefl.get(call AnchorHood.getNeighbor(i)));}
    dbg(DBG_USR2, "\n");	
    //Here, I could update anchors using scribble, but that would violate
    //update event semantics
    return msg;
  }
  
  event TOS_MsgPtr ManagementComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
    {
      uint8_t i,numNeighbors;
      dbg(DBG_USR2, "got management info msg from potential neighbor %d\n", src);
      unpackManagementMsg(src.address, msg);
      dbg(DBG_USR2, "CLOSEST_NBR_MGR: neighborhood: ");
      numNeighbors = call AnchorHood.numNeighbors();
      for(i=0;i<numNeighbors;i++) {
	dbg(DBG_USR2, "%d about %d ", call AnchorHood.getNeighbor(i), call ShortestPathNodeRefl.get(call AnchorHood.getNeighbor(i)));
      }
      dbg(DBG_USR2, "\n");	
      return msg;
    }
  
  task void pull()
  {
    //TOS_MsgPtr msg = call AnchorHood_private.lockMsgBuffer();
/*      TOS_MsgPtr msg = call MsgBuffers_alloc(); */
    TOS_MsgPtr msg = &mmsg_pull;
    if( msg != 0 ) {
      if( call ManagementRequestComm.send(POTENTIAL_NEIGHBORS, msg ) == SUCCESS )
	return;
      //call AnchorHood_private.unlockMsgBuffer( msg );
/*        call MsgBuffers.free(msg); */
    }
  }

  command void NeighborhoodManager.pullManagementInfo() {
    post pull() ? SUCCESS : FAIL;
  }

  event result_t ManagementRequestComm.sendDone( TOS_MsgPtr msg, result_t success ) {
    //call AnchorHood_private.unlockMsgBuffer( msg );
/*      call MsgBuffers.free(msg); */
    return SUCCESS;
  }
  
  event TOS_MsgPtr ManagementRequestComm.receive( nodeID_t src, TOS_MsgPtr msg ) {
    return msg;
  }

  event TOS_MsgPtr ManagementRequestComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg ) {
    return msg;
  }
  
  event void LocationAttr.updated() {
/*	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
//        dbg(DBG_USR2, "CLOSEST_NBR_MGR: my location attribute was updated\n");
	for(i=0;i<numNeighbors;i++){
		call RankRefl.scribble(i, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(i))));
		}*/
  }

/*  event void RssiTxrCoeffsAttr.updated( ){
	}*/

//  event void RssiRxrCoeffsAttr.updated( ){
/*	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
//        dbg(DBG_USR2, "CLOSEST_NBR_MGR: my location attribute was updated\n");
	for(i=0;i<numNeighbors;i++){
		call RankRefl.scribble(i, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(i))));
		}*/
//  }

  event void LocationRefl.updated( nodeID_t id, location_t value ){
//	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(id)));
  }

/*  event void RssiRefl.updated( nodeID_t id, ewma_t value ){
  }
*/
  event void RankRefl.updated( nodeID_t id, uint16_t value ){
  }

  event void ShortestPathNodeRefl.updated( nodeID_t id, uint16_t value ){
  }

  event void ShortestPathRefl.updated( nodeID_t id, distance_t value ){
  }

  event void HopCountRefl.updated( nodeID_t id, uint8_t value ){
  }
  
  
/*  event void RssiTxrCoeffsRefl.updated( nodeID_t id, polynomialD1_t value ){
//	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(id))));
}*/

  event void DistanceRefl.updated( nodeID_t id, distance_t value ){
//	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(id))));
  }

  event void RangingRefl.updated( nodeID_t id, distance_t rangingData ){
    distance_t sp, oldDistance, newDistance;
    uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
    uint16_t absVal;
    nodeID_t anchorID;
    for(i=0;i<numNeighbors;i++){
      anchorID=call AnchorHood.getNeighbor(i);
      if(call ShortestPathNodeRefl.get(anchorID)==id){
	sp=call ShortestPathRefl.get(anchorID);
	oldDistance=call DistanceRefl.get(anchorID);
	newDistance.distance=sp.distance+rangingData.distance;
	newDistance.stdv=sp.stdv+rangingData.stdv;
	call DistanceRefl.scribble(anchorID, newDistance);
	call RankRefl.scribble(anchorID, rankNeighbor(call AnchorHood_private.getID(anchorID)));
	absVal = newDistance.distance>oldDistance.distance ? newDistance.distance-oldDistance.distance : oldDistance.distance-newDistance.distance;
	if(absVal > G_Config.deltaDistanceThreshold){
	  call TxRetryRefl.scribble(anchorID,G_Config.txRetry);
	  call TxDelayRefl.scribble(anchorID,G_Config.txDelay +  (call Random.rand() & G_Config.txDelayMask));
	}
      }
    }
  }

  event void RangingCountRefl.updated ( nodeID_t id, uint8_t rangingData ) {
  }
  event void TxRetryRefl.updated ( nodeID_t id, uint8_t retry ) {
  }
  event void TxDelayRefl.updated ( nodeID_t id, uint16_t delay ) {
  }
  
  event void AnchorHood.removingNeighbor( nodeID_t id ){
    dbg(DBG_USR1, "AnchorHood DIRECTED GRAPH: remove edge %d\n", id);
    dbg(DBG_USR1, "ShortestPathConnectivity DIRECTED GRAPH: remove edge %d\n", call ShortestPathNodeRefl.get(id));
  }
  
  event void AnchorHood.addedNeighbor( nodeID_t id ){
    dbg(DBG_USR1, "AnchorHood DIRECTED GRAPH: add edge %d\n", id);
    dbg(DBG_USR1, "ShortestPathConnectivity DIRECTED GRAPH: add edge %d\n", call ShortestPathNodeRefl.get(id));
  }
  
  event void RangingHood.removingNeighbor( nodeID_t id ){
  }
  
  event void RangingHood.addedNeighbor( nodeID_t id ){
  }

  task void debug_push_t()
  {
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("mpush");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      if(debug_push.numNeighbors != 0) {
	call DiagMsg.uint16(debug_push.anchorID);      
	call DiagMsg.uint16(debug_push.location.pos.x);
	call DiagMsg.uint16(debug_push.location.pos.y);
	call DiagMsg.uint16(debug_push.shortestPath.distance);
	call DiagMsg.uint8(debug_push.hopCount);
      }
      call DiagMsg.send();
    }
  }
  
  task void debug_push_rec_t()
  {
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("mrec");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.uint16(debug_m.src);
      //call DiagMsg.boolean(debug_m.isNeighbor);
      if(debug_m.isNeighbor) {
	call DiagMsg.uint16(debug_m.anchorID);      
	call DiagMsg.uint16(debug_m.location.pos.x);
	call DiagMsg.uint16(debug_m.location.pos.y);
	call DiagMsg.uint16(debug_m.rangeToSrc.distance);
	call DiagMsg.uint16(debug_m.shortestPath.distance);
	call DiagMsg.uint16(debug_m.rangeToAnchor.distance);
	call DiagMsg.uint8(debug_m.hopCount);
        //call DiagMsg.uint16(debug_m.rank);
	//call DiagMsg.boolean(debug_m.if1);
	//call DiagMsg.boolean(debug_m.if2);
	//call DiagMsg.boolean(debug_m.else2);
      }
      call DiagMsg.send();
    }
  }
  
}
