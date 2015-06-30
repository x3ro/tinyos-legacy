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

    //all of the interfaces below should be defined in your localization and ranging components
    interface LocationAttr;

    interface LocationAttrReflection as LocationRefl;
    interface DistanceAttrReflection as DistanceRefl;
    interface RangingAttrReflection as RangingRefl;
    interface HopCountAttrReflection as HopCountRefl;
    interface RangingCountAttrReflection as RangingCountRefl;
    
    interface Neighborhood as AnchorHood;
    interface Neighborhood as RangingHood;
    interface AnchorHood_private;
    interface NeighborhoodComm as ManagementComm;
    interface NeighborhoodComm as ManagementRequestComm;
    interface MsgBuffers;
    interface DiagMsg;
  }
}

implementation
{
  bool m_pushTask_pending;
  uint8_t currentAnchorPushed;//APS-specific
//  enum{RANK_THRESHOLD=1300};//set threshold high so we only prune uninitialized nodes

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

  
  command result_t StdControl.init()
  {
    currentAnchorPushed=0;//APS-specific
    call MsgBuffers.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  //RANK = mean(distance.stdv + location.stdv.x + location.stdv.y)/32
  uint16_t rankNeighbor(AnchorHood_t *neighbor){
//	return (neighbor->data_DistanceRefl.stdv + neighbor->data_LocationRefl.stdv.x + neighbor->data_LocationRefl.stdv.y)/96;
    return (neighbor->data_DistanceRefl.stdv +neighbor->data_DistanceRefl.distance);
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
  
  task void push()
  {
    ManagementMsg *managementMsg;
    //TOS_MsgPtr msg = call AnchorHood_private.lockMsgBuffer();
/*      TOS_MsgPtr msg = call MsgBuffers_alloc(); */
    TOS_MsgPtr msg = &mmsg_push;
        m_pushTask_pending = FALSE;
    if( msg != 0 ) {
      managementMsg = (ManagementMsg*)initRoutingMsg( msg, sizeof(ManagementMsg) );
      if( managementMsg != 0 ) {
	debug_push.numNeighbors = call AnchorHood.numNeighbors();
	if(call AnchorHood.numNeighbors()==0){
	  //call AnchorHood_private.unlockMsgBuffer( msg );
/*  	  call MsgBuffers.free( msg ); */
	  return;
	}
	if(currentAnchorPushed > call AnchorHood.numNeighbors()-1)
	  currentAnchorPushed=0;//APS-specific
	if(call AnchorHood.isNeighbor(TOS_LOCAL_ADDRESS))
	  currentAnchorPushed=0;//APS-specific: if isanchor
	managementMsg->anchorID=call AnchorHood.getNeighbor(currentAnchorPushed);//APS-specific
	managementMsg->location=call LocationRefl.get(call AnchorHood.getNeighbor(currentAnchorPushed));//APS-specific
	managementMsg->shortestPath=call DistanceRefl.get(call AnchorHood.getNeighbor(currentAnchorPushed));//APS-specific
	managementMsg->hopCount=call HopCountRefl.get(call AnchorHood.getNeighbor(currentAnchorPushed));
	
	debug_push.anchorID = managementMsg->anchorID;
	debug_push.location = managementMsg->location;
	debug_push.shortestPath = managementMsg->shortestPath;
	
//		  managementMsg->rssiTxrCoeffs=call RssiTxrCoeffsAttr.get();
	if(call ManagementComm.send(POTENTIAL_CONEIGHBORS, msg)==SUCCESS){
	  currentAnchorPushed++;//APS-specific
	  dbg(DBG_USR3, "CLOSEST_NBR_MGR: sending  management info\n");
	  return;
	} else {
	  //call AnchorHood_private.unlockMsgBuffer( msg );
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
      post push();
    }
  }
  
  command void NeighborhoodManager.pushManagementInfo() {
    postPushTask();
  }

  event result_t ManagementComm.sendDone( TOS_MsgPtr msg, result_t success ) {
    //call AnchorHood_private.unlockMsgBuffer( msg );
/*      call MsgBuffers.free(msg); */
    call Leds.yellowToggle();
    //post debug_push_t();
    return SUCCESS;
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
  
/*  note the following weird semantics:  we can have multiple entries for the same neighbor,
	although each entry must have the shortest path distance to a different anchor.  Furthermore
	the same anchor cannot be in the neighborhood more than once, even if it is through multiple
	neighbors.  I.e. the neighbor is really the anchorID, and it has to have a unique entry.
	We are making the neighbor through which the shortest path is found to be the neighbor because
	that makes it easier to update and keep track of RSSI readings.*/
  void unpackManagementMsg(uint16_t src, TOS_MsgPtr msg ) {
    nodeID_t maxNeighbor;
    uint16_t maxRank;
    AnchorHood_t *oldAnchorInfo, candidate = G_default_node_AnchorHood;
    ManagementMsg *managementMsg = (ManagementMsg*)popFromRoutingMsg( msg, sizeof(ManagementMsg) );
    distance_t rangingData;

    //call Leds.redToggle();
    //post debug_push_rec_t();
    debug_m.src = src;
    if(!call RangingHood.isNeighbor(src)) {
      debug_m.isNeighbor = FALSE;
      return; //if there is no ranging info, this cannot be a neighbor
    }
    else // debug
      debug_m.isNeighbor = TRUE;
    
    candidate.id=managementMsg->anchorID;
    candidate.data_LocationRefl=managementMsg->location;
//	candidate.data_RssiTxrCoeffsRefl=managementMsg->rssiTxrCoeffs;
    candidate.data_ShortestPathRefl=managementMsg->shortestPath;//APS-specific
    candidate.data_ShortestPathNodeRefl=src;//APS-specific
    rangingData=call RangingRefl.get(src);
    // see if we have enough ranging readings to feel confident about ranging data
    if(call RangingCountRefl.get(src) < G_Config.rangingCountMin)
      return;
    candidate.data_DistanceRefl.distance=candidate.data_ShortestPathRefl.distance+rangingData.distance;

    // put anchor pruning here
    candidate.data_DistanceRefl.stdv=candidate.data_ShortestPathRefl.stdv+rangingData.stdv;

    // increment hop count on receive
    candidate.data_HopCountRefl = managementMsg->hopCount+1;
    
    candidate.data_RankRefl=rankNeighbor(&candidate);
    
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
	signal AnchorInfoPropagation.initiateAnchorPropagation();
	return;
      }
      else{
	return;
      }
    }
	
    if(call AnchorHood.numNeighbors() < MAX_MEMBERS_AnchorHood) {
      call AnchorHood_private.addID(candidate.id, &candidate);
      signal AnchorInfoPropagation.initiateAnchorPropagation();
    } else {
      findMaxRankingNeighbor(&maxNeighbor, &maxRank);
      if(candidate.data_RankRefl < maxRank){
	
	call AnchorHood_private.changeID(maxNeighbor, candidate.id, &candidate);
	signal AnchorInfoPropagation.initiateAnchorPropagation();
      }
    }
    call NeighborhoodManager.prune();
    return;
  }


  event TOS_MsgPtr ManagementComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    uint8_t i,numNeighbors;
    dbg(DBG_USR2, "got management info msg from neighbor %d\n", src);
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
    postPushTask();
    return msg;
  }

  event TOS_MsgPtr ManagementRequestComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg ) {
    postPushTask();
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
    distance_t sp;
    uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
    nodeID_t anchorID;
    for(i=0;i<numNeighbors;i++){
      anchorID=call AnchorHood.getNeighbor(i);
      if(call ShortestPathNodeRefl.get(anchorID)==id){
	sp=call ShortestPathRefl.get(anchorID);
	rangingData.distance=sp.distance+rangingData.distance;
	rangingData.stdv=sp.stdv+rangingData.stdv;
	call DistanceRefl.scribble(anchorID, rangingData);
	call RankRefl.scribble(anchorID, rankNeighbor(call AnchorHood_private.getID(anchorID)));
      }
    }
  }

  event void RangingCountRefl.updated ( nodeID_t id, uint8_t rangingData ) {
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

}
