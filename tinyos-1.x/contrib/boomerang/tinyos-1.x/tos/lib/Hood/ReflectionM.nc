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

generic module ReflectionM(typedef ReflectionType_t, uint8_t NumNeighbors) {
  provides{
    interface StdControl;
    interface Reflection<ReflectionType_t>;
    interface ReflBackend;
  }
}
implementation {
  ReflectionType_t val[NumNeighbors];
  bool isvalid[NumNeighbors];

  command result_t StdControl.init() {
    uint8_t i;
    for (i=0 ; i < NumNeighbors; i++) {
      isvalid[i]=0;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  command ReflectionType_t Reflection.get(uint16_t nodeID) {
    uint8_t slot;
    if ( signal ReflBackend.isNeighbor(nodeID, &slot) ){
      return val[slot];
    }
    else {
      return val[0];
    }
  }
  command const void* ReflBackend.get(uint8_t slot){
    if (slot >= NumNeighbors){
      return NULL;
    }
    return val+slot;
  }
  
  command bool Reflection.valid(uint16_t nodeID) {
    uint8_t slot;
    return signal ReflBackend.isNeighbor(nodeID, &slot) && isvalid[slot];
  }
  
  command uint8_t ReflBackend.size(uint8_t slot){
    return sizeof(ReflectionType_t);
  }

  command result_t Reflection.update(uint16_t nodeID) {
    return signal ReflBackend.updateRequest(nodeID);
  }

  command result_t Reflection.scribble(uint16_t nodeID, ReflectionType_t newval) {
    uint8_t slot;
    if (signal ReflBackend.isNeighbor(nodeID, &slot) ){
      val[slot]=newval;
      isvalid[slot]=TRUE;
      signal Reflection.updated(nodeID, val[slot]);
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t ReflBackend.set(uint8_t slot, const void* newval, uint16_t nodeID){
    memcpy(val+slot, newval, sizeof(ReflectionType_t));
    isvalid[slot]=TRUE;
    if ( !(signal ReflBackend.isCandidate(slot)) ){
      signal Reflection.updated(nodeID, val[slot]);
    }
    return SUCCESS;     
  }
  
  command result_t ReflBackend.clear(uint8_t slot){
    isvalid[slot]=FALSE;
    return SUCCESS;     
  }
  
  default event void Reflection.updated(uint16_t nodeID, ReflectionType_t newval){
  }

  default event result_t ReflBackend.updateRequest(uint16_t nodeID){
    return FAIL;
  }

}

