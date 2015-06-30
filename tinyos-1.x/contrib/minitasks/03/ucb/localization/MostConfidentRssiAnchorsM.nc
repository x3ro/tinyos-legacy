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
includes MostConfidentRssiAnchors;

module MostConfidentRssiAnchorsM
{
  provides
  {
    interface StdControl;
    interface NeighborhoodManager;
  }
  uses
  {
    interface RankAttrReflection as RankRefl;
    interface Rssi;
    interface Leds;

    //all of the interfaces below should be defined in your localization and ranging components
    interface LocationAttr;
    interface RssiTxrCoeffsAttr;
    interface RssiRxrCoeffsAttr;

    interface LocationAttrReflection as LocationRefl;
    interface RssiTxrCoeffsAttrReflection as RssiTxrCoeffsRefl;
    interface RssiAttrReflection as RssiRefl;
    interface DistanceAttrReflection as DistanceRefl;

    interface Neighborhood as AnchorHood;
    interface AnchorHood_private;
    interface NeighborhoodComm as ManagementComm;
    interface NeighborhoodComm as ManagementRequestComm;
  }
}

implementation
{
  AnchorHood_t candidate;
  bool m_pushTask_pending;

  enum{RANK_THRESHOLD=1300};//set threshold high so we only prune uninitialized nodes

  typedef struct{
	location_t location;
	polynomialD1_t rssiTxrCoeffs;
  } ManagementMsg;

  command result_t StdControl.init()
  {
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
	return (neighbor->data_DistanceRefl.stdv + neighbor->data_LocationRefl.stdv.x + neighbor->data_LocationRefl.stdv.y)/96;
  }

  command void NeighborhoodManager.prune(){
	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
	for(i=0;i<numNeighbors;i++){
		nodeID_t neighbor = call AnchorHood.getNeighbor(i);
		if(call RankRefl.get(neighbor) > RANK_THRESHOLD){
			call AnchorHood_private.removeID(neighbor);
		}
		if(call RankRefl.get(neighbor) > RANK_THRESHOLD){
			call AnchorHood_private.removeID(neighbor);
		}
	}
  }

  void findMinRankingNeighbor(nodeID_t *minNode, uint16_t *rank){
	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
	uint16_t currRank;
 	*minNode=0;
	if(numNeighbors<MAX_MEMBERS_AnchorHood){ *rank=65535; return;}
	*rank=0;

	for(i=0;i<numNeighbors;i++){
		nodeID_t neighbor = call AnchorHood.getNeighbor(i);
		currRank=call RankRefl.get(neighbor);
		if(currRank >= *rank){
			*minNode=neighbor;
			*rank=currRank;
		}
	}
	dbg(DBG_USR2, "CLOSEST_NBR_MGR: min ranking neighbor is node %d with rank %d\n", *minNode, *rank);
  }









  task void push()
  {
    ManagementMsg *managementMsg;
	TOS_MsgPtr msg = call AnchorHood_private.lockMsgBuffer();
    m_pushTask_pending = FALSE;
    if( msg != 0 )
    {
      managementMsg = (ManagementMsg*)initRoutingMsg( msg, sizeof(ManagementMsg) );
      if( managementMsg != 0 )
      {
		  managementMsg->location=call LocationAttr.get();
		  managementMsg->rssiTxrCoeffs=call RssiTxrCoeffsAttr.get();
		  if(call ManagementComm.send(POTENTIAL_CONEIGHBORS, msg)==SUCCESS){
			  dbg(DBG_USR3, "CLOSEST_NBR_MGR: sending  management info\n");
			  return;
		  }else{
			  dbg(DBG_USR3, "CLOSEST_NBR_MGR: ERROR sending  management info\n");
		  }
      }
	call AnchorHood_private.unlockMsgBuffer( msg );
    }
  }

  void postPushTask()
  {
    if( m_pushTask_pending == FALSE )
    {
      m_pushTask_pending = TRUE;
      post push();
    }
  }

  command void NeighborhoodManager.pushManagementInfo(){
	  postPushTask();
  }

  event result_t ManagementComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call AnchorHood_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr ManagementComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
	uint8_t i,numNeighbors = call AnchorHood.numNeighbors();
	dbg(DBG_USR2, "got management info msg from neighbor %d\n", src);
    dbg(DBG_USR2, "CLOSEST_NBR_MGR: neighborhood: ");
    for(i=0;i<numNeighbors;i++){dbg(DBG_USR2, "%d ", call AnchorHood.getNeighbor(i));}
    dbg(DBG_USR2, "\n");	
	//Here, I could update anchors using scribble, but that would violate
	//update event semantics
    return msg;
  }

  event TOS_MsgPtr ManagementComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
	nodeID_t minNeighbor;
	uint16_t minRank,i,numNeighbors, rssi;
	ManagementMsg *managementMsg = (ManagementMsg*)popFromRoutingMsg( msg, sizeof(ManagementMsg) );
	dbg(DBG_USR2, "got management info msg from non-neighbor %d\n", src.address);
	candidate.id=src.address;
	candidate.data_LocationRefl=managementMsg->location;
	candidate.data_RssiTxrCoeffsRefl=managementMsg->rssiTxrCoeffs;
