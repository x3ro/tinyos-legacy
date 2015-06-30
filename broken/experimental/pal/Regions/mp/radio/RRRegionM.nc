includes TupleSpace;
includes RadioRegion;
includes TuningKeys;

module RRRegionM {
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
  }

} implementation {

  // Default values
  enum {
    EMPTY_ADDR = 0xffff,
    DEFAULT_TIMER_RATE = 1000,
    DEFAULT_AGE_THRESHOLD = 4,
    TIMER_BEACON_COUNT = 2,
    TIMER_AGE_COUNT = 20,
    TIMER_PENDING_COUNT = 10,
  }; 

  tuning_value_t age_threshold, timer_rate;
  bool region_formed, pending, timer_started;
  int pending_count;
  int timer_ticks;
  struct TOS_Msg beacon_packet;
  bool send_busy;

  struct neighbor {
    uint16_t addr;
    uint8_t age;
  } neighbors[RADIOREGION_MAX_NEIGHBORS];
  uint16_t exported_neighbors[RADIOREGION_MAX_NEIGHBORS];

  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY_ADDR;
    neighbor->age = 0;
  }

  static void initialize() {
    int n;
    //dbg(DBG_USR2, "RRRegionM: initialize\n");
    for (n = 0; n < RADIOREGION_MAX_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    timer_ticks = 0;
    region_formed = send_busy = pending = timer_started = FALSE;
  }

  /***********************************************************************
   * StdControl
   ***********************************************************************/

  command result_t StdControl.init() {
    initialize();
    //dbg(DBG_USR1, "RRRegionM: initialized.\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    //dbg(DBG_USR1, "RRRegionM: starting.\n");
    if (!call Tuning.getDefault(KEY_RADIOREGION_AGE_THRESHOLD, &age_threshold,
	  DEFAULT_AGE_THRESHOLD)) {
      return FAIL;
    }
    if (call Tuning.getDefault(KEY_RADIOREGION_TIMER_RATE, &timer_rate, 
	  DEFAULT_TIMER_RATE)) {
      timer_started = TRUE;
      if (!call Timer.start(TIMER_REPEAT, (uint16_t)timer_rate)) {
	timer_started = FALSE;
      }
      return timer_started?SUCCESS:FAIL;
    } else {
      return FAIL;
    }
  }

  command result_t StdControl.stop() {
    //dbg(DBG_USR1, "RRRegionM: stopping.\n");
    return call Timer.stop();
  } 

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  default event void Region.getDone(result_t success) { 
    // Empty
  }

  static void add_neighbor(uint16_t addr) {
    int n;
    for (n = 0; n < RADIOREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	neighbors[n].age = 0;
	return;
      }
    }
    for (n = 0; n < RADIOREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY_ADDR)  {
	neighbors[n].addr = addr;
	neighbors[n].age = 0;
	break;
      }
    }
    if (pending && call Region.numNodes() == RADIOREGION_MAX_NEIGHBORS) {
      call Timer.stop();
      region_formed = TRUE;
      pending = FALSE;
      timer_started = FALSE;
      signal Region.getDone(SUCCESS);
    }
  }

  static void neighbor_timeout() {
    int n;
    for (n = 0; n < RADIOREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) {
	if (++neighbors[n].age >= (int)age_threshold) {
	  //dbg(DBG_USR1, "RRRegionM: timing out neighbor %d\n", neighbors[n].addr);
	  init_neighbor(&neighbors[n]);
	}
      }
    }
  }

  static void send_beacon() {
    RadioRegion_BeaconMsg *send_msg = (RadioRegion_BeaconMsg *)beacon_packet.data;
    if (!send_busy) {
      send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
      if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(RadioRegion_BeaconMsg), &beacon_packet) == SUCCESS) {
	send_busy = TRUE;
      }
    }
  }

  /***********************************************************************
   * Region
   ***********************************************************************/

  
  task void regionDoneTask() {
    signal Region.getDone(SUCCESS);
  }

  command result_t Region.getRegion() {
    //dbg(DBG_USR1, "RRRegionM: getRegion: ");
    if (!region_formed) {
      dbg_clear(DBG_USR1, " forming region.\n");
      pending = TRUE;
      pending_count = 0;
      if (!timer_started) {
	timer_started = TRUE;
	if (!call Timer.start(TIMER_REPEAT, (uint16_t)timer_rate)) {
	  timer_started = FALSE;
	}
	return timer_started?SUCCESS:FAIL;
      } else {
	// Timer already started
       	return SUCCESS;
      }
    } else {
      post regionDoneTask();
      dbg_clear(DBG_USR1, " already formed.\n");
      return SUCCESS;
    }
  }

  command int Region.numNodes() {
    int n, count = 0;
    if (!region_formed) return 0;
    for (n = 0; n < RADIOREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) count++;
    }
    return count;
  }

  command int Region.getNodes(uint16_t **node_list_ptr) {
    int count = 0;
    int n;
    if (!region_formed) return 0;
    for (n = 0; n < RADIOREGION_MAX_NEIGHBORS; n++) {
      //dbg(DBG_USR1, "RRRegionM: getNodes: n[%d] addr %d\n", n, neighbors[n].addr);
      exported_neighbors[n] = neighbors[n].addr;
      if (neighbors[n].addr != EMPTY_ADDR) count++;
    }
    //dbg(DBG_USR1, "RRRegionM: getNodes returning %d\n", count);
    *node_list_ptr = exported_neighbors;
    return count;
  }

  /***********************************************************************
   * Timer
   ***********************************************************************/

  event result_t Timer.fired() {
    timer_ticks++;
    //dbg(DBG_USR1, "RRRegionM: Timer fired: timer ticks %i, pending %i, pending count %i.\n", (int)timer_ticks, (int)pending, (int)pending_count);
    if (timer_ticks % TIMER_BEACON_COUNT == 0) {
      send_beacon();
    }

    if (timer_ticks % TIMER_AGE_COUNT == 0) {
      neighbor_timeout();
    }

    if (pending && ++pending_count >= TIMER_PENDING_COUNT) {
      pending = FALSE;
      region_formed = TRUE;
      timer_started = FALSE;
      call Timer.stop();
      //dbg(DBG_USR1, "RRRegionM: Completed region.\n");
      signal Region.getDone(SUCCESS);
    }
    return SUCCESS;
  }

  /***********************************************************************
   * Communication
   ***********************************************************************/

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    RadioRegion_BeaconMsg *beacon_msg = (RadioRegion_BeaconMsg *)recv_packet->data;
    uint16_t addr = beacon_msg->sourceaddr;
    call Leds.yellowToggle();
    //dbg(DBG_USR1, "RRRegionM: beacon received from %d\n", addr);

    if (addr != TOS_LOCAL_ADDRESS) {
      add_neighbor(addr);
    }
    return recv_packet;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    //dbg(DBG_USR1, "RRRegionM: sendDone\n");
    send_busy = FALSE;
    return SUCCESS;
  }

}
