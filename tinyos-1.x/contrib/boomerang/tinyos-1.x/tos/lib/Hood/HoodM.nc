/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Kamin Whitehouse
 */

generic module HoodM (uint8_t hoodID, uint8_t numSlots){
  provides{
    interface StdControl;
    interface Hood;
    interface HoodManager;
    interface GenericBackend;
  }
  uses{
    interface ReflBackend[AttrID_t reflID];
    interface HoodTransport;
  }
}
implementation {
  uint16_t neighbor[numSlots];
  bool isvalid[numSlots];
  bool candidate[numSlots];
  bool completeCandidate[numSlots];
  uint8_t numNeighbors;

  command result_t StdControl.init() {
    uint8_t i;
    for( i=0; i>numSlots; i++){
      isvalid[i] = FALSE;
      candidate[i] = FALSE;
      completeCandidate[i] = FALSE;
    }
    numNeighbors = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  bool isInTable(uint16_t nodeID, uint8_t *slot){
    uint8_t i;
    for (i=0;i<numSlots;i++){
      if (isvalid[i] && (nodeID==neighbor[i]) ){
	*slot = i;
	return TRUE;
      }
    }
    return FALSE;
  }    

  command uint8_t Hood.numNeighbors(){
    return numNeighbors;
  }

  command uint8_t Hood.numSlots(){
    return numSlots;
  }

  command bool Hood.getNeighborID ( uint8_t p_index, uint16_t *neighborID ){
    uint8_t i, count=0;
    for (i=0;i<numSlots;i++){
      if ( isvalid[i] && !candidate[i] ){
	count++;
	if (count > p_index){
	  return TRUE;
	}
      }
    }
    return FALSE;
  }

  command bool Hood.isNeighbor( uint16_t nodeID ){
    uint8_t slot;
    if (isInTable(nodeID, &slot) && !candidate[slot] ){
      return TRUE;
    }
    return FALSE;
  }

  command result_t HoodManager.removeNeighbor(uint16_t nodeID ){
    uint8_t slot, i;
    AttrID_t reflID;
    if (isInTable(nodeID, &slot) ){

      //first, make the neighbor invalid
      isvalid[slot]=FALSE;
      numNeighbors--;

      //now go through and invalidate all refls
      for ( i=0 ; i < numReflections[hoodID-HOOD_ID_OFFSET] ; i++ ){
	reflID = reflections[hoodID-HOOD_ID_OFFSET][i];
	call ReflBackend.clear[reflID](slot);
      }

      //      dbg(DBG_USR1, "Hood: removed node %d from slot %d\n", nodeID, slot); 
      signal Hood.removedNeighbor(nodeID);
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t HoodManager.acceptCandidate(uint16_t nodeID){
    uint8_t slot, i;
    ReflID_t reflID;
    if (numNeighbors < numSlots && isInTable(nodeID, &slot) && candidate[slot]){
      candidate[slot]=FALSE;
      numNeighbors++;
      //      dbg(DBG_USR1, "Hood: accepted node %d into table in slot %d\n", nodeID, slot); 
      
      // signal new neighbor event
      signal Hood.addedNeighbor(nodeID);

      // signal updated events for all valid reflections
      for ( i=0 ; i <  numReflections[hoodID-HOOD_ID_OFFSET] ; i++ ){
	reflID = reflections[hoodID-HOOD_ID_OFFSET][i];
	//for now, there's no better way to signal updated events than this:
	call ReflBackend.set[reflID]( slot, 
				      call ReflBackend.get[reflID](slot), 
				      nodeID);
      }

      return SUCCESS;
    }
    return FAIL;
  }

  command result_t HoodManager.replaceNeighborWithCandidate(uint16_t neighborID, uint16_t candidateID){
    if (neighborID==candidateID){
      return call HoodManager.acceptCandidate(candidateID);
    }
    else{
      if (call Hood.isNeighbor(candidateID) ){
	if (call HoodManager.removeNeighbor(neighborID)){
	  return call HoodManager.acceptCandidate(candidateID);
	}
      }
    }
    return FAIL;
  }

  event result_t ReflBackend.updateRequest[AttrID_t reflID](uint16_t nodeID){
    return call HoodTransport.attrPull(reflID, nodeID);
  }

  event bool ReflBackend.isCandidate[AttrID_t reflID](uint8_t slot){
    return candidate[slot];
  }

  event bool ReflBackend.isNeighbor[AttrID_t reflID](uint16_t nodeID, uint8_t *slot){
    return isInTable(nodeID, slot);
  }

  result_t addCandidate(uint16_t nodeID, uint8_t slot ){
    uint8_t i;
    AttrID_t reflID;
    if (!isvalid[slot]){
      
      //invalidate all refls in this slot
      for ( i=0 ; i <  numReflections[hoodID-HOOD_ID_OFFSET] ; i++ ){
	reflID = reflections[hoodID-HOOD_ID_OFFSET][i];
	call ReflBackend.clear[reflID](slot);
      }

      //now add the candidate
      completeCandidate[slot] = FALSE;
      candidate[slot] = TRUE;
      neighbor[slot] = nodeID;
      isvalid[slot] = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }


  /**********
   * set: a new attribute has arrived.  This is where the action is:
   * Here, we update the node with the new reflection.
   * There is always at least one slot reserved for candidates, so the
   * data being passed into this function is guaranteed to fit, although
   * one of the old candidates might be booted out to make space.  After
   * the data is updated, a newCandidate event is fired if there is now a
   * complete candidate that was not there before.
   **********/
  command result_t GenericBackend.set(const void* itemID, const void* data){
    uint8_t slot,i;

    //if this node is not already in the neighbor table, add it.
    //    dbg(DBG_USR1, "Hood: new value for refl %d of node %d\n", ((ReflBackend_t*)itemID)->reflID, 
    //							       ((ReflBackend_t*)itemID)->nodeID);
    if (!isInTable(((ReflBackend_t*)itemID)->nodeID, &slot) ){
      //    dbg(DBG_USR1, "Hood: node %d not in table\n", ((ReflBackend_t*)itemID)->nodeID);

      //first, try to add it in an empty slot.  
      if (numNeighbors < numSlots) {
	for ( slot=0 ; slot < numSlots ; slot++ ){
	  if (!isvalid[slot]){
	    if ( addCandidate(((ReflBackend_t*)itemID)->nodeID, slot) ){
	      //	      dbg(DBG_USR1, "Hood: added node %d as candidate in empty slot %d\n", ((ReflBackend_t*)itemID)->nodeID, slot);
	      break;
	    }
	  }
	}
      }
      //otherwise, replace the first existing candidate.
      else {
	for ( slot=0 ; slot < numSlots ; slot++ ){
	  if (candidate[slot]){
	    if (call HoodManager.removeNeighbor(neighbor[slot])){
	      if (addCandidate(((ReflBackend_t*)itemID)->nodeID, slot)) {
		//dbg(DBG_USR1, "Hood: added node %d as candidate by replacing node %d in slot %d\n", 
		//		    ((ReflBackend_t*)itemID)->nodeID, neighbor[slot], slot);
		break;
	      }
	    }
	  }
	}
      }
    }

    //at this point, we know the node is in the table.  find and update it.
    if (isInTable(((ReflBackend_t*)itemID)->nodeID, &slot) ){
      if ( call ReflBackend.set[((ReflBackend_t*)itemID)->reflID](slot, data, 
								  ((ReflBackend_t*)itemID)->nodeID) ){
	//	dbg(DBG_USR1, "Hood: set value of refl %d for node %d\n", 
	//	    ((ReflBackend_t*)itemID)->reflID, 
	//	    ((ReflBackend_t*)itemID)->nodeID);
      }

      //now, check if it just became a complete candidate.
      if ( candidate[slot] && !completeCandidate[slot] ){
	AttrID_t reflID;
	bool complete=TRUE;

	// see if we have all required fields for this candidate.
	for ( i=0 ; i <  numRequired[hoodID-HOOD_ID_OFFSET] ; i++ ){
	  reflID = requiredAttrs[hoodID-HOOD_ID_OFFSET][i];
	  complete &= call ReflBackend.get[reflID](slot)==NULL ? 
	    FALSE : TRUE;
	}

	// if so, signal that there is a new candidate to evaluate.
	if (complete) {
	  // dbg(DBG_USR1, "Hood: node %d is a new completed candidate\n", ((ReflBackend_t*)itemID)->nodeID);
	  completeCandidate[slot]=TRUE;
	  signal HoodManager.newCandidate(neighbor[slot]);
	}
      }
    }

    return SUCCESS;
  }



  /*******************
   * the rest just translates from the runtime parameter used by
   * GenericBackend to the compile time parameter used by ReflBackend.
   *****************/

  command uint8_t GenericBackend.size(const void* itemID){
    return call ReflBackend.size[((ReflBackend_t*)itemID)->reflID](0);
  }

  command const void* GenericBackend.get(const void* itemID){
    uint8_t slot;
    if (isInTable(((ReflBackend_t*)itemID)->nodeID, &slot)){
      return call ReflBackend.get[((ReflBackend_t*)itemID)->reflID](slot);
    }
    return NULL;
  }

  command result_t GenericBackend.update(const void* itemID){
    //Reflections should not be updated through the backend query
    //system; this is due to overloading of the term "update" between
    //attributes and reflections.  Update for attributes means
    //"generate a new value".  Update for reflections means get a new
    //version of the neighbor attribute over the network.  
    return FAIL;
  }

  default event void GenericBackend.updated(const void* itemID, const void* newvalue){
  }

  default event void Hood.addedNeighbor(uint16_t nodeID){
  }
  default event void Hood.removedNeighbor(uint16_t nodeID){
  }
  default event void HoodManager.newCandidate(uint16_t nodeID){
  }

  default command uint8_t ReflBackend.size[AttrID_t reflID](uint8_t slot){
    return 0;
  }
  default command const void* ReflBackend.get[AttrID_t reflID](uint8_t slot){
    return NULL;
  }
  default command result_t ReflBackend.set[AttrID_t reflID](uint8_t slot, const void* val, uint16_t nodeID){
    return FALSE;
  }
  default command result_t ReflBackend.clear[AttrID_t reflID](uint8_t slot){
    return FALSE;
  }

}

