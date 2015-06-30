/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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
	node positions are considered to be +-stdv, so the maximum
	distance possible within 1 stdv is chosen.

	2.  Distances are discretized to 32cm (1ft) for stability and
	memory savings

	This component assumes this it is being used for a neighborhood
	that has a location_t attribute  The neighborhood it is managing
	should be called "AnchorHood".
	*/

includes common_structs;
includes Localization;
includes AnchorHood;
includes Neighborhood;

module ClosestLocationNeighborsM
{
  provides
  {
    interface StdControl;
    interface NeighborhoodManager;
  }
  uses
  {
    interface Leds;

    //all of the interfaces below should be defined in your localization component
    interface LocationAttr;
    interface LocationAttrReflection as LocationRefl;
    interface LocationAttrReflectionSnoop as LocationReflSnoop;
    interface RankAttrReflection as RankRefl;
    interface RankAttrReflectionSnoop as RankReflSnoop;
    interface Neighborhood as AnchorHood;
    interface AnchorHood_private;
  }
}

implementation
{
  AnchorHood_t candidate;

  enum {
    RANK_THRESHOLD = 65535, //set threshold to zero so we never prune anybody
  };

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

  float euclideanDistance(float dx, float dy){
	return sqrt( pow(dx, 2) + pow(dy, 2) );
  }

  float manhattanDistance(float dx, float dy){
	return abs(dx) + abs(dy);
  }

  float distanceUpperBound(location_t *loc1, location_t *loc2){
	float dx = loc1->pos.x > loc2->pos.x? loc1->pos.x - loc2->pos.x : loc2->pos.x - loc1->pos.x; 
	float dy = loc1->pos.y > loc2->pos.y? loc1->pos.y - loc2->pos.y : loc2->pos.y - loc1->pos.y; 
	dx += loc1->stdv.x + loc2->stdv.x;
	dy += loc1->stdv.y + loc2->stdv.y;
	dy = euclideanDistance(dx, dy);
//	dbg(DBG_USR2, "CLOSEST_NBR_MGR: distance estimate: %f\n", dy);
	return dy;
  }

  //RANK = euclideanDistance(distanceUpperBound)/32
  uint16_t rankNeighbor(AnchorHood_t *neighbor){
	location_t myLoc=call LocationAttr.get();
	uint16_t rank = (uint16_t)(distanceUpperBound(&(neighbor->data_LocationRefl), &myLoc));// /32);
//	dbg(DBG_USR2, "CLOSEST_NBR_MGR: rank: %d\n", rank);
	return rank;
  }

  command void NeighborhoodManager.prune(){
	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
	for(i=0;i<numNeighbors;i++){
		nodeID_t neighbor = call AnchorHood.getNeighbor(i);
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

  command void NeighborhoodManager.pushManagementInfo(){
//    dbg(DBG_USR2, "CLOSEST_NBR_MGR: pushing management info\n");
    call LocationRefl.push();
  }

  command void NeighborhoodManager.pullManagementInfo(){
//    dbg(DBG_USR2, "CLOSEST_NBR_MGR: pulling management info\n");
      call LocationRefl.pull( POTENTIAL_NEIGHBORS );
  }

  event void LocationAttr.updated(){
	uint8_t i,numNeighbors=call AnchorHood.numNeighbors();
//        dbg(DBG_USR2, "CLOSEST_NBR_MGR: my location attribute was updated\n");
	for(i=0;i<numNeighbors;i++){
		call RankRefl.scribble(i, rankNeighbor(call AnchorHood_private.getID(call AnchorHood.getNeighbor(i))));
	}
  }

  event void LocationReflSnoop.updatedNAN( RoutingDestination_t address, location_t value ){
	AnchorHood_t *newNodeMirror;
	nodeID_t minNeighbor;
	uint16_t minRank, candidateRank;
	uint16_t i,numNeighbors;
	candidate.id=address.address;
	candidate.data_LocationRefl=value;
	candidate.data_RankRefl=rankNeighbor(&candidate);
        dbg(DBG_USR2, "CLOSEST_NBR_MGR: observed potential neighbor %d with location x: %d, y: %d and rank: %d\n", address.address, value.pos.x, value.pos.y, candidate.data_RankRefl);

	if(call AnchorHood.numNeighbors() < MAX_MEMBERS_AnchorHood){
		call AnchorHood_private.addID(address.address, &candidate);
	}
	else{
		findMinRankingNeighbor(&minNeighbor, &minRank);
		if(candidate.data_RankRefl < minRank){
			call AnchorHood_private.removeID(minNeighbor);
			call AnchorHood_private.addID(address.address, &candidate);
		}
	}
	numNeighbors = call AnchorHood.numNeighbors();
        dbg(DBG_USR2, "CLOSEST_NBR_MGR: neighborhood: ");
        for(i=0;i<numNeighbors;i++){dbg(DBG_USR2, "%d ", call AnchorHood.getNeighbor(i));}
        dbg(DBG_USR2, "\n");	
  }

  event void LocationRefl.updated( nodeID_t id, location_t value ){
//        dbg(DBG_USR2, "CLOSEST_NBR_MGR: saw neighbor %d location\n", id);
	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(id)));
  }

  event void RankReflSnoop.updatedNAN( RoutingDestination_t address, uint16_t rank ){
//        dbg(DBG_USR2, "CLOSEST_NBR_MGR: saw not-neighbor %d location\n", address.address);
  }

  event void RankRefl.updated( nodeID_t id, uint16_t value ){
	call RankRefl.scribble(id, rankNeighbor(call AnchorHood_private.getID(id)));
  }
  event void AnchorHood.removingNeighbor( nodeID_t id ){
	        dbg(DBG_USR2, "CLOSEST_NBR_MGR: removing node %d \n", id);
  }
  event void AnchorHood.addedNeighbor( nodeID_t id ){
	        dbg(DBG_USR2, "CLOSEST_NBR_MGR: adding node %d \n", id);
  }

}
