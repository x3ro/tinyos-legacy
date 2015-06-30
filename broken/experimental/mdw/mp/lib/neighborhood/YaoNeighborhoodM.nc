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

includes YaoNeighborhood;

/**
 * YaoNeighborhoodM: An approximate planar mesh based on a pruned Yao graph.
 * Each node picks up to MAX_YAO_NEIGHBORS neighbors, each of which is the 
 * nearest neighbor within a sector of angle (2*pi)/MAX_YAO_NEIGHBORS.
 * Nodes then broadcast their chosen neighbor sets to other nodes, which may
 * invalidate a chosen edge if it crosses one of their own edges.
 */
module YaoNeighborhoodM {
  provides {
    interface StdControl;
    interface Neighborhood;
  }
  uses {
    interface SharedVar as SV_location;
    interface Neighborhood as RadioNeighborhood;
    interface Location;
    interface Timer;
    interface SendMsg as SendPickEdgeMsg;
    interface SendMsg as SendInvalidateMsg;
    interface ReceiveMsg as ReceivePickEdgeMsg;
    interface ReceiveMsg as ReceiveInvalidateMsg;
  }

} implementation {

  double SECTOR_ANGLE;
  double TWOPI;
  bool rn_ready, edges_ready;
  location_3d_t myLocation;
  int outstanding_reads;
  int state;

  enum { 
    MAX_NEIGHBORS = 16,
    MAX_YAO_NEIGHBORS = 4,
    EMPTY_ADDR = 0xffff,
    SIGNAL_DONE_DELAY = 10000,
    GET_LOCATION_TIMEOUT = 5000,
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
    location_3d_t loc;
    float dist;
    float angle;
  } neighbors[MAX_NEIGHBORS];

  uint16_t chosen_neighbors[MAX_YAO_NEIGHBORS];
  struct TOS_Msg pick_packet[MAX_YAO_NEIGHBORS];
  struct TOS_Msg invalidate_packet;

  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY_ADDR;
    neighbor->dist = -1.0;
    neighbor->angle = 0.0;
    neighbor->loc.x = -1.0; // Invalid
  }

  static void initialize() {
    int n;
    dbg(DBG_USR1, "YaoNeighborhoodM: initialize\n");

    TWOPI = 2 * M_PI;
    SECTOR_ANGLE = TWOPI / MAX_YAO_NEIGHBORS;
    state = STATE_IDLE;
    rn_ready = FALSE;
    edges_ready = FALSE;
    myLocation.x = -1.0; // Invalid

    for (n = 0; n < MAX_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    for (n = 0; n < MAX_YAO_NEIGHBORS; n++) {
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
    if (!call Location.getLocation()) {
      dbg(DBG_USR1, "YaoNeighborhoodM: Can't call Location.getLocation\n");
    } 
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
    //dbg(DBG_USR2, "YaoNeighborhoodM: add_neighbor %x\n", addr);
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	//dbg(DBG_USR2, "YaoNeighborhoodM: renewing slot %d of %d\n", n, MAX_NEIGHBORS);
	return;
      }
    }
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY_ADDR)  {
	neighbors[n].addr = addr;
	//dbg(DBG_USR2, "YaoNeighborhoodM: adding in slot %d of %d\n", n, MAX_NEIGHBORS);
	break;
      }
    }
  }

  task void getLocationTask() {
    int num_rn, n;
    uint16_t tmp_neighbors[MAX_NEIGHBORS];

    dbg(DBG_USR2, "YaoNeighborhoodM: getLocationTask: rn_ready %d myLocation (%f,%f)\n", rn_ready, myLocation.x, myLocation.y);
    if (!rn_ready || myLocation.x == -1.0) return;

    num_rn = call RadioNeighborhood.getNeighbors(tmp_neighbors, MAX_NEIGHBORS);
    dbg(DBG_USR2, "YaoNeighborhoodM: Got %d neighbors\n", num_rn);
    if (num_rn == 0) {
      // Retry the radio neighborhood
      state = STATE_GET_RADIO_NEIGHBORS;
      if (!call RadioNeighborhood.getNeighborhood()) {
	dbg(DBG_USR2, "YaoNeighborhoodM: Unable to retry radio neighborhood\n");
	return;
      }
      dbg(DBG_USR2, "YaoNeighborhoodM: Retrying radio neighborhood\n");
      return;
    }
    for (n = 0; n < num_rn; n++) {
      add_neighbor(tmp_neighbors[n]);
    }
    for (n = 0; n < num_rn; n++) {
      outstanding_reads++;
      if (!call SV_location.get(neighbors[n].addr, &neighbors[n].loc, sizeof(neighbors[n].loc))) {
	dbg(DBG_USR2, "YaoNeighborhoodM: Unable to call SV_loc.get for neighbor %d\n", n);
	outstanding_reads--;
      }
    }
    dbg(DBG_USR2, "YaoNeighborhoodM: Initiated %d SV_loc reads\n", outstanding_reads);
    if (outstanding_reads == 0) {
      dbg(DBG_USR2, "YaoNeighborhoodM: Can't call SV_loc.get for any neighbor\n");
      state = STATE_IDLE;
      signal Neighborhood.getNeighborhoodDone(FAIL);
    }
    state = STATE_GET_NEIGHBOR_LOC;
    if (!call Timer.start(TIMER_ONE_SHOT, GET_LOCATION_TIMEOUT)) {
      dbg(DBG_USR2, "YaoNeighborhoodM: Can't start timer\n");
      state = STATE_IDLE;
      signal Neighborhood.getNeighborhoodDone(FAIL);
    }
  }

  double calc_dist(location_3d_t *loc) {
    double dist;
    dist = (loc->x - myLocation.x) * (loc->x - myLocation.x);
    dist += (loc->y - myLocation.y) * (loc->y - myLocation.y);
    return sqrt(dist);
  }

  double calc_angle(location_3d_t *loc) {
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

  int closest_neighbor(int sector) {
    float anglestart = SECTOR_ANGLE * sector;
    float angleend = SECTOR_ANGLE * (sector+1);
    int closest = -1;
    int n;

    dbg(DBG_USR2, "YaoNeighborhoodM: closest_neighbor(%d) angle %f -> %f\n", sector, anglestart, angleend);
    dbg(DBG_USR2, "YaoNeighborhoodM: myLocation (%f,%f)\n", myLocation.x, myLocation.y);

    for (n = 0; n < MAX_NEIGHBORS; n++) {
      dbg(DBG_USR2, "YaoNeighborhoodM: neighbor %d angle %f dist %f\n", neighbors[n].addr, neighbors[n].angle, neighbors[n].dist);
      if (neighbors[n].addr != EMPTY_ADDR &&
          neighbors[n].dist != -1.0 &&
	  neighbors[n].angle >= anglestart && 
	  neighbors[n].angle < angleend) {
	if (closest == -1) closest = n;
	else if (neighbors[n].dist < neighbors[closest].dist) closest = n;
      }
    }
    dbg(DBG_USR2, "YaoNeighborhoodM: closest is %d\n", neighbors[closest].addr);
    return closest;
  }

  int tridir(location_3d_t *p1, location_3d_t *p2, location_3d_t *p3) {
    int test = ((p2->x - p1->x)*(p3->y - p1->y)) - 
      ((p3->x - p1->x)*(p2->y - p1->y));
    if (test > 0) return COUNTER_CLOCKWISE;
    else if (test < 0) return CLOCKWISE;
    else return LINE;
  }

  bool crossing(uint16_t fromaddr, uint16_t toaddr) {
    struct neighbor *fromn = NULL, *ton = NULL;
    location_3d_t *l1p1, *l1p2, *l2p1, *l2p2;
    bool test1_a, test1_b, test2_a, test2_b;

    int n;
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (fromaddr == neighbors[n].addr) fromn = &neighbors[n];
      if (toaddr == neighbors[n].addr) ton = &neighbors[n];
    }
    if (fromn == NULL || ton == NULL) return FALSE;
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      int m;
      bool found = FALSE;
      l1p1 = &myLocation;
      l1p2 = &neighbors[n].loc; // Invalid
      if (neighbors[n].addr == EMPTY_ADDR) continue;
      if (neighbors[n].loc.x < 0.0) continue;
      for (m = 0; m < MAX_YAO_NEIGHBORS; m++) {
	if (chosen_neighbors[m] == neighbors[n].addr) found = TRUE;
      }
      if (!found) continue;

      l2p1 = &fromn->loc;
      if (l2p1->x < 0.0) continue; // Invalid
      l2p2 = &ton->loc;
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
	  dbg(DBG_USR2, "YaoNeighborhoodM: Edge %d -> %d crosses %d -> %d\n", 
	      fromaddr, toaddr, TOS_LOCAL_ADDRESS, neighbors[n].addr);
	  return TRUE;
	}
      }
    }
    return FALSE;
  }

  task void calcEdgesTask() {
    int n, s;
    int sector[MAX_YAO_NEIGHBORS];

    dbg(DBG_USR2, "YaoNeighborhoodM: calcEdgesTask running\n");

    for (n = 0; n < MAX_YAO_NEIGHBORS; n++) {
      sector[n] = -1;
    }

    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR &&
	  neighbors[n].loc.x != -1.0) {
	dbg(DBG_USR2, "YaoNeighborhoodM: neighbor %d loc (%f,%f)\n", neighbors[n].addr, neighbors[n].loc.x, neighbors[n].loc.y);
	neighbors[n].dist = calc_dist(&neighbors[n].loc);
	neighbors[n].angle = calc_angle(&neighbors[n].loc);
      }
    }

    // Pick closest neighbor in each sector
    for (s = 0; s < MAX_YAO_NEIGHBORS; s++) {
      sector[s] = closest_neighbor(s);
      dbg(DBG_USR2, "YaoNeighborhoodM: sector[%d] is %d\n", s, sector[s]);
      if (sector[s] != -1) {
	PickEdgeMsg *pick_msg = (PickEdgeMsg *)pick_packet[s].data;
	chosen_neighbors[s] = neighbors[sector[s]].addr;
	dbg(DBG_USR2, "YaoNeighborhoodM: Choosing edge %d -> %d\n", TOS_LOCAL_ADDRESS, chosen_neighbors[s]);
	pick_msg->fromaddr = TOS_LOCAL_ADDRESS;
	pick_msg->toaddr = chosen_neighbors[s];
	// Don't care if we push it out or not - assume it's ok
	call SendPickEdgeMsg.send(TOS_BCAST_ADDR, sizeof(PickEdgeMsg), &pick_packet[s]);
      }
    }

    dbg(DBG_USR2, "YaoNeighborhoodM: Waiting for invalidations\n");
    state = STATE_WAITING_INVALIDATIONS;
    if (!call Timer.start(TIMER_ONE_SHOT, SIGNAL_DONE_DELAY)) {
      dbg(DBG_USR2, "YaoNeighborhoodM: Can't start timer\n");
      state = STATE_IDLE;
      signal Neighborhood.getNeighborhoodDone(FAIL);
    }
  }

  void invalidate(uint16_t fromaddr, uint16_t toaddr) {
    InvalidateMsg *msg = (InvalidateMsg *)invalidate_packet.data;
    msg->fromaddr = fromaddr;
    msg->toaddr = toaddr;
    // Don't care if we push it out or not - assume it's ok
    dbg(DBG_USR2, "YaoNeighborhoodM: Invalidating %d -> %d\n", fromaddr, toaddr);
    call SendInvalidateMsg.send(fromaddr, sizeof(InvalidateMsg), &invalidate_packet);
  }

  /***********************************************************************
   * Timer
   ***********************************************************************/

  event result_t Timer.fired() {
    if (state == STATE_GET_NEIGHBOR_LOC) {
      dbg(DBG_USR2, "YaoNeighborhoodM: Timer fired, posting calcEdgesTask\n");
      post calcEdgesTask();
    } else if (state == STATE_WAITING_INVALIDATIONS) {
      dbg(DBG_USR2, "YaoNeighborhoodM: Timer fired, signaling done\n");
      state = STATE_DONE;
      signal Neighborhood.getNeighborhoodDone(SUCCESS);
    } 
    return SUCCESS;
  }

  /***********************************************************************
   * Neighborhood
   ***********************************************************************/

  command result_t Neighborhood.getNeighborhood() {
    dbg(DBG_USR2, "YaoNeighborhoodM: getNeighborhood(), state %d\n", state);
    if (state == STATE_DONE) signal Neighborhood.getNeighborhoodDone(SUCCESS);
    if (state != STATE_IDLE) return SUCCESS;
    state = STATE_GET_RADIO_NEIGHBORS;
    return call RadioNeighborhood.getNeighborhood();
  }

  command int Neighborhood.numNeighbors() {
    int n, count = 0;
    for (n = 0; n < MAX_YAO_NEIGHBORS; n++) {
      if (chosen_neighbors[n] != EMPTY_ADDR) count++;
    }
    dbg(DBG_USR2, "YaoNeighborhoodM: numNeighbors %d\n", count);
    return count;
  }

  command int Neighborhood.getNeighbors(uint16_t *buf, int size) {
    int n, count = 0;
    dbg(DBG_USR2, "YaoNeighborhoodM: getNeighbors called\n");
    for (n = 0; count < size && n < MAX_YAO_NEIGHBORS; n++) {
      dbg(DBG_USR2, "YaoNeighborhoodM: getNeighbors: n[%d] addr %d\n", n, chosen_neighbors[n]);
      if (chosen_neighbors[n] != EMPTY_ADDR) {
	buf[count] = chosen_neighbors[n];
	count++;
      }
    }
    dbg(DBG_USR2, "YaoNeighborhoodM: getNeighbors returning %d\n", count);
    return count;
  }


  /***********************************************************************
   * RadioNeighborhood
   ***********************************************************************/

  event void RadioNeighborhood.getNeighborhoodDone(result_t success) {
    dbg(DBG_USR2, "YaoNeighborhoodM: RN.getNeighborhoodDone\n");
    if (success == SUCCESS && state == STATE_GET_RADIO_NEIGHBORS) {
      dbg(DBG_USR2, "YaoNeighborhoodM: posting getLocationTask\n");
      rn_ready = TRUE;
      post getLocationTask();
    } else if (state == STATE_GET_RADIO_NEIGHBORS) {
      // Try to get radio neighborhood again
      dbg(DBG_USR2, "YaoNeighborhoodM: Retrying getNeighborhood\n");
      if (!call RadioNeighborhood.getNeighborhood()) {
	dbg(DBG_USR2, "YaoNeighborhoodM: Can't call getNeighborhood\n");
	state = STATE_IDLE;
	signal Neighborhood.getNeighborhoodDone(FAIL);
      }
    }
  }

  /***********************************************************************
   * Location
   ***********************************************************************/

  // This will be signaled periodically e.g., if the application 
  // calls getLocation()
  event void Location.locationDone(location_3d_t *loc) {
    dbg(DBG_USR2, "YaoNeighborhoodM: locationDone\n");
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
	if (!call SV_location.put(&myLocation, sizeof(myLocation))) {
  	  dbg(DBG_USR2, "YaoNeighborhoodM: Can't put SV_location\n");
   	}
      }
    } else {
      // Try to get location again
      dbg(DBG_USR2, "YaoNeighborhoodM: Retrying getLocation\n");
      if (!call Location.getLocation()) {
       	dbg(DBG_USR1, "YaoNeighborhoodM: Can't call getLocation\n");
      }
    }
  }

  /***********************************************************************
   * SharedVar
   ***********************************************************************/

  event void SV_location.getDone(uint16_t moteaddr, void *buf, int buflen, result_t success) {
    if (state == STATE_GET_NEIGHBOR_LOC) {
      if (--outstanding_reads == 0) post calcEdgesTask();
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
    if (crossing(msg->fromaddr, msg->toaddr)) {
      invalidate(msg->fromaddr, msg->toaddr);
    }
    return recv_packet;
  }

  event TOS_MsgPtr ReceiveInvalidateMsg.receive(TOS_MsgPtr recv_packet) {
    InvalidateMsg *msg = (InvalidateMsg *)recv_packet->data;
    dbg(DBG_USR2, "YaoNeighborhoodM: Got invalidate msg\n");
    if (state == STATE_WAITING_INVALIDATIONS) {
      if (msg->fromaddr == TOS_LOCAL_ADDRESS) {
	int n;
        dbg(DBG_USR2, "YaoNeighborhoodM: Invalidating local edge %d -> %d\n", msg->fromaddr, msg->toaddr);
	for (n = 0; n < MAX_YAO_NEIGHBORS; n++) {
	  if (chosen_neighbors[n] == msg->toaddr) 
	    chosen_neighbors[n] = EMPTY_ADDR;
	}
      }
    }
    return recv_packet;
  }


}
