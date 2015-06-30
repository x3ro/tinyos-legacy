includes TupleSpace;
includes KNearestRegion;
includes TuningKeys;
includes Location2D;

module KNRegionM {
  provides {
    interface StdControl;
    interface Region;
  }
  uses {
    interface Tuning;
    interface Timer;
    interface SendMsg;
    interface ReceiveMsg;
    interface Leds;
    interface Location2D;
  }

} implementation {

  // Default values
  enum {
    EMPTY_ADDR = 0xffff,
    BAD_LOCATION = 0xffff,
    DEFAULT_TIMER_RATE = 1000,
    DEFAULT_TIMER_PENDING_COUNT = 10,
    DEFAULT_AGE_THRESHOLD = 4,
    TIMER_BEACON_COUNT = 1,
    TIMER_AGE_COUNT = 20,
    DEFAULT_MAX_NEIGHBORS = KNEARESTREGION_MAX_NEIGHBORS,
  }; 

  tuning_value_t age_threshold, timer_rate, timer_pending_count;
  bool pending, timer_started;
  int pending_count;
  int timer_ticks;
  struct TOS_Msg beacon_packet;
  bool send_busy;
  location_2d_t myLocation;
  bool region_formed;
  int max_neighbors;

  struct neighbor {
    uint16_t addr;
    uint8_t age;
    location_2d_t loc;
  } neighbors[KNEARESTREGION_MAX_NEIGHBORS];
  uint16_t exported_neighbors[KNEARESTREGION_MAX_NEIGHBORS];

  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY_ADDR;
    neighbor->age = 0;
    neighbor->loc.x = BAD_LOCATION;
  }

  static result_t initialize() {
    int n;
    dbg(DBG_USR2, "KNRegionM: initialize\n");
    for (n = 0; n < KNEARESTREGION_MAX_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    timer_ticks = 0;
    myLocation.x = BAD_LOCATION;
    send_busy = pending = timer_started = region_formed = FALSE;

    if (!call Tuning.getDefault(KEY_RADIOREGION_AGE_THRESHOLD, &age_threshold,
	  DEFAULT_AGE_THRESHOLD)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_RADIOREGION_TIMER_PENDING_COUNT, 
	  &timer_pending_count, DEFAULT_TIMER_PENDING_COUNT)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_KNEARESTREGION_MAX_NEIGHBORS, &max_neighbors, 
	  DEFAULT_MAX_NEIGHBORS)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_RADIOREGION_TIMER_RATE, &timer_rate, 
	  DEFAULT_TIMER_RATE)) {
      return FAIL;
    }
    return SUCCESS;
  }

  /***********************************************************************
   * StdControl
   ***********************************************************************/

  command result_t StdControl.init() {
    return initialize();
  }

  command result_t StdControl.start() {
    if (!call Location2D.getLocation()) {
      return FAIL;
    }
    timer_started = TRUE;
    if (!call Timer.start(TIMER_REPEAT, (uint16_t)timer_rate)) {
      timer_started = FALSE;
    }
    return timer_started?SUCCESS:FAIL;
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  } 

  /***********************************************************************
   * Location2D
   ***********************************************************************/
  event void Location2D.getLocationDone(location_2d_t *loc) {
    if (loc != NULL) {
      myLocation.x = loc->x;
      myLocation.y = loc->y;
    } else {
      // Try to get location again
      dbg(DBG_USR2, "KNRegionM: Retrying getLocation\n");
      call Location2D.getLocation();
    }
  }

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  double calc_dist(location_2d_t *loc) {
    double dist;
    dist = ((loc->x - (myLocation.x * 1.0)) * (loc->x - (myLocation.x * 1.0)));
    dist += ((loc->y - (myLocation.y * 1.0)) * (loc->y - (myLocation.y * 1.0)));
    return sqrt(dist);
  }

  static void add_neighbor(uint16_t addr, location_2d_t *loc) {
    int n;
    double max_dist = -1.0;
    int max_entry = -1;

    dbg(DBG_USR2, "KNRegionM: add_neighbor %d (%d,%d), my loc (%d,%d), dist %.2f\n", addr, loc->x, loc->y, myLocation.x, myLocation.y, calc_dist(loc));

    /* Mark existing slot */
    for (n = 0; n < max_neighbors; n++) {
      if (neighbors[n].addr == addr) {
	neighbors[n].age = 0;
	dbg(DBG_USR2, "KNRegionM: add_neighbor marking existing\n");
	return;
      }
    }

    /* Find empty slot */
    for (n = 0; n < max_neighbors; n++) {
      if (neighbors[n].addr == EMPTY_ADDR)  {
	neighbors[n].addr = addr;
	memcpy(&neighbors[n].loc, loc, sizeof(*loc));
	neighbors[n].age = 0;
	dbg(DBG_USR2, "KNRegionM: add_neighbor adding to empty slot\n");
	return;
      }
    }

    /* Evict */
    if (myLocation.x == BAD_LOCATION) return; // Drop if no location yet
    for (n = 0; n < max_neighbors; n++) {
      double d = calc_dist(&neighbors[n].loc);
      if (d > max_dist) {
	max_dist = d; max_entry = n;
      }
    }
    dbg(DBG_USR2, "KNRegionM: max_dist %.2f (node %d)\n", max_dist, neighbors[max_entry].addr);
    if (max_dist != -1.0 && max_dist > calc_dist(loc)) {
      neighbors[max_entry].addr = addr;
      memcpy(&neighbors[max_entry].loc, loc, sizeof(*loc));
      dbg(DBG_USR2, "KNRegionM: evicting\n");
      neighbors[max_entry].age = 0;
    }
  }

  static void neighbor_timeout() {
    int n;
    for (n = 0; n < max_neighbors; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) {
	if (++neighbors[n].age >= (int)age_threshold) {
	  dbg(DBG_USR2, "KNRegionM: timing out neighbor %d\n", neighbors[n].addr);
	  init_neighbor(&neighbors[n]);
	}
      }
    }
  }

  static void send_beacon() {
    KNearestRegion_BeaconMsg *send_msg = (KNearestRegion_BeaconMsg *)beacon_packet.data;
    if (!send_busy) {
      send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
      memcpy(&send_msg->loc, &myLocation, sizeof(myLocation));
      send_busy = TRUE;
      if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(KNearestRegion_BeaconMsg), &beacon_packet) == SUCCESS) {
	send_busy = FALSE;
      }
    }
  }

  /***********************************************************************
   * Region
   ***********************************************************************/

  command result_t Region.getRegion() {
    dbg(DBG_USR1,"KNRegionM: getRegion: formed %d timer_started %d pending %d\n", region_formed, timer_started, pending);
    if (region_formed) {
      signal Region.getDone(SUCCESS);
      return SUCCESS;
    } else {
      pending = TRUE;
      pending_count = 0;
      if (!timer_started) {
       	timer_started = TRUE;
	dbg(DBG_USR1,"KNRegionM: Timer rate %d\n", (uint16_t)timer_rate);
	if (!call Timer.start(TIMER_REPEAT, (uint16_t)timer_rate)) {
  	  timer_started = FALSE;
	  pending = FALSE;
   	}
	dbg(DBG_USR1,"KNRegionM: getRegion: tried to start timer, returning %d\n", timer_started);
    	return timer_started?SUCCESS:FAIL;
      } else {
      	return SUCCESS;
      }
    }
  }

  command int Region.numNodes() {
    int n, count = 0;
    for (n = 0; n < max_neighbors; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) count++;
    }
    return count;
  }

  command int Region.getNodes(uint16_t **node_list_ptr) {
    int count = 0;
    int n;
    for (n = 0; n < max_neighbors; n++) {
      dbg(DBG_USR2, "KNRegionM: getNodes: n[%d] addr %d\n", n, neighbors[n].addr);
      exported_neighbors[count] = neighbors[n].addr;
      if (neighbors[n].addr != EMPTY_ADDR) count++;
    }
    dbg(DBG_USR2, "KNRegionM: getNodes returning %d\n", count);
    *node_list_ptr = exported_neighbors;
    return count;
  }

  /***********************************************************************
   * Timer
   ***********************************************************************/

  event result_t Timer.fired() {
    timer_ticks++;

    dbg(DBG_USR2,"KNRegionM: ticks %d pending %d pending_count %d pcthresh %d\n", timer_ticks, pending, pending_count, timer_pending_count);


    if (timer_ticks % TIMER_BEACON_COUNT == 0) {
      send_beacon();
    }

    if (timer_ticks % TIMER_AGE_COUNT == 0) {
      neighbor_timeout();
    }

    if (pending && ++pending_count >= (int)timer_pending_count) {
      pending = FALSE;
      region_formed = TRUE;
      call Timer.stop();
      signal Region.getDone(SUCCESS);
      timer_started = FALSE;
    }
    return SUCCESS;
  }

  /***********************************************************************
   * Communication
   ***********************************************************************/

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    KNearestRegion_BeaconMsg *beacon_msg = (KNearestRegion_BeaconMsg *)recv_packet->data;
    uint16_t addr = beacon_msg->sourceaddr;
    call Leds.yellowToggle();
    dbg(DBG_USR2, "KNRegionM: beacon received from %d at %d,%d\n", addr, beacon_msg->loc.x, beacon_msg->loc.y);

    if (addr != TOS_LOCAL_ADDRESS) {
      add_neighbor(addr, &beacon_msg->loc);
    }
    return recv_packet;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    //dbg(DBG_USR2, "KNRegionM: sendDone\n");
    send_busy = FALSE;
    return SUCCESS;
  }

}
