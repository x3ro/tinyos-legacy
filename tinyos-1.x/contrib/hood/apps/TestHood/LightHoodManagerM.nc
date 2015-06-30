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

module LightHoodManagerM{
  provides{
    interface StdControl;
  }
  uses{
    interface Reflection<uint16_t> as LightRefl @reflection("LightHood","Light");
    interface Reflection<location_t> as LocationRefl @reflection("LightHood","Location");
    interface Reflection<uint16_t> as Timestamp @scribble("LightHood","Timestamp");
    interface HoodManager @hood("LightHood", 8, "Light","Location"); //name, numNbrs, required attrs
    interface Hood;
    interface Timer;
  }
}
implementation {

  enum {
    TIMER_FREQUENCY = 1000,
    MAX_IDLE_TIME=10000,
    MIN_LIGHT_VALUE=30
  };

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, TIMER_FREQUENCY);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired(){
    //every time the timer fires, increase the count for all neighbors
    uint8_t n, timestamp;
    uint16_t neighbor;
    for(n=0;n < call Hood.numNeighbors(); n++){
      //if the timestamp is too high, remove that neighbor
      timestamp = call Timestamp.get(neighbor);
      if ( call Hood.getNeighborID(n, &neighbor) &&
	   call Timestamp.valid(neighbor) &&
	   timestamp > MAX_IDLE_TIME ){
	call HoodManager.removeNeighbor(neighbor);
	continue;
      }
      call Timestamp.scribble(neighbor, timestamp+TIMER_FREQUENCY);
    }
    return SUCCESS;
  }

  event void HoodManager.newCandidate(uint16_t nodeID){
    //if the light value is above some threshold and the location is
    //valid, then this is a valid neighbor. try to add it:
    if (call LocationRefl.valid(nodeID) &&
	call LightRefl.valid(nodeID) &&
	call LightRefl.get(nodeID) > MIN_LIGHT_VALUE ){
      if (call HoodManager.acceptCandidate(nodeID)==FAIL){

	uint8_t n, minNode=0, foundOne=0;
	uint16_t neighbor, minLight=65535U;
	//if there is no space to just accept it, find another one to replace
	for(n=0;n < call Hood.numNeighbors(); n++){
	  if ( call Hood.getNeighborID(n, &neighbor) &&
	       call LightRefl.get(neighbor) <= minLight &&
	       call LightRefl.get(neighbor) <= call LightRefl.get(nodeID)){
	    foundOne = 1;
	    minNode=neighbor;
	    minLight = call LightRefl.get(neighbor);
	  }
	}
	if (foundOne == 1){
	  call HoodManager.replaceNeighborWithCandidate(minNode, nodeID);
	}
      }
    }
  }

  event void Hood.addedNeighbor(uint16_t nodeID){
    call Timestamp.scribble(nodeID, 0);
  }
  event void Hood.removedNeighbor(uint16_t nodeID){
  }
  event void LightRefl.updated(uint16_t nodeID, uint16_t val){
    call Timestamp.scribble(nodeID, 0);
  }
  event void LocationRefl.updated(uint16_t nodeID, location_t val){
    call Timestamp.scribble(nodeID, 0);
  }
  event void Timestamp.updated( uint16_t nodeID, uint16_t val){
  }



}

