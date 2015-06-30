/*
 * Copyright (c) 2003
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

includes TupleSpace;
includes Location2D;
includes YaoRegion;

/**
 * YaoRegionM: An approximate planar mesh based on a pruned Yao graph.
 * Each node picks up to YAOREGION_NUM_SECTORS neighbors, each of which is the 
 * nearest neighbor within a sector of angle (2*pi)/YAOREGION_NUM_SECTORS.
 * Nodes then broadcast their chosen neighbor sets to other nodes, which may
 * invalidate a chosen edge if it crosses one of their own edges.
 */
module YaoRegionM {
  provides {
    interface StdControl;
    interface Region;
  }
  uses {
    interface Tuning;
    interface Timer as TimerGetTS;
    interface Timer as TimerGetLoc;
    interface Timer as TimerWaitInvalid;
    interface Location2D;
    interface TupleSpace;
    interface Region as RadioRegion;
    interface SendMsg as SendPickEdgeMsg;
    interface SendMsg as SendInvalidateMsg;
    interface ReceiveMsg as ReceivePickEdgeMsg;
    interface ReceiveMsg as ReceiveInvalidateMsg;
  }

} implementation {

  double SECTOR_ANGLE;
  double TWOPI;
  bool rn_ready, edges_ready, location_pending;
  location_2d_t myLocation;
  int ts_get_count, ts_get_done, ts_get_err, wi_timer_count;
  int state;
  tuning_value_t wait_invalidation_timeout, wait_invalidation_count,
    get_location_timeout, ts_get_delay;
  uint16_t *radio_neighbors;
  int num_radioneighbors;

  enum { 
    DEFAULT_TS_GET_DELAY = 500,
    DEFAULT_WAIT_INVALIDATION_TIMEOUT = 10000,
    DEFAULT_WAIT_INVALIDATION_COUNT = 1,
    DEFAULT_GET_LOCATION_TIMEOUT = 5000,
    EMPTY_ADDR = 0xffff,
    BAD_LOCATION = 65535,
    LINE = 0,
    COUNTER_CLOCKWISE = 1,
    CLOCKWISE = 2,
  }; 

  enum { 
    STATE_IDLE = 0,
    STATE_GET_RADIO_NEIGHBORS = 1,
    STATE_GET_NEIGHBOR_LOC = 2,
    STATE_WAITING_INVALIDATIONS = 3,
    STATE_DONE = 4,
  }; 

  struct neighbor {
    uint16_t addr;
    location_2d_t loc;
    float dist;
    float angle;
  } neighbors[YAOREGION_MAX_NEIGHBORS];

  int sector[YAOREGION_NUM_SECTORS];
  uint16_t chosen_neighbors[YAOREGION_NUM_SECTORS];
  uint16_t exported_neighbors[YAOREGION_NUM_SECTORS];
  struct TOS_Msg pick_packet[YAOREGION_NUM_SECTORS];
  struct TOS_Msg invalidate_packet;

  task void getMyLocationTask();

  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY_ADDR;
    neighbor->dist = -1.0;
    neighbor->angle = 0.0;
    neighbor->loc.x = BAD_LOCATION;
  }

  static void initialize() {
    int n;
    dbg(DBG_USR1, "YaoRegionM: initialize\n");

    TWOPI = 2 * M_PI;
    SECTOR_ANGLE = TWOPI / YAOREGION_NUM_SECTORS;
    state = STATE_IDLE;
    rn_ready = FALSE;
    edges_ready = FALSE;
    location_pending = FALSE;
    myLocation.x = BAD_LOCATION;
    wi_timer_count = 0;

    for (n = 0; n < YAOREGION_MAX_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    for (n = 0; n < YAOREGION_NUM_SECTORS; n++) {
      chosen_neighbors[n] = EMPTY_ADDR;
    }
  }

  /***********************************************************************
   * StdControl
   ***********************************************************************/

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "YaoRegionM: StdControl.start()\n");
    if (!call Tuning.getDefault(KEY_YAOREGION_TS_GET_DELAY,
	  &ts_get_delay, DEFAULT_TS_GET_DELAY)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_YAOREGION_WAIT_INVALIDATION_TIMEOUT, 
	  &wait_invalidation_timeout,
	  DEFAULT_WAIT_INVALIDATION_TIMEOUT)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_YAOREGION_WAIT_INVALIDATION_COUNT,
	  &wait_invalidation_count,
	  DEFAULT_WAIT_INVALIDATION_COUNT)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_YAOREGION_GET_LOCATION_TIMEOUT, 
	  &get_location_timeout,
	  DEFAULT_GET_LOCATION_TIMEOUT)) {
      return FAIL;
    }
    dbg(DBG_USR1, "YaoRegionM: TS_GET_DELAY %d, WAIT_INVAL_TIMEOUT %d, GET_LOC_TIMEOUT %d\n", 
	ts_get_delay,
	wait_invalidation_timeout,
	get_location_timeout);

    post getMyLocationTask();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  } 

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  static void add_neighbor(uint16_t addr) {
    int n;
    //dbg(DBG_USR2, "YaoRegionM: add_neighbor %x\n", addr);
    for (n = 0; n < YAOREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	//dbg(DBG_USR2, "YaoRegionM: renewing slot %d of %d\n", n, YAOREGION_MAX_NEIGHBORS);
	return;
      }
    }
    for (n = 0; n < YAOREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY_ADDR)  {
	neighbors[n].addr = addr;
	//dbg(DBG_USR2, "YaoRegionM: adding in slot %d of %d\n", n, YAOREGION_MAX_NEIGHBORS);
	break;
      }
    }
  }

  task void getMyLocationTask() {
    dbg(DBG_USR1, "YaoRegionM: getMyLocationTask running\n");
    if (location_pending) return;
    location_pending = TRUE;
    if (!call Location2D.getLocation()) {
      location_pending = FALSE;
      dbg(DBG_USR1, "YaoRegionM: Can't call Location2D.getLocation\n");
    } 
  }

  task void getLocationTask() {
    int n;

    dbg(DBG_USR2, "YaoRegionM: getLocationTask: rn_ready %d myLocation (%d,%d)\n", rn_ready, myLocation.x, myLocation.y);
    if (!rn_ready || myLocation.x == BAD_LOCATION) return;

    num_radioneighbors = call RadioRegion.getNodes(&radio_neighbors);
    dbg(DBG_USR2, "YaoRegionM: Got %d neighbors\n", num_radioneighbors);
    if (num_radioneighbors == 0 && state != STATE_IDLE) {
      dbg(DBG_USR2, "YaoRegionM: No radio neighbors, signalling failure\n");
      state = STATE_IDLE;
      signal Region.getDone(FAIL);
    }
    for (n = 0; n < num_radioneighbors; n++) {
      add_neighbor(radio_neighbors[n]);
    }

    // Initiate retrieval of neighbor locations
    // Spread them out over time to avoid filling queues
    state = STATE_GET_NEIGHBOR_LOC;
    if (!call TimerGetLoc.start(TIMER_ONE_SHOT, 
	  ((int)ts_get_delay) * (num_radioneighbors+2))) {
      dbg(DBG_USR2, "YaoRegionM: Can't start timer\n");
      state = STATE_IDLE;
      signal Region.getDone(FAIL);
    }

    ts_get_count = ts_get_done = ts_get_err = 0;
    if (!call TimerGetTS.start(TIMER_ONE_SHOT, (int)ts_get_delay)) {
      dbg(DBG_USR2, "YaoRegionM: Can't call TimerGetTS.start\n");
      state = STATE_IDLE;
      signal Region.getDone(FAIL);
    }
  }

  task void getNextLocationTask() {
    if (ts_get_count >= num_radioneighbors) return;

    dbg(DBG_USR2, "YaoRegionM: Calling TS.get() for neighbor %d\n", neighbors[ts_get_count].addr);
    if (!call TupleSpace.get(TS_LOCATION_KEY, neighbors[ts_get_count].addr, 
	  &neighbors[ts_get_count].loc)) {
      dbg(DBG_USR2, "YaoRegionM: Unable to call TS.get() for neighbor %d\n", neighbors[ts_get_count].addr);
      ts_get_err++;
    }
    ts_get_count++;
    if (ts_get_count < num_radioneighbors) {
      if (!call TimerGetTS.start(TIMER_ONE_SHOT, (int)ts_get_delay)) {
	dbg(DBG_USR2, "YaoRegionM: Can't call TimerGetTS.start\n");
	state = STATE_IDLE;
	signal Region.getDone(FAIL);
      }
    }
  }

  double calc_dist(location_2d_t *loc) {
    double dist;
    dist = (loc->x - myLocation.x) * (loc->x - myLocation.x);
    dist += (loc->y - myLocation.y) * (loc->y - myLocation.y);
    return sqrt(dist);
  }

  double calc_angle(location_2d_t *loc) {
    double xd, yd, an;
    xd = (double)abs(loc->x - myLocation.x);
    if (xd == 0) xd = 0.01;
    yd = (double)abs(loc->y - myLocation.y);
    an = atan(yd / xd);
    if (loc->x < myLocation.x && loc->y >= myLocation.y) an = M_PI - an;
    if (loc->x < myLocation.x && loc->y < myLocation.y) an += M_PI;
    if (loc->x >= myLocation.x && loc->y < myLocation.y) an = TWOPI - an;
    return an;
  }

  int closest_neighbor(int thesector) {
    float anglestart = SECTOR_ANGLE * thesector;
    float angleend = SECTOR_ANGLE * (thesector+1);
    int closest = -1;
    int n;

    dbg(DBG_USR2, "YaoRegionM: closest_neighbor(%d) angle %f -> %f\n", thesector, anglestart, angleend);
    dbg(DBG_USR2, "YaoRegionM: myLocation (%d,%d)\n", myLocation.x, myLocation.y);

    for (n = 0; n < YAOREGION_MAX_NEIGHBORS; n++) {
      dbg(DBG_USR2, "YaoRegionM: neighbor %d angle %f dist %f\n", neighbors[n].addr, neighbors[n].angle, neighbors[n].dist);
      if (neighbors[n].addr != EMPTY_ADDR &&
          neighbors[n].dist != -1.0 &&
	  neighbors[n].angle >= anglestart && 
	  neighbors[n].angle < angleend) {
	if (closest == -1) closest = n;
	else if (neighbors[n].dist < neighbors[closest].dist) closest = n;
      }
    }
    if (closest != -1) {
      dbg(DBG_USR2, "YaoRegionM: closest is %d\n", neighbors[closest].addr);
    } else {
      dbg(DBG_USR2, "YaoRegionM: no closest neighbor\n");
    }
    return closest;
  }

  int tridir(location_2d_t *p1, location_2d_t *p2, location_2d_t *p3) {
    int test = ((p2->x - p1->x)*(p3->y - p1->y)) - 
      ((p3->x - p1->x)*(p2->y - p1->y));
    if (test > 0) return COUNTER_CLOCKWISE;
    else if (test < 0) return CLOCKWISE;
    else return LINE;
  }

  bool crossing(uint16_t fromaddr, uint16_t toaddr, 
      location_2d_t *fromloc, location_2d_t *toloc) {
    location_2d_t *l1p1, *l1p2, *l2p1, *l2p2;
    bool test1_a, test1_b, test2_a, test2_b;
    int n;

    for (n = 0; n < YAOREGION_MAX_NEIGHBORS; n++) {
      int m;
      bool found = FALSE;
      l1p1 = &myLocation;
      l1p2 = &neighbors[n].loc; // Invalid
      if (neighbors[n].addr == EMPTY_ADDR) continue;
      if (neighbors[n].loc.x < 0.0) continue;
      for (m = 0; m < YAOREGION_NUM_SECTORS; m++) {
	if (chosen_neighbors[m] == neighbors[n].addr) found = TRUE;
      }
      if (!found) continue;

      l2p1 = fromloc;
      if (l2p1->x < 0.0) continue; // Invalid
      l2p2 = toloc;
      if (l2p2->x < 0.0) continue; // Invalid

      if (l1p1->x == l2p1->x && l1p1->y == l2p1->y) continue;
      if (l1p2->x == l2p1->x && l1p2->y == l2p1->y) continue;
      if (l1p1->x == l2p2->x && l1p1->y == l2p2->y) continue;
      if (l1p2->x == l2p2->x && l1p2->y == l2p2->y) continue;

      test1_a = tridir(l1p1, l1p2, l2p1);
      test1_b = tridir(l1p1, l1p2, l2p2);
      if (test1_a != test1_b) {
	test2_a = tridir(l2p1, l2p2, l1p1);
	test2_b = tridir(l2p1, l2p2, l1p2);
	if (test2_a != test2_b) {
	  dbg(DBG_USR2, "YaoRegionM: Edge %d -> %d crosses %d -> %d\n", 
	      fromaddr, toaddr, TOS_LOCAL_ADDRESS, neighbors[n].addr);
	  return TRUE;
	}
      }
    }
    return FALSE;
  }

  void send_pick_edges() {
    int s;
    for (s = 0; s < YAOREGION_NUM_SECTORS; s++) {
      if (chosen_neighbors[s] != EMPTY_ADDR) {
	PickEdgeMsg *pick_msg = (PickEdgeMsg *)pick_packet[s].data;
	dbg(DBG_USR2, "YaoRegionM: Choosing edge %d -> %d\n", TOS_LOCAL_ADDRESS, chosen_neighbors[s]);
	pick_msg->fromaddr = TOS_LOCAL_ADDRESS;
	pick_msg->toaddr = chosen_neighbors[s];
	memcpy(&pick_msg->fromloc, &myLocation, sizeof(myLocation));
	memcpy(&pick_msg->toloc, &(neighbors[sector[s]].loc), sizeof(pick_msg->toloc));
	// Don't care if we push it out or not - assume it's ok
	call SendPickEdgeMsg.send(TOS_BCAST_ADDR, sizeof(PickEdgeMsg), &pick_packet[s]);
      }
    }
  }

  task void calcEdgesTask() {
    int n, s;

    dbg(DBG_USR2, "YaoRegionM: calcEdgesTask running\n");

    for (n = 0; n < YAOREGION_NUM_SECTORS; n++) {
      sector[n] = -1;
    }

    for (n = 0; n < YAOREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR &&
	  neighbors[n].loc.x != BAD_LOCATION) {
	dbg(DBG_USR2, "YaoRegionM: neighbor %d loc (%d,%d)\n", neighbors[n].addr, neighbors[n].loc.x, neighbors[n].loc.y);
	neighbors[n].dist = calc_dist(&neighbors[n].loc);
	neighbors[n].angle = calc_angle(&neighbors[n].loc);
      }
    }

    // Pick closest neighbor in each sector
    for (s = 0; s < YAOREGION_NUM_SECTORS; s++) {
      sector[s] = closest_neighbor(s);
      dbg(DBG_USR2, "YaoRegionM: sector[%d] is %d\n", s, sector[s]);
      if (sector[s] != -1) {
	chosen_neighbors[s] = neighbors[sector[s]].addr;
      }
    }

    send_pick_edges();

    dbg(DBG_USR2, "YaoRegionM: Waiting for invalidations\n");
    state = STATE_WAITING_INVALIDATIONS;
    if (!call TimerWaitInvalid.start(TIMER_REPEAT, wait_invalidation_timeout)) {
      dbg(DBG_USR2, "YaoRegionM: Can't start timer\n");
      state = STATE_IDLE;
      signal Region.getDone(FAIL);
    }
  }

  void invalidate(uint16_t fromaddr, uint16_t toaddr) {
    InvalidateMsg *msg = (InvalidateMsg *)invalidate_packet.data;
    msg->fromaddr = fromaddr;
    msg->toaddr = toaddr;
    // Don't care if we push it out or not - assume it's ok
    dbg(DBG_USR2, "YaoRegionM: Invalidating %d -> %d\n", fromaddr, toaddr);
    call SendInvalidateMsg.send(fromaddr, sizeof(InvalidateMsg), &invalidate_packet);
  }

  /***********************************************************************
   * Timer
   ***********************************************************************/

  event result_t TimerGetTS.fired() {
    post getNextLocationTask();
    return SUCCESS;
  }

  event result_t TimerGetLoc.fired() {
    if (state == STATE_GET_NEIGHBOR_LOC) {
      dbg(DBG_USR2, "YaoRegionM: Timer fired, posting calcEdgesTask\n");
      post calcEdgesTask();
    }
    return SUCCESS;
  }


  event result_t TimerWaitInvalid.fired() {
    if (state == STATE_WAITING_INVALIDATIONS) {
      dbg(DBG_USR2, "YaoRegionM: TimerWaitInvalid fired\n");
      if (++wi_timer_count == wait_invalidation_count) {
	call TimerWaitInvalid.stop();
	state = STATE_DONE;
	signal Region.getDone(SUCCESS);
      }
    } 
    return SUCCESS;
  }

  /***********************************************************************
   * Region
   ***********************************************************************/

  // Form region from scratch on each call
  command result_t Region.getRegion() {
    dbg(DBG_USR2, "YaoRegionM: getRegion(), state %d\n", state);
    initialize();
    post getMyLocationTask();
    state = STATE_GET_RADIO_NEIGHBORS;
    return call RadioRegion.getRegion();
  }

  command int Region.numNodes() {
    int n, count = 0;
    for (n = 0; n < YAOREGION_NUM_SECTORS; n++) {
      if (chosen_neighbors[n] != EMPTY_ADDR) count++;
    }
    dbg(DBG_USR2, "YaoRegionM: numNeighbors %d\n", count);
    return count;
  }

  command int Region.getNodes(uint16_t **node_list_ptr) {
    int n, count = 0;
    dbg(DBG_USR2, "YaoRegionM: getNodes called\n");
    *node_list_ptr = exported_neighbors;
    for (n = 0; n < YAOREGION_NUM_SECTORS; n++) {
      dbg(DBG_USR2, "YaoRegionM: getNodes: n[%d] addr %d\n", n, chosen_neighbors[n]);
      if (chosen_neighbors[n] != EMPTY_ADDR) {
	exported_neighbors[count] = chosen_neighbors[n];
	count++;
      }
    } 
    dbg(DBG_USR2, "YaoRegionM: getNodes returning %d\n", count);
    return count;
  }

  /***********************************************************************
   * RadioRegion
   ***********************************************************************/

  event void RadioRegion.getDone(result_t success) {
    dbg(DBG_USR2, "YaoRegionM: RN.getDone\n");
    if (success == SUCCESS && state == STATE_GET_RADIO_NEIGHBORS) {
      dbg(DBG_USR2, "YaoRegionM: posting getLocationTask\n");
      rn_ready = TRUE;
      post getLocationTask();
    } else if (state == STATE_GET_RADIO_NEIGHBORS) {
      // Try to get radio neighborhood again
      dbg(DBG_USR2, "YaoRegionM: Retrying getRegion\n");
      if (!call RadioRegion.getRegion()) {
	dbg(DBG_USR2, "YaoRegionM: Can't call getRegion\n");
	state = STATE_IDLE;
	signal Region.getDone(FAIL);
      }
    }
  }

  /***********************************************************************
   * Location2D
   ***********************************************************************/

  // This will be signaled periodically e.g., if the application 
  // calls getLocation()
  event void Location2D.getLocationDone(location_2d_t *loc) {
    dbg(DBG_USR2, "YaoRegionM: locationDone\n");
    location_pending = FALSE;
    if (loc != NULL) {
      // Only recalculate edges if we move
      if (loc->x != myLocation.x ||
	  loc->y != myLocation.y) {
	myLocation.x = loc->x;
	myLocation.y = loc->y;
	if (state == STATE_DONE) {
	  state = STATE_IDLE;
	} else if (state == STATE_GET_RADIO_NEIGHBORS) {
	  post getLocationTask();
	}
	if (!call TupleSpace.put(TS_LOCATION_KEY, &myLocation, sizeof(myLocation))) {
  	  dbg(DBG_USR2, "YaoRegionM: Can't call TS.put()\n");
   	}
      }
    } else {
      // Try to get location again
      dbg(DBG_USR2, "YaoRegionM: Retrying getLocation\n");
      post getMyLocationTask();
    }
  }

  /***********************************************************************
   * SharedVar
   ***********************************************************************/

  event void TupleSpace.getDone(ts_key_t key, uint16_t moteaddr, void *buf, int buflen, result_t success) {
    dbg(DBG_USR1, "YaoRegionM: TupleSpace.getDone, key %d node %d\n", key, moteaddr);
    if (state == STATE_GET_NEIGHBOR_LOC && key == TS_LOCATION_KEY) {
      ts_get_done++;
      dbg(DBG_USR1, "YaoRegionM: TupleSpace.getDone, %d/%d completed reads\n", ts_get_done+ts_get_err, num_radioneighbors);
      if (ts_get_done+ts_get_err == num_radioneighbors) {
	post calcEdgesTask();
      }
    }
  }

  /***********************************************************************
   * SendMsg/ReceiveMsg
   ***********************************************************************/

  event result_t SendPickEdgeMsg.sendDone(TOS_MsgPtr msg, bool success) {
    return SUCCESS;
  }
  event result_t SendInvalidateMsg.sendDone(TOS_MsgPtr msg, bool success) {
    return SUCCESS;
  }

  event TOS_MsgPtr ReceivePickEdgeMsg.receive(TOS_MsgPtr recv_packet) {
    PickEdgeMsg *msg = (PickEdgeMsg *)recv_packet->data;
    dbg(DBG_USR2,"YaoRegionM: Heard about edge %d (loc %d,%d) -> %d (loc %d,%d)\n", msg->fromaddr, msg->fromloc.x, msg->fromloc.y, msg->toaddr, msg->toloc.x, msg->toloc.y);
    if (crossing(msg->fromaddr, msg->toaddr, &msg->fromloc, &msg->toloc)) {
      invalidate(msg->fromaddr, msg->toaddr);
    }
    return recv_packet;
  }

  event TOS_MsgPtr ReceiveInvalidateMsg.receive(TOS_MsgPtr recv_packet) {
    InvalidateMsg *msg = (InvalidateMsg *)recv_packet->data;
    dbg(DBG_USR2, "YaoRegionM: Got invalidate msg\n");
    if (state == STATE_WAITING_INVALIDATIONS) {
      if (msg->fromaddr == TOS_LOCAL_ADDRESS) {
	int n;
        dbg(DBG_USR2, "YaoRegionM: Invalidating local edge %d -> %d\n", msg->fromaddr, msg->toaddr);
	for (n = 0; n < YAOREGION_NUM_SECTORS; n++) {
	  if (chosen_neighbors[n] == msg->toaddr) 
	    chosen_neighbors[n] = EMPTY_ADDR;
	}
      }
    }
    return recv_packet;
  }


}