#ifdef MAKEPC
    dbg(DBG_USR1, "RSSI MSG: transmitter %d\n", src.address);                  //uncomment for simulation
	rssi=generic_adc_read(TOS_LOCAL_ADDRESS,131,0);
    dbg(DBG_USR1, "RSSI MSG : rssi= %d\n",rssi);                  //uncomment for simulation
	addToEWMA((float)rssi, &(candidate.data_RssiRefl));  //uncomment for simulation
#else
	addToEWMA((float)msg->strength, &(candidate.data_RssiRefl)); //uncomment for real deployment
#endif
	candidate.data_DistanceRefl=call Rssi.estimateDistance(candidate.data_RssiRefl,(polynomial_t*)&(candidate.data_RssiTxrCoeffsRefl));
	candidate.data_RankRefl=rankNeighbor(&candidate);
        dbg(DBG_USR2, "CLOSEST_NBR_MGR: observed potential neighbor %d with location x: %d, xStd: %d, y: %d, yStd: %d, distance: %d, dStdv: %d, and rank: %d\n", src.address, candidate.data_LocationRefl.pos.x, candidate.data_LocationRefl.stdv.x, candidate.data_LocationRefl.pos.y, candidate.data_LocationRefl.stdv.y, candidate.data_DistanceRefl.distance, candidate.data_DistanceRefl.stdv, candidate.data_RankRefl);

	if(call AnchorHood.numNeighbors() < MAX_MEMBERS_AnchorHood){
		call AnchorHood_private.addID(src.address, &candidate);
	}
	else{
		findMinRankingNeighbor(&minNeighbor, &minRank);
		if(candidate.data_RankRefl < minRank){
			call AnchorHood_private.changeID(minNeighbor, src.address, &candidate);
		}
	}
	call NeighborhoodManager.prune();
	numNeighbors = call AnchorHood.numNeighbors();
        dbg(DBG_USR2, "CLOSEST_NBR_MGR: neighborhood: ");
        for(i=0;i<numNeighbors;i++){dbg(DBG_USR2, "%d ", call AnchorHood.getNeighbor(i));}
        dbg(DBG_USR2, "\n");	
	return msg;
  }

  task void pull()
  {
    TOS_MsgPtr msg = call AnchorHood_private.lockMsgBuffer();
    if( msg != 0 )
    {
      if( call ManagementRequestComm.send(POTENTIAL_NEIGHBORS, msg ) == SUCCESS )
		  return;
      call AnchorHood_private.unlockMsgBuffer( msg );
    }
  }

  command void NeighborhoodManager.pullManagementInfo()
  {
    post pull() ? SUCCESS : FAIL;
  }

  event result_t ManagementRequestComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call AnchorHood_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr ManagementRequestComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }

  event TOS_MsgPtr ManagementRequestComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }




  
  event void LocationAttr.updated(){
	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
//        dbg(DBG_USR2, "CLOSEST_NBR_MGR: my location attribute was updated\n");
	for(i=0;i<numNeighbors;i++){
		call RankRefl.scribble(i, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(i))));
	}
  }

  event void RssiTxrCoeffsAttr.updated( ){
  }

  event void RssiRxrCoeffsAttr.updated( ){
	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
//        dbg(DBG_USR2, "CLOSEST_NBR_MGR: my location attribute was updated\n");
	for(i=0;i<numNeighbors;i++){
		call RankRefl.scribble(i, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(i))));
	}
  }

  event void LocationRefl.updated( nodeID_t id, location_t value ){
	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(id)));
  }

  event void RssiRefl.updated( nodeID_t id, ewma_t value ){
  }

  event void RankRefl.updated( nodeID_t id, uint16_t value ){
  }

  event void RssiTxrCoeffsRefl.updated( nodeID_t id, polynomialD1_t value ){
	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(id))));
  }

  event void DistanceRefl.updated( nodeID_t id, distance_t value ){
	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(id))));
  }

  event void AnchorHood.removingNeighbor( nodeID_t id ){
    location_t location = call LocationRefl.get(id); 
  //    dbg(DBG_USR1, "LOC_BY_MULTI: %d removed from nbhd: x= %d, y= %d\n", id, location.pos.x, location.pos.y);
  }
  
  event void AnchorHood.addedNeighbor( nodeID_t id ){
    location_t location = call LocationRefl.get(id);
  //    dbg(DBG_USR1, "LOC_BY_MULTI: %d added to nbhd: x= %d, y= %d\n", id, location.pos.x, location.pos.y); 
  }

}














