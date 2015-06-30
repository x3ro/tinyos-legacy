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
includes Localization;

//!! Neighbor 2 { location_t location = { pos:{x:0, y:0, z:0}, stdv:{x:32767, y:32767, z:32767}, coordinate_system:0 }; }

//!! Neighbor 5 { anchorArray_t anchors; }

//!! Neighbor 4 { anchorCorrectionArray_t anchorCorrections; }

module LocalizationByAPS
{
  provides
  {
    interface StdControl;
    interface Localization;
  }
  uses
  {
    interface Neighbor_location;
    interface Neighbor_anchors;
    interface Neighbor_anchorCorrections;
    interface TupleStore;
    interface Leds;
  }
}
implementation
{
  bool isAnchor;

  void estimateLocation();
  result_t chooseAnchors();
  void correctDistancesToAnchors();
  void calculateOwnCoordinates();


  command result_t StdControl.init()
  {
    isAnchor=FALSE;
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


  /**This command is here as a wrapper for the task
	because NesC doesn't support putting tasks in interfaces
  */
  command void Localization.estimateLocation()
  {
	estimateLocation();
  }




  /**This task first chooses the anchors to use,
	then estimates the distance to each anchor, accounting
	perhaps for correction factors from other anchors,
	then calculates its own XY coordinates by using the 
	distances to the anchor nodes and puts the XY coords 
	in the neighborhood to be shared with its other neighbors
  */
  void estimateLocation()
  {
	if(isAnchor) call Neighbor_anchors.publish();

	else 
	if(chooseAnchors()==SUCCESS){
		correctDistancesToAnchors();
		calculateOwnCoordinates();
	}
  }






  /**This command chooses MAX_NUM_ANCHORS number of anchors with which
	to judge its own position.  It should try to choose anchors 
	that are not too far away, are not colinear, etc.
	CURRENT IMPLEMENTATION: choose the closest anchors
	@return SUCCESS means a good subset of anchors was found
  */
  result_t chooseAnchors()
  {
      uint8_t i, numAnchors, farthestAnchor; 
      anchorArray_t newAnchors;
      const Neighbor_t* me = call TupleStore.getByAddress( TOS_LOCAL_ADDRESS );
      TupleIterator_t ii = call TupleStore.initIterator();

      //first, initialize the anchor list
      for(i=0;i<MAX_NUM_ANCHORS;i++){
		newAnchors.data[i].ID = 0;
		newAnchors.data[i].shortestPathDistance = 32767;
      }
      farthestAnchor = 0;

      // Iterate over all valid tuples in the tuple store.
      while( call TupleStore.getNext(&ii) == TRUE )
      {
	// Check that this tuple is not the local tuple.
	if( ii.tuple->address != TOS_LOCAL_ADDRESS )
	{
		// Check all anchors that each node is using.  See if any of those
		// anchors are closer than the anchors I am using and if so, use them instead
		for(i=0;i<MAX_NUM_ANCHORS;i++){
			if(ii.tuple->anchors.data[i].shortestPathDistance + ii.tuple->rangingData.distance < newAnchors.data[farthestAnchor].shortestPathDistance){
				newAnchors.data[farthestAnchor] = ii.tuple->anchors.data[i];
				newAnchors.data[farthestAnchor].shortestPathDistance += ii.tuple->rangingData.distance;
				for(i=0;i<MAX_NUM_ANCHORS;i++)
					if(newAnchors.data[i].shortestPathDistance > newAnchors.data[farthestAnchor].shortestPathDistance) farthestAnchor=i;
			}
		}
	}

      //check that we have at least 3 anchor nodes (or 4 in 3D)
      numAnchors=0;
      for(i=0;i<MAX_NUM_ANCHORS;i++){
	if(newAnchors.data[i].ID!=0)
		numAnchors++;
      }
      if(numAnchors>=3){
	call Neighbor_anchors.set(TOS_LOCAL_ADDRESS, &newAnchors);
	return SUCCESS;
      }
      else{
	return FAIL;
      }
   }
  }





  /**This command uses the correction factors that other anchor
	nodes have published to correct the distance estimates
	to each anchor node
  */
  void correctDistancesToAnchors()
  {
  }






  /**This command calculates the current position given anchor node positions
	and estimated distance to those anchor nodes.  
	CURRENT IMPLEMENTATION: assume we have at most 3 anchor nodes and 
	use backsubstitution to solve my own coordinates.
  */
  void calculateOwnCoordinates()
  {
      uint8_t i;
      float A[2][2], B[2]; //these are variables for equation "Ax=B"
      const Neighbor_t* me = call TupleStore.getByAddress( TOS_LOCAL_ADDRESS );
      location_t myLocation = me->location;

	//first generate the A coefficient matrix and B matrix
      for(i=0;i<2;i++){
	A[i][0] = (float)( me->anchors.data[i].location.pos.x - me->anchors.data[3].location.pos.x);
	A[i][1] = (float)( me->anchors.data[i].location.pos.y - me->anchors.data[3].location.pos.y);
	B[i] = (float)( + me->anchors.data[i].shortestPathDistance*me->anchors.data[i].shortestPathDistance 
			- me->anchors.data[3].shortestPathDistance*me->anchors.data[3].shortestPathDistance 
			- me->anchors.data[i].location.pos.x*me->anchors.data[i].location.pos.x 
			+ me->anchors.data[3].location.pos.x*me->anchors.data[3].location.pos.x 
			- me->anchors.data[i].location.pos.y*me->anchors.data[i].location.pos.y 
			+ me->anchors.data[3].location.pos.y*me->anchors.data[3].location.pos.y); 
      }
	
      if(A[1][1] != 0 && A[0][0] !=0){
		// make the A matrix triangular
	      A[0][0] += -A[0][1]/A[1][1] * A[1][0]; 
	      A[0][1] =0;

		//now solve for x using backsubstitution
	      myLocation.pos.x = (uint16_t) ( B[0]/A[0][0] );
	      myLocation.pos.y = (uint16_t) ( (B[1] - myLocation.pos.x*A[1][0])/A[1][1] );
      }
      else if(A[1][0] != 0 && A[0][1] !=0){
		// make the A matrix triangular along the other diagonal
	      A[0][1] += -A[0][0]/A[1][0] * A[1][1]; 
	      A[0][0] =0;

		//now solve for x using backsubstitution
	      myLocation.pos.y = (uint16_t) ( B[0]/A[0][1] );
	      myLocation.pos.x = (uint16_t) ( (B[1] - myLocation.pos.y*A[1][1])/A[1][0] );
      }
      else return;// FAIL;
      call Neighbor_location.set(TOS_LOCAL_ADDRESS, &myLocation);
  }



  event void Neighbor_location.updatedFromRemote( uint16_t address )
  {
      uint8_t i;
      anchorArray_t newAnchors;
      const Neighbor_t* me = call TupleStore.getByAddress( TOS_LOCAL_ADDRESS );

      if(address!=TOS_LOCAL_ADDRESS) return;
	
      isAnchor=TRUE;
      newAnchors.data[0].ID=TOS_LOCAL_ADDRESS;
      newAnchors.data[0].location=me->location;
      newAnchors.data[0].shortestPathDistance=0;
      for(i=1;i<MAX_NUM_ANCHORS;i++){
		newAnchors.data[i].ID = 0;
		newAnchors.data[i].shortestPathDistance = 32767;
      }
      call Neighbor_anchors.set(TOS_LOCAL_ADDRESS, &newAnchors);
	
  }

  event void Neighbor_anchors.updatedFromRemote( uint16_t address )
  {
  }

  event void Neighbor_anchorCorrections.updatedFromRemote( uint16_t address )
  {
  }



}








