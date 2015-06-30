/* 
 * Author: Matt Welsh
 * Last updated: 1 Nov 2002
 * 
 */

includes AM;
includes Multihop;

/**
 * 
 **/
module MultihopM {
  provides {
    interface StdControl;
    interface Send;
    event void sendFail(uint16_t destaddr);
    event void sendSucceed(uint16_t destaddr);
  }
  uses {
    interface Timer;
    interface Leds;
    interface ReceiveMsg;
    interface SendMsg;
    interface CommControl;
    interface Random;
    interface StdControl as Sounder;
  }
}
implementation {

  enum {
    NUM_NEIGHBORS = 16,                // Total # neighbors
    TIMER_GETADC_COUNT = 1,            // Timer ticks for ADC 
    TIMER_NEIGHBOR_TIMEOUT_COUNT = 3,  // Timer ticks for neighbor timeout
    TIMER_PLQ_UPDATE_COUNT = 5,        // Timer ticks for PLQ update
    TIMER_CHIRP_COUNT = 10,            // Timer on/off chirp count
    PARENT_THRESHOLD = 20,             // Parent link quality threshold
    ROOT_BEACON_THRESHOLD = 50,        // PLQ threshold for choosing root
    TIMEOUT_SCALE = 10,                // Number of 'failed' recv per timeout
    TIMEOUT_THRESHOLD = 10,            // Clear out neighbor after this many
    AGE_THRESHOLD = 30,                // Clear goodness after this many
    GOODNESS_THRESHOLD = 30,           // Neighbor must be this good
    CMD_BROADCAST_THRESHOLD = 5,       // Max # times to broadcast a cmd
    MAX_SEQNO_GAP = 20,		       // Max seqno gap
  };

  struct neighbor {
    uint16_t addr;
    uint8_t hopcount;
    uint8_t age;
    uint8_t timeouts;
    uint8_t recv_count;
    uint8_t fail_count;
    uint8_t last_seqno;
    bool is_child;
    uint8_t goodness;
  } neighbors[NUM_NEIGHBORS];

  uint16_t my_parent;
  uint8_t my_hopcount;
  int parent_xmit_success;
  int parent_xmit_fail;
  int parent_link_quality;

  bool send_busy;
  uint8_t cur_seqno;
  struct TOS_Msg adc_packet, forward_packet;
  uint16_t sensor_reading;
  int timer_rate;
  int timer_ticks;
  uint32_t debug_code;
  uint8_t update_count;
  uint8_t cmd_broadcast_count;
  uint8_t last_cmd_type;

  /***********************************************************************
   * Initialization 
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY;
    neighbor->hopcount = 0;
    neighbor->timeouts = 0;
    neighbor->age = 0;
    neighbor->recv_count = 0;
    neighbor->fail_count = 0;
    neighbor->last_seqno = 0;
    neighbor->is_child = FALSE;
    neighbor->goodness = 0;
  }

  static void initialize() {
    int n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }

    timer_rate = INITIAL_TIMER_RATE;
    send_busy = FALSE;
    cur_seqno = 0;
    my_parent = EMPTY;
    my_hopcount = INITIAL_HOPCOUNT;
    parent_xmit_success = 0;
    parent_xmit_fail = 0;
    parent_link_quality = -1;
    timer_ticks = 0;
    debug_code = 0;
    update_count = 0;
    cmd_broadcast_count = 0;
    last_cmd_type = 0;
  }

  command result_t StdControl.init() {
    initialize();
    call Random.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.setPromiscuous(TRUE);
    return call Timer.start(TIMER_REPEAT, timer_rate);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  static void calc_goodness(struct neighbor *neighbor) {
    int fail;
    if (neighbor->addr == EMPTY) return;
    fail = neighbor->fail_count + (TIMEOUT_SCALE * neighbor->timeouts);
    if (neighbor->recv_count+fail == 0) {
      neighbor->goodness = 100;
    } else {
      neighbor->goodness = (int)((neighbor->recv_count * 1.0) / ((neighbor->recv_count + fail) * 1.0) * 100.0);
    }
  }

  task void route_update() {
    int best = -1, best_goodness = 0, best_hopcount = 255, n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      calc_goodness(&neighbors[n]);
    }

    // First pass: min hopcount
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if ((neighbors[n].addr != EMPTY) &&
	  (neighbors[n].goodness > GOODNESS_THRESHOLD) &&
	  (neighbors[n].is_child == FALSE)) {
	if (neighbors[n].hopcount < best_hopcount) {
	  best_hopcount = neighbors[n].hopcount;
	}
      }
    }

    // Second pass: max goodness
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if ((neighbors[n].addr != EMPTY) &&
	  (neighbors[n].hopcount == best_hopcount) &&
	  (neighbors[n].goodness > GOODNESS_THRESHOLD) &&
	  (neighbors[n].is_child == FALSE)) {
	if (neighbors[n].goodness > best_goodness) {
	  best_goodness = neighbors[n].goodness;
	  best = n;
	}
      }
    }
    if (best != -1) {
      my_parent = neighbors[best].addr;
      my_hopcount = neighbors[best].hopcount + 1;
      parent_xmit_success = 0;
      parent_xmit_fail = 0;
      parent_link_quality = -1;
      update_count++;
      debug_code = ((unsigned long)42) << 24;
      debug_code |= ((unsigned long)best) << 16;
      debug_code |= ((unsigned long)best_goodness) << 8;
      debug_code |= (update_count & 0xff);
    }
    // Note - might not have found a parent!
  }

  static void neighbor_timeout() {
    int n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY) {
	if (++neighbors[n].timeouts >= TIMEOUT_THRESHOLD) {
	  // Clear out neighbor
	  neighbors[n].addr = EMPTY; 
	}
	if (++neighbors[n].age >= AGE_THRESHOLD) {
	  // Clear out goodness
	  neighbors[n].recv_count = neighbors[n].fail_count = 0;
	}
      }
    }
  }

  static void calc_plq() {
    int newplq;
    if (parent_xmit_success+parent_xmit_fail == 0) {
      // If nothing has happened, don't recalculate
      return;
    } else {
      newplq = (int)((parent_xmit_success * 1.0) / ((parent_xmit_success + parent_xmit_fail)*1.0) * 100);
    }
    if (parent_link_quality == -1) {
      // Initially, set plq to newplq
      parent_link_quality = newplq;
    } else {
      // EWMA
      parent_link_quality = (int)((newplq * PARENT_LINK_QUALITY_ALPHA) + (parent_link_quality * (1.0 - PARENT_LINK_QUALITY_ALPHA)));
    }
    parent_xmit_success = 0;
    parent_xmit_fail = 0;
    if (parent_link_quality < PARENT_THRESHOLD) post route_update();
  }

  static void enforce_parent() {
    parent_xmit_success++;
  }

  static void discourage_parent() {
    parent_xmit_fail++;
  }

  static struct neighbor *get_neighbor(uint16_t addr, bool evict) {
    int n;
    int victim;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	return &neighbors[n];
      }
    }
    if (!evict) return NULL;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY) {
        init_neighbor(&neighbors[n]);
        neighbors[n].addr = addr;
	return &neighbors[n];
      }
    }
    // None empty - try to evict. Don't care if we evict our parent!
    victim = (call Random.rand()) % NUM_NEIGHBORS;
    init_neighbor(&neighbors[victim]);
    neighbors[victim].addr = addr;
    return &neighbors[victim];
  }

  static void link_update(MultihopMsg *msg) {
    // First update status for sourceaddr (link-level)
    struct neighbor *neighbor = get_neighbor(msg->sourceaddr, TRUE);
    neighbor->timeouts = 0;
    neighbor->recv_count++;
    if (neighbor->recv_count > 1) {
      // Not the first message from this neighbor - avoid large miss penalty
      // if last_seqno is incorrect

      // Drop neighbor if seqno gap is too large
      // (avoid overflow and force periodic refresh)
      if (msg->seqno - neighbor->last_seqno > MAX_SEQNO_GAP) {
	neighbor->addr = EMPTY;
	return;
      }
      neighbor->fail_count += (msg->seqno - neighbor->last_seqno);
    }
    neighbor->last_seqno = msg->seqno;

    // Now update status for originaddr (global)
    neighbor = get_neighbor(msg->originaddr, TRUE);
    neighbor->hopcount = msg->hopcount;
    neighbor->is_child = (msg->parentaddr == TOS_LOCAL_ADDRESS)?TRUE:FALSE;
  }

  static void break_cycle() {
    struct neighbor *neighbor = get_neighbor(my_parent, FALSE);
    if (neighbor != NULL) {
      neighbor->is_child = TRUE;
    }
    // Drop our parent
    my_parent = EMPTY;
    my_hopcount = INITIAL_HOPCOUNT;
    parent_xmit_success = 0;
    parent_xmit_fail = 0;
    parent_link_quality = -1;
    post route_update();
  }


  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  event result_t Timer.fired() {
    timer_ticks++;

    if (timer_ticks % TIMER_NEIGHBOR_TIMEOUT_COUNT == 0) {
      neighbor_timeout();
    }
    if (timer_ticks % TIMER_PLQ_UPDATE_COUNT == 0) {
      calc_plq();
    }
    return SUCCESS;
  }

  static void forward(uint16_t destaddr, MultihopMsg *recv_msg) {
    MultihopMsg *send_msg = (MultihopMsg *)forward_packet.data;
    if (send_busy) return; // Drop if busy
    memcpy(send_msg, recv_msg, sizeof(MultihopMsg));
    send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
    send_msg->seqno = cur_seqno++;
      // Queued send returns FAIL if concurrent enqueues are happening -
      // just drop message in that case. 
    if (call SendMsg.send(destaddr, sizeof(MultihopMsg), &forward_packet) == SUCCESS) {
      send_busy = TRUE;
    }
  }

  static void broadcast_cmd(MultihopMsg *recv_msg) {
    if (recv_msg->type != last_cmd_type) {
      cmd_broadcast_count = 0;
      last_cmd_type = recv_msg->type;
    }
    if (++cmd_broadcast_count < CMD_BROADCAST_THRESHOLD) {
      forward(TOS_BCAST_ADDR, recv_msg);
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    MultihopMsg *recv_msg = (MultihopMsg *)recv_packet->data;
    call Leds.yellowToggle();

    // Drop messages from ourselves
    if (recv_msg->originaddr == TOS_LOCAL_ADDRESS) {
      // Is this a cycle? Our parent is not a "direct" child, but 
      // let's invalidate it and do a route update.
      if (recv_packet->addr == TOS_LOCAL_ADDRESS) {
	break_cycle();
      }
      return recv_packet;
    }

    // If this is a root beacon...
    if (recv_msg->type == MULTIHOP_TYPE_ROOTBEACON) {
      if ((parent_link_quality == -1 || 
	    parent_link_quality < ROOT_BEACON_THRESHOLD) &&
	  (recv_msg->hopcount < my_hopcount) &&
	  (my_parent != recv_msg->sourceaddr)) {
	my_parent = recv_msg->sourceaddr;
	my_hopcount = recv_msg->hopcount+1;
	parent_xmit_success = 0;
	parent_xmit_fail = 0;
	parent_link_quality = -1;
	debug_code = 0x69; // Assigned parent from root beacon
      }
      // Don't forward it
      return recv_packet;
    }

    // Update link information
    link_update(recv_msg);

    // If no parent, pick one
    if (my_parent == EMPTY) post route_update();

    // Forward if it was destined for us
    if (recv_packet->addr == TOS_LOCAL_ADDRESS && my_parent != EMPTY) {
      forward(my_parent, recv_msg);
    }

    return recv_packet;
  }

  event void sendFail(uint16_t destaddr) {
    if (destaddr == my_parent) {
      call Leds.redOn();
      discourage_parent();
    }
  }

  event void sendSucceed(uint16_t destaddr) {
    if (destaddr == my_parent) {
      call Leds.redOff();
      enforce_parent();
    }
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    send_busy = FALSE;
    signal Send.sendDone(msg, success);
    return SUCCESS;
  }

  /* For Send interface */
  command result_t Send.send(TOS_MsgPtr msg, uint16_t length) {
    MultihopMsg *send_msg = (MultihopMsg *)msg->data;

    // Don't send if no parent yet
    if (my_parent == EMPTY) return FAIL;
    // Don't send if busy
    if (send_busy) return FAIL;

    send_msg->type = MULTIHOP_TYPE_USERDATA;
    send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
    send_msg->originaddr = TOS_LOCAL_ADDRESS;
    send_msg->parentaddr = my_parent;
    send_msg->hopcount = my_hopcount;
    send_msg->seqno = cur_seqno++;
    send_msg->parent_link_quality = parent_link_quality;
    send_msg->debug_code = debug_code;

    // Queued send returns FAIL if concurrent enqueues are happening -
    // just drop message in that case. 
    if (call SendMsg.send(my_parent, sizeof(MultihopMsg), msg) == SUCCESS) {
      send_busy = TRUE;
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  /* For Send interface */
  command uint8_t* Send.getBuffer(TOS_MsgPtr msg, uint16_t *length) {
    MultihopMsg *user_msg = (MultihopMsg *)msg->data;
    *length = sizeof(user_msg->user_data);
    return (uint8_t *)&(user_msg->user_data);
  }

}


