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

/*  This component chooses the N geographically closest nodes
	according to some metric (currently euclidean distance)

	The distances are cached as the node "rank", with two caveats:

	1. A very conservative estimate of distance is used, where
	distances are considered to be +-stdv, so the maximum
	distance possible within 1 stdv is chosen.

	2.  Distances are discretized to 32cm (1ft) for stability and
	memory savings

	This component assumes this it is being used for a neighborhood
	that has a distance_t attribute, rssi moving average attribute, 
	and a rssiTxrCalibrationCoefficients attribute.
	The neighborhood it is managing should be called "AnchorHood".
	*/

includes common_structs;
includes Ranging;
includes Rssi;
includes AnchorHood;
includes NeighborhoodComm;
includes math;

enum{RANK_THRESHOLD=0};//set threshold to zero so we never prune anybody

//!! RankAttr = CreateAttribute( uint16_t=0 );
//!! RankRefl = CreateReflection( AnchorHood, RankAttr, FALSE );

typedef struct{
location_t location;
calibrationCoeffs_t rssiTxrCoeffs;
} managementMsg;

module ClosestNeighborsManagerM
{
  provides
  {
    interface StdControl;
    interface NeighborhoodManager;
  }
  uses
  {
    interface RankRefl;
    interface StdControl as RankReflControl;
    interface Rssi;
    interface Leds;

    \\all of the interfaces below should be defined in your ranging component
    interface RssiTxrCoeffsAttr;
    interface RssiRxrCoeffsAttr;

    interface RssiTxrCoeffsAttrReflection as RssiTxrCoeffsRefl;
    interface RssiAttrReflection as RssiRefl;
    interface DistanceAttrReflection as DistanceRefl;

    interface Neighborhood as AnchorHood;
    interface Neighborhood_private as PrivateAnchorHood;
    interface NeighborhoodComm as ManagementComm;
    interface NeighborhoodComm as ManagementRequestComm;
  }
}

implementation
{
  AnchorHood_t candidate;
  TOS_Msg m_msg;

  command result_t StdControl.init()
  {
    RankReflControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    RankReflControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    RankReflControl.stop();
    return SUCCESS;
  }

  //RANK = inverse((distanceUpperBound)/32)
  uint16_t rankNeighbor(AnchorHood_t *neighbor){
	return 65535-(neighbor->data_DistanceAttr.distance + neighbor->data_DistanceAttr.stdv >> 5);
  }

  command void NeighborhoodManager.prune(){
	uint8_t i,numNeighbors=AnchorHood.numNeighbors();
	for(i=0;i<numNeighbors;i++){
		nodeID neighbor = AnchorHood.getNeighbor(i);
		if(RankRefl.get(neighbor) < RANK_THRESHOLD){
			PrivateAnchorHood.remove(neighbor);
		}
	}
  }

  void findMinRankingNeighbor(nodeID *minNode, uint16_t rank){
	uint8_t i,numNeighbors=AnchorHood.numNeighbors();
	uint16_t currRank;
 	rank=255;
	for(i=0;i<numNeighbors;i++){
		nodeID neighbor = AnchorHood.getNeighbor(i);
		currRank=RankRefl.get(neighbor);
		if(currRank < *rank){
			*minNode=neighbor;
			*rank=currRank;
		}
	}
  }

  command void NeighborhoodManager.pushManagementInfo(){
    //isn't there some sort of initialization thing for routing?
    Managementmsg managementMsg = &m_msg;
    managementMsg->rssiTxrCoeffs=call RssiTxrCoeffsAttr.get();
    call ManagementComm.send(POTENTIAL_CONEIGHBORS, &m_msg);
  }


  event result_t ManagementComm.sendDone( TOS_MsgPtr msg, result_t success ){return msg;}

  event void ManagementComm.receive( noceID src, TOS_MsgPtr msg ){
  }//Here, I could update anchors using scribble, but that would violate
	//update event semantics

  event void ManagementComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg ){
	AnchorHood_t *newNodeMirror;
	nodeID minNeighbor;
	uint16_t minRank, candidateRank;
	ManagementMsg *managementMsg = &(msg->data);
	candidate.id=src;
	candidate.data_RssiTxrCoeffsAttrRefl=managementMsg->rssiTxrCoeffs;
	candidate.data_RssiRefl.mean=msg->strength;
	candidate.data_RssiRefl.numSamples=1;
	candidate.data_DistanceRefl=Rssi.estimateDistance(&candidate.data_RssiRefl,&candidate.data_RssiTxrCoeffsRefl);
	candidate.data_RankAttr=rankNeighbor(&candidate);

	findMinRankingNeighbor(&minNeighbor, &minRank);
	if(candidate.data_RankAttr > minRank){
		PrivateAnchorHood.change(minNeighbor,src,candidate);
	}
  }


  command void NeighborhoodManager.pullManagementInfo(){
    call ManagementRequestComm.sendNAN(POTENTIAL_NEIGHBORS, &m_msg); //broadcast to 1-hop neighbors
  }

  event result_t ManagementRequestComm.sendDone( TOS_MsgPtr msg, result_t success ){return msg;}

  event void ManagementRequestComm.receive( noceID src, TOS_MsgPtr msg ){
	call NeighborhoodManager.pushManagementInfo();
  }

  event void ManagementRequestComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg ){
	call neighborhoodManager.pushManagementInfo();
  }

  event void RankAttr.updated(){
	uint8_t i,numNeighbors=AnchorHood.numNeighbors();
	for(i=0;i<numNeighbors;i++){
		RankRefl.scribble(i, rankNeighbor(PrivateAnchorHood.get(i)));
	}
  }

  event void RssiTxrCoeffsAttr.updated(Location_t value ){
	uint8_t i,numNeighbors=AnchorHood.numNeighbors();
	for(i=0;i<numNeighbors;i++){
		RankRefl.scribble(i, rankNeighbor(PrivateAnchorHood.get(i)));
	}
  }

  event void RssiRxrCoeffsAttr.updated(Location_t value ){
	uint8_t i,numNeighbors=AnchorHood.numNeighbors();
	for(i=0;i<numNeighbors;i++){
		RankRefl.scribble(i, rankNeighbor(PrivateAnchorHood.get(i)));
	}
  }

  event void RssiRefl.updated( nodeID id, Location_t value ){
	RankRefl.scribble(id, rankNeighbor(PrivateAnchorHood.get(id)));
  }

  event void RankRefl.updated( nodeID id, Location_t value ){
	call RankRefl.scribble(id, rankNeighbor(PrivateAnchorHood.get(id)));
  }

  event void RssiTxrCoeffsRefl.updated( nodeID id, Location_t value ){
	RankRefl.scribble(id, rankNeighbor(PrivateAnchorHood.get(id)));
  }

  event void DistanceRefl.updated( nodeID id, Location_t value ){
	call RankRefl.scribble(id, rankNeighbor(PrivateAnchorHood.get(id)));
  }
}














