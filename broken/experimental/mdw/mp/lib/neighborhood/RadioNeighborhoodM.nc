/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

includes RadioNeighborhood;

/**
 * RadioNeighborhoodM: Pick all one-hop radio neighbors.
 */
module RadioNeighborhoodM {
  provides {
    interface StdControl;
    interface Neighborhood;
  }
  uses {
    interface Timer;
    interface SendMsg;
    interface ReceiveMsg;
    interface Leds;
  }

} implementation {

  enum { 
    MAX_NEIGHBORS = 16,
    EMPTY_ADDR = 0xffff,
    AGE_THRESHOLD = 5,
    TIMER_RATE = 1000,
    TIMER_BEACON_COUNT = 2,
    TIMER_AGE_COUNT = 20,
    TIMER_PENDING_COUNT = 10,
  }; 

  bool pending;
  int pending_count;
  int timer_ticks;
  struct TOS_Msg beacon_packet;
  bool send_busy;

  struct neighbor {
    uint16_t addr;
    uint8_t age;
  } neighbors[MAX_NEIGHBORS];

  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY_ADDR;
    neighbor->age = 0;
  }

  static void initialize() {
    int n;
    dbg(DBG_USR2, "RadioNeighborhoodM: initialize\n");
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    timer_ticks = 0;
    send_busy = pending = FALSE;
  }

  /***********************************************************************
   * StdControl
   ***********************************************************************/

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  } 

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  static void add_neighbor(uint16_t addr) {
    int n;
    //dbg(DBG_USR2, "RadioNeighborhoodM: add_neighbor %d\n", addr);
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	neighbors[n].age = 0;
	//dbg(DBG_USR2, "RadioNeighborhoodM: renewing slot %d of %d\n", n, MAX_NEIGHBORS);
	return;
      }
    }
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY_ADDR)  {
	neighbors[n].addr = addr;
	neighbors[n].age = 0;
	//dbg(DBG_USR2, "RadioNeighborhoodM: adding in slot %d of %d\n", n, MAX_NEIGHBORS);
	break;
      }
    }
    if (pending && call Neighborhood.numNeighbors() == MAX_NEIGHBORS) {
      signal Neighborhood.getNeighborhoodDone(SUCCESS);
      pending = FALSE;
    }
  }

  static void neighbor_timeout() {
    int n;
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) {
	if (++neighbors[n].age >= AGE_THRESHOLD) {
	  dbg(DBG_USR2, "RadioNeighborhoodM: timing out neighbor %x\n", neighbors[n].addr);
	  init_neighbor(&neighbors[n]);
	}
      }
    }
  }

  static void send_beacon() {
    BeaconMsg *send_msg = (BeaconMsg *)beacon_packet.data;
    //dbg(DBG_USR2, "RadioNeighborhoodM: send_beacon(), send_busy is %d\n", send_busy);
    if (!send_busy) {
      send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
      if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(BeaconMsg), &beacon_packet) == SUCCESS) {
	send_busy = TRUE;
      }
    }
  }

  /***********************************************************************
   * Neighborhood
   ***********************************************************************/

  command result_t Neighborhood.getNeighborhood() {
    pending = TRUE;
    pending_count = 0;
    call Timer.start(TIMER_REPEAT, TIMER_RATE);
    return SUCCESS;
  }

  command int Neighborhood.numNeighbors() {
    int n, count = 0;
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) count++;
    }
    //dbg(DBG_USR2, "RadioNeighborhoodM: numNeighbors %d\n", count);
    return count;
  }

  command int Neighborhood.getNeighbors(uint16_t *buf, int size) {
    int count = 0;
    int n;
    for (n = 0; n < size && n < MAX_NEIGHBORS; n++) {
      dbg(DBG_USR2, "RadioNeighborhoodM: getNeighbors: n[%d] addr 0x%x\n", n, neighbors[n].addr);
      if (neighbors[n].addr != EMPTY_ADDR) {
	buf[n] = neighbors[n].addr;
	count++;
      }
    }
    dbg(DBG_USR2, "RadioNeighborhoodM: getNeighbors returning %d\n", count);
    return count;
  }

  /***********************************************************************
   * Timer
   ***********************************************************************/

  event result_t Timer.fired() {
    timer_ticks++;
    if (timer_ticks % TIMER_BEACON_COUNT == 0) {
      send_beacon();
    }

    if (timer_ticks % TIMER_AGE_COUNT == 0) {
      neighbor_timeout();
    }

    if (pending && ++pending_count >= TIMER_PENDING_COUNT) {
      pending = FALSE;
      signal Neighborhood.getNeighborhoodDone(SUCCESS);
      call Timer.stop();
    }
    return SUCCESS;
  }

  /***********************************************************************
   * Communication
   ***********************************************************************/

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    BeaconMsg *beacon_msg = (BeaconMsg *)recv_packet->data;
    uint16_t addr = beacon_msg->sourceaddr;
    call Leds.yellowToggle();
    //dbg(DBG_USR2, "RadioNeighborhoodM: beacon received from %x\n", addr);

    if (addr != TOS_LOCAL_ADDRESS) {
      add_neighbor(addr);
    }
    return recv_packet;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    //dbg(DBG_USR2, "RadioNeighborhoodM: sendDone\n");
    send_busy = FALSE;
    return SUCCESS;
  }

}
