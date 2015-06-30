/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Implementation of SP's Neighbor Table and associated management functions.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPNeighborTableM {
  provides {
    interface SPNeighbor[uint8_t id];
  }
  uses {
    interface ObjectPool<sp_neighbor_t> as NeighborTable;
    interface ObjectPoolEvents<sp_neighbor_t> as NeighborTableEvents;
    interface SPLinkStats;
    interface SPLinkEvents;
  }
}
implementation {

  /************************** SP NEIGHBOR ****************************/

  async command sp_neighbor_t* SPNeighbor.get[uint8_t id](uint8_t i) {
    return call NeighborTable.get(i);
  }
  async command uint8_t SPNeighbor.max[uint8_t id]() {
    return call NeighborTable.max();
  }
  async command uint8_t SPNeighbor.first[uint8_t id]() {
    return call NeighborTable.first();
  }
  async command bool SPNeighbor.valid[uint8_t id]( uint8_t i ) {
    return call NeighborTable.valid(i);
  }
  async command uint8_t SPNeighbor.next[uint8_t id]( uint8_t i ) {
    return call NeighborTable.next(i);
  }
  async command uint8_t SPNeighbor.populated[uint8_t id]() {
    return call NeighborTable.populated();
  }

  // Adding, admitting, updating and removing neighbors
  command result_t SPNeighbor.insert[uint8_t id](sp_neighbor_t* neighbor) {
    neighbor->id = id;
    if (call NeighborTable.insert(neighbor) == SUCCESS) {
      neighbor->flags |= SP_FLAG_TABLE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t SPNeighbor.remove[uint8_t id](sp_neighbor_t* neighbor) {
    if (neighbor->id == id) {
      if (call NeighborTable.remove(neighbor) == SUCCESS) {
	neighbor->flags &= ~SP_FLAG_TABLE;
	return SUCCESS;
      }
    }
    return FAIL;
  }

  command void SPNeighbor.change[uint8_t id](sp_neighbor_t* object) {
    int i;
    for (i = 0; i < uniqueCount("SPNeighbor"); i++) {
      if (i != id) {
	signal SPNeighbor.update[i](object);
      }
    }    
  }

  command sp_neighbor_flags_t SPNeighbor.getFlags[uint8_t id](sp_neighbor_t* neighbor) {
    return neighbor->flags;
  }

  // Try to find more neighbors
  command result_t SPNeighbor.find[uint8_t id]() {
    return call SPLinkStats.find();
  }
  command result_t SPNeighbor.findDone[uint8_t id]() {
    return call SPLinkStats.findDone();
  }

  event void NeighborTableEvents.inserted(sp_neighbor_t* object) {
    int i;
    for (i = 0; i < uniqueCount("SPNeighbor"); i++) {
      if (i != object->id) {
	signal SPNeighbor.update[i](object);
      }
    }
  }

  event void NeighborTableEvents.removed(sp_neighbor_t* object) {
    int i;
    for (i = 0; i < uniqueCount("SPNeighbor"); i++) {
      if (i != object->id) {
	signal SPNeighbor.evicted[i](object);
      }
    }    
  }

  event void SPLinkEvents.active() {}
  event void SPLinkEvents.sleep() {}

  event void SPLinkEvents.expired(sp_neighbor_t* n) {
    signal SPNeighbor.expired[n->id](n);
  }


  default event void SPNeighbor.update[uint8_t id](sp_neighbor_t* neighbor) { }
  default event result_t SPNeighbor.admit[uint8_t id](sp_neighbor_t* neighbor) { return SUCCESS; }
  default event void SPNeighbor.expired[uint8_t id](sp_neighbor_t* neighbor) { }
  default event void SPNeighbor.evicted[uint8_t id](sp_neighbor_t* neighbor) { }

}
