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

/**
 * This module implements an adaptive spanning tree construction and
 * maintenance algorithm based on the Surge3 codebase. It supports multiple
 * concurrent spanning trees from different root nodes.
 *
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

includes TupleSpace;
includes SpanTreeRegion;
includes TuningKeys;

module STRegionM {
  provides {
    interface StdControl;
    interface Region;
    interface SendMsg as SendToParent;
    interface SendMsg as SendToRoot;
    interface ReceiveMsg as ReceiveAtParent;
    interface ReceiveMsg as ReceiveAtRoot;
  }
  uses {
    interface Tuning;
    interface Timer;
    interface SendMsg as SendBeacon;
    interface SendMsg as SendParent;
    interface SendMsg as SendRoot;
    interface ReceiveMsg as ReceiveBeacon;
    interface ReceiveMsg as ReceiveParent;
    interface ReceiveMsg as ReceiveRoot;
    interface CommControl;
    interface Random;
  }

} implementation {

  char *color_strings[] = { "0xf00000", "0x00a000", "0x0000a0", "0xf000f0" };

  // Default values
  enum {
    MAX_TREES = 4,			// Max number of simultaneous trees
    EMPTY_ADDR = 0xffff, 
    DEFAULT_TIMER_RATE = 1000,
    DEFAULT_TIMER_PENDING_COUNT = 20,
    DEFAULT_AGE_THRESHOLD = 30,
    TIMER_BEACON_COUNT = 1,
    TIMER_AGE_COUNT = 1,
    DEFAULT_MAX_NEIGHBORS = SPANTREEREGION_MAX_NEIGHBORS,
    INITIAL_HOPCOUNT = 64,
    TIMEOUT_SCALE = 1,
    GOODNESS_THRESHOLD = 30,           // Neighbor must be this good
    PARENT_THRESHOLD = 20,             // Parent link quality threshold
    TIMEOUT_THRESHOLD = 10,            // Clear out neighbor after this many
    MAX_SEQNO_GAP = 20,                // Max seqno gap
    ROOT_BEACON_THRESHOLD = 50,        // PLQ threshold for choosing root
  }; 
  double PARENT_LINK_QUALITY_ALPHA = 0.8;

  // State for each neighbor
  struct neighbor {
    uint16_t addr;
    uint16_t root;
    uint8_t age;
    uint8_t timeouts;
    uint8_t recv_count;
    uint8_t fail_count;
    uint8_t last_seqno;
    uint8_t goodness;
  } neighbors[SPANTREEREGION_MAX_NEIGHBORS];
  uint16_t exported_neighbors[SPANTREEREGION_MAX_NEIGHBORS];

  // State for each spanning tree
  struct tree_state {
    char *color_string; // For DIRECTED GRAPH only
    uint16_t root;
    uint16_t parent;
    uint8_t hopcount;
    int parent_xmit_success;
    int parent_xmit_fail;
    int parent_link_quality;
    uint8_t seqno;

    struct treeneighbor {
      struct neighbor *nbr;
      uint8_t hopcount;  // Hopcount of this nbr in this tree
      bool is_child;	 // Whether this nbr is a child in this tree
    } neighbors[SPANTREEREGION_MAX_NEIGHBORS];

  } treestate[MAX_TREES];

  tuning_value_t age_threshold, timer_rate, timer_pending_count;
  bool initialized, is_root, pending, timer_started;
  int pending_count;
  int timer_ticks;
  struct TOS_Msg beacon_packet, route_packet, root_packet;
  bool sendBeacon_busy, sendParent_busy, sendRoot_busy;
  bool region_formed;
  int max_neighbors;
  uint8_t cur_seqno;

  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void init_tree(struct tree_state *tree) {
    int n;
    tree->root = tree->parent = EMPTY_ADDR;
    tree->hopcount = INITIAL_HOPCOUNT;
    tree->seqno = 0;
    tree->parent_xmit_success = 0;
    tree->parent_xmit_fail = 0;
    tree->parent_link_quality = -1;
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      tree->neighbors[n].nbr = &neighbors[n];
      tree->neighbors[n].hopcount = INITIAL_HOPCOUNT;
      tree->neighbors[n].is_child = FALSE;
    }
  }

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY_ADDR;
    neighbor->root = EMPTY_ADDR;
    neighbor->age = 0;
    neighbor->timeouts = 0;
    neighbor->recv_count = 0;
    neighbor->fail_count = 0;
    neighbor->last_seqno = 0;
    neighbor->goodness = 0;
  }

  static result_t initialize() {
    int n;
    dbg(DBG_USR2, "STRegionM: initialize\n");
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    for (n = 0; n < MAX_TREES; n++) {
      init_tree(&treestate[n]);
      treestate[n].color_string = color_strings[n];
    }

    sendBeacon_busy = FALSE;
    cur_seqno = 0;
    timer_ticks = 0;
    sendBeacon_busy = sendParent_busy = sendRoot_busy = FALSE;
    is_root = pending = timer_started = region_formed = FALSE;

    if (!call Tuning.getDefault(KEY_RADIOREGION_AGE_THRESHOLD, &age_threshold,
	  DEFAULT_AGE_THRESHOLD)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_SPANTREEREGION_TIMER_PENDING_COUNT, 
	  &timer_pending_count, DEFAULT_TIMER_PENDING_COUNT)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_SPANTREEREGION_MAX_NEIGHBORS, &max_neighbors, 
	  DEFAULT_MAX_NEIGHBORS)) {
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_SPANTREEREGION_TIMER_RATE, &timer_rate, 
	  DEFAULT_TIMER_RATE)) {
      return FAIL;
    }

    call Random.init();
    initialized = TRUE;
    return SUCCESS;
  }

  /***********************************************************************
   * StdControl
   ***********************************************************************/

  command result_t StdControl.init() {
    return initialize();
  }

  command result_t StdControl.start() {
    call CommControl.setPromiscuous(TRUE);
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
   * Internal functions
   ***********************************************************************/

  static void calc_goodness(struct neighbor *neighbor) {
    int fail;
    if (neighbor->addr == EMPTY_ADDR) return;
    fail = neighbor->fail_count + (TIMEOUT_SCALE * neighbor->timeouts);
    if (neighbor->recv_count+fail == 0) {
      neighbor->goodness = 100;
    } else {
      neighbor->goodness = (int)((neighbor->recv_count * 1.0) / ((neighbor->recv_count + fail) * 1.0) * 100.0);
    }
  }

  // Try to pick a new parent for the given tree
  void route_update(struct tree_state *tree) {
    int best = -1, best_goodness = 0, best_hopcount = 255, n;

    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      calc_goodness(&neighbors[n]);
    }

    // First pass: min hopcount
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      if ((tree->neighbors[n].nbr->addr != EMPTY_ADDR) &&
	  (tree->neighbors[n].nbr->goodness > GOODNESS_THRESHOLD) &&
	  (tree->neighbors[n].is_child == FALSE)) {
	if (tree->neighbors[n].hopcount < best_hopcount) {
	  best_hopcount = tree->neighbors[n].hopcount;
	}
      }
    }

    // Second pass: max goodness
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      if ((tree->neighbors[n].nbr->addr != EMPTY_ADDR) &&
	  (tree->neighbors[n].hopcount == best_hopcount) &&
	  (tree->neighbors[n].nbr->goodness > GOODNESS_THRESHOLD) &&
	  (tree->neighbors[n].is_child == FALSE)) {
	if (tree->neighbors[n].nbr->goodness > best_goodness) {
	  best_goodness = tree->neighbors[n].nbr->goodness;
	  best = n;
	}
      }
    }
    if (best != -1) {
      dbg(DBG_USR1, "STRegionM-%d DIRECTED GRAPH: remove edge %d\n", tree->root, tree->parent);
      tree->parent = tree->neighbors[best].nbr->addr;
      tree->hopcount = tree->neighbors[best].hopcount + 1;
      tree->parent_xmit_success = 0;
      tree->parent_xmit_fail = 0;
      tree->parent_link_quality = -1;
      dbg(DBG_USR1, "STRegionM-%d DIRECTED GRAPH: add edge %d label: root%d-hc%d-ru color: %s\n", tree->root, tree->parent, tree->root, tree->hopcount, tree->color_string);
    }
    // Note - might not have found a parent!
  }

  static void calc_plq(struct tree_state *tree) {
    int newplq;
    if (tree->parent_xmit_success + tree->parent_xmit_fail == 0) {
      // If nothing has happened, don't recalculate
      return;
    } else {
      newplq = (int)((tree->parent_xmit_success * 1.0) / ((tree->parent_xmit_success + tree->parent_xmit_fail)*1.0) * 100);
    }
    if (tree->parent_link_quality == -1) {
      // Initially, set plq to newplq
      tree->parent_link_quality = newplq;
    } else {
      // EWMA
      tree->parent_link_quality = (int)((newplq * PARENT_LINK_QUALITY_ALPHA) + (tree->parent_link_quality * (1.0 - PARENT_LINK_QUALITY_ALPHA)));
    }
    tree->parent_xmit_success = 0;
    tree->parent_xmit_fail = 0;
    if (tree->parent_link_quality < PARENT_THRESHOLD) route_update(tree);
  }

  static void enforce_parent(struct tree_state *tree) {
    tree->parent_xmit_success++;
  }

  static void discourage_parent(struct tree_state *tree) {
    tree->parent_xmit_fail++;
  }

  static void neighbor_timeout() {
    int n;
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) {
	if (++neighbors[n].timeouts >= TIMEOUT_THRESHOLD) {
	  // Clear out neighbor
	  neighbors[n].addr = EMPTY_ADDR;
	}
	if (++neighbors[n].age >= age_threshold) {
	  // Clear out goodness
	  neighbors[n].recv_count = neighbors[n].fail_count = 0;
	}
      }
    }
  }

  static struct tree_state *get_tree(uint16_t rootaddr, bool evict) {
    int n;
    int victim;
    for (n = 0; n < MAX_TREES; n++) {
      if (treestate[n].root == rootaddr) {
	return &treestate[n];
      }
    }
    if (!evict) return NULL;
    for (n = 0; n < MAX_TREES; n++) {
      if (treestate[n].root == EMPTY_ADDR) {
	init_tree(&treestate[n]);
	treestate[n].root = rootaddr;
	return &treestate[n];
      }
    }
    // None empty - try to evict. 
    victim = (call Random.rand()) % MAX_TREES;
    init_tree(&treestate[n]);
    treestate[n].root = rootaddr;
    return &treestate[n];
  }

  static struct neighbor *get_neighbor(uint16_t addr, bool evict) {
    int n;
    int victim;
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	return &neighbors[n];
      }
    }
    if (!evict) return NULL;
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY_ADDR) {
	init_neighbor(&neighbors[n]);
	neighbors[n].addr = addr;
	return &neighbors[n];
      }
    }
    // None empty - try to evict. Don't care if we evict our parent!
    victim = (call Random.rand()) % SPANTREEREGION_MAX_NEIGHBORS;
    init_neighbor(&neighbors[victim]);
    neighbors[victim].addr = addr;
    return &neighbors[victim];
  }

  static struct treeneighbor *get_treeneighbor(struct tree_state *tree,
      uint16_t addr, bool evict) {
    int n;
    struct neighbor *nbr = get_neighbor(addr, evict);

    if (nbr == NULL) return NULL;
    for (n = 0; n < SPANTREEREGION_MAX_NEIGHBORS; n++) {
      if (tree->neighbors[n].nbr == nbr) {
	return &(tree->neighbors[n]);
      }
    }
    return NULL;
  }

  static void link_update(SpanTreeRegion_BeaconMsg *msg) {
    struct neighbor *neighbor = get_neighbor(msg->sourceaddr, TRUE);

    neighbor->timeouts = 0;
    neighbor->recv_count++;
    if (neighbor->recv_count > 1) {
      // Not the first message from this neighbor - avoid large miss penalty
      // if last_seqno is incorrect

      // Drop neighbor if seqno gap is too large
      // (avoid overflow and force periodic refresh)
      if (msg->seqno - neighbor->last_seqno > MAX_SEQNO_GAP) {
	neighbor->addr = EMPTY_ADDR;
	return;
      }
      neighbor->fail_count += (msg->seqno - neighbor->last_seqno);
    }
    neighbor->last_seqno = msg->seqno;
    // Now update status for originaddr (global)
    //neighbor = get_neighbor(msg->originaddr, TRUE);
    //neighbor->root = msg->originaddr;
    //neighbor->hopcount = msg->hopcount;
    //neighbor->is_child = (msg->parentaddr == TOS_LOCAL_ADDRESS)?TRUE:FALSE;
  }

  static void break_cycle(uint16_t rootaddr) {
    struct tree_state *tree; 
    struct treeneighbor *neighbor;

    dbg(DBG_USR1, "SurgeM: Breaking cycle for root %d\n", rootaddr);

    tree = get_tree(rootaddr, FALSE);
    if (tree == NULL) return;
    if (tree->parent == EMPTY_ADDR) return;
    neighbor = get_treeneighbor(tree, tree->parent, FALSE);
    if (neighbor != NULL) {
      neighbor->is_child = TRUE;
    }
    // Drop our parent
    dbg(DBG_USR1, "STRegionM-%d DIRECTED GRAPH: remove edge %d\n", tree->root, tree->parent);
    route_update(tree);
  }

  static void send_beacon() {
    SpanTreeRegion_BeaconMsg *send_msg;

    if (!is_root) return;
      
    send_msg = (SpanTreeRegion_BeaconMsg *)beacon_packet.data;
    if (!sendBeacon_busy) {
      send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
      send_msg->parentaddr = EMPTY_ADDR;
      send_msg->originaddr = TOS_LOCAL_ADDRESS;
      send_msg->seqno = ++cur_seqno;
      send_msg->hopcount = 0;
      sendBeacon_busy = TRUE;
      if (!call SendBeacon.send(TOS_BCAST_ADDR, sizeof(SpanTreeRegion_BeaconMsg), &beacon_packet) == SUCCESS) {
	sendBeacon_busy = FALSE;
      }
    }
  }

  static void forward_beacon(TOS_MsgPtr recv_packet) {
    SpanTreeRegion_BeaconMsg *msg = (SpanTreeRegion_BeaconMsg *)recv_packet->data;
    SpanTreeRegion_BeaconMsg *outmsg = (SpanTreeRegion_BeaconMsg *)beacon_packet.data;
    if (!sendBeacon_busy) {
      struct tree_state *tree = get_tree(msg->originaddr, FALSE);
      if (tree == NULL) {
	dbg(DBG_USR1,"forward_beacon: no tree found for root %d\n", msg->originaddr);
	return;
      }

      dbg(DBG_USR1,"forward_beacon: root %d parent %d msg->source %d seqno %d msg->seqno %d\n", msg->originaddr, tree->parent, msg->sourceaddr, tree->seqno, msg->seqno);
      // Only forward beacons from our parent
      if (tree->parent == EMPTY_ADDR || msg->sourceaddr != tree->parent) return;
      // Don't forward if we already have done it
      if (cur_seqno >= msg->seqno) return;
      cur_seqno = msg->seqno;

      // Just update a few fields in the beacon
      memcpy(&beacon_packet, recv_packet, sizeof(beacon_packet));
      outmsg->sourceaddr = TOS_LOCAL_ADDRESS;
      outmsg->parentaddr = tree->parent;
      outmsg->hopcount = tree->hopcount; // XXX Should be msg->hopcount+1?
      sendBeacon_busy = TRUE;
      if (!call SendBeacon.send(TOS_BCAST_ADDR, sizeof(SpanTreeRegion_BeaconMsg), &beacon_packet) == SUCCESS) {
	sendBeacon_busy = FALSE;
      }
    }
  }

  /***********************************************************************
   * Region
   ***********************************************************************/

  command result_t Region.getRegion() {
    dbg(DBG_USR1,"STRegionM: getRegion: formed %d timer_started %d pending %d\n", region_formed, timer_started, pending);
    if (region_formed) {
      signal Region.getDone(SUCCESS);
      return SUCCESS;
    } else {
      is_root = TRUE;
      pending = TRUE;
      pending_count = 0;
      if (!timer_started) {
       	timer_started = TRUE;
	dbg(DBG_USR1,"STRegionM: Timer rate %d\n", (uint16_t)timer_rate);
	if (!call Timer.start(TIMER_REPEAT, (uint16_t)timer_rate)) {
  	  timer_started = FALSE;
	  pending = FALSE;
   	}
	dbg(DBG_USR1,"STRegionM: getRegion: tried to start timer, returning %d\n", timer_started);
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
      dbg(DBG_USR2, "STRegionM: getNodes: n[%d] addr %d\n", n, neighbors[n].addr);
      exported_neighbors[count] = neighbors[n].addr;
      if (neighbors[n].addr != EMPTY_ADDR) count++;
    }
    dbg(DBG_USR2, "STRegionM: getNodes returning %d\n", count);
    *node_list_ptr = exported_neighbors;
    return count;
  }

  /***********************************************************************
   * Timer
   ***********************************************************************/

  event result_t Timer.fired() {
    timer_ticks++;

    //dbg(DBG_USR2,"STRegionM: ticks %d pending %d pending_count %d pcthresh %d\n", timer_ticks, pending, pending_count, timer_pending_count);

    if (timer_ticks % TIMER_BEACON_COUNT == 0) {
      send_beacon();
    }

    if (timer_ticks % TIMER_AGE_COUNT == 0) {
      neighbor_timeout();
    }

    if (is_root && pending && ++pending_count >= (int)timer_pending_count) {
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

  event TOS_MsgPtr ReceiveBeacon.receive(TOS_MsgPtr recv_packet) {
    SpanTreeRegion_BeaconMsg *recv_msg = (SpanTreeRegion_BeaconMsg *)recv_packet->data;
    struct tree_state *tree;

    if (!initialized) return recv_packet;
    dbg(DBG_USR1, "STRegionM: Message received, source 0x%02x, origin 0x%02x, parent 0x%02x, hopcount %d, seqno %d\n", recv_msg->sourceaddr, recv_msg->originaddr, recv_msg->parentaddr, recv_msg->hopcount, recv_msg->seqno);

    // Drop messages from ourselves
    if (recv_msg->originaddr == TOS_LOCAL_ADDRESS) {
      // Is this a cycle? Our parent is not a "direct" child, but 
      // let's invalidate it and do a route update.
      if (recv_packet->addr == TOS_LOCAL_ADDRESS) {
	// XXX
	//break_cycle();
      }
      dbg(DBG_USR1, "STRegionM: Dropping message from self\n");
      return recv_packet;
    }

    tree = get_tree(recv_msg->originaddr, TRUE);
    if (tree == NULL) {
      dbg(DBG_USR1, "STRegionM: No tree found for root %d\n", recv_msg->originaddr);
      return recv_packet;
    }

    dbg(DBG_USR1, "STRegionM: Rootbeacon, root %d, plq=%d hopcount=%d parent=%d\n", tree->root, tree->parent_link_quality, tree->hopcount, tree->parent);

    // Maybe pick new parent
    if ((tree->parent_link_quality == -1 ||
	  tree->parent_link_quality < ROOT_BEACON_THRESHOLD) &&
	(recv_msg->hopcount+1 < tree->hopcount) &&
	(tree->parent != recv_msg->sourceaddr)) {
      dbg(DBG_USR1, "STRegionM: Setting parent for root %d to %x\n", tree->root, recv_msg->sourceaddr);
      dbg(DBG_USR1, "STRegionM-%d DIRECTED GRAPH: remove edge %d\n", tree->root, tree->parent);
      tree->parent = recv_msg->sourceaddr;
      tree->hopcount = recv_msg->hopcount+1;
      tree->parent_xmit_success = 0;
      tree->parent_xmit_fail = 0;
      tree->parent_link_quality = -1;
      dbg(DBG_USR1, "STRegionM-%d DIRECTED GRAPH: add edge %d label: root%d-hc%d color: %s\n", tree->root, tree->parent, tree->root, tree->hopcount, tree->color_string);
    }

    // Forward the beacon
    forward_beacon(recv_packet);

    // Update link information
    // XXX
    ///link_update(recv_msg);

    // If no parent, pick one
    if (tree->parent == EMPTY_ADDR) route_update(tree);

    return recv_packet;
  }   

  event result_t SendBeacon.sendDone(TOS_MsgPtr msg, bool success) {
    SpanTreeRegion_BeaconMsg *beacon = (SpanTreeRegion_BeaconMsg *)msg->data;
    struct tree_state *tree;

    dbg(DBG_USR2, "STRegionM: SendBeacon.sendDone\n");
    sendBeacon_busy = FALSE;

    tree = get_tree(beacon->originaddr, FALSE);
    if (tree == NULL) return SUCCESS;
    if (tree->parent != EMPTY_ADDR && msg->addr == tree->parent) {
      if (success) enforce_parent(tree);
      else discourage_parent(tree);
    }
    return SUCCESS;
  }

  /* SendToParent *********************************************************/

  event result_t SendParent.sendDone(TOS_MsgPtr msg, bool success) {
    // Should keep track of which tree this was for and 
    // enforce/discourage parent
    dbg(DBG_USR2, "STRegionM: SendParent.sendDone\n");
    sendParent_busy = FALSE;
    signal SendToParent.sendDone(msg, success);
    return SUCCESS;
  }

  default event result_t SendToParent.sendDone(TOS_MsgPtr msg, bool success) {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReceiveAtParent.receive(TOS_MsgPtr msg) {
    return msg;
  }

  /** 
   * Send a message to this node's parent in the spanning tree rooted at 
   * 'address'.
   */
  command result_t SendToParent.send(uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    struct tree_state *tree = get_tree(address, FALSE);
    if (tree == NULL) return FAIL;
    if (tree->parent == EMPTY_ADDR) return FAIL;
    if (sendParent_busy) return FAIL;
    sendParent_busy = TRUE;
    if (!call SendParent.send(tree->parent, length, msg)) {
      sendParent_busy = FALSE;
      return FAIL;
    }
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveParent.receive(TOS_MsgPtr recv_packet) {
    return signal ReceiveAtParent.receive(recv_packet);
  }

  /* SendToRoot ***********************************************************/

  event result_t SendRoot.sendDone(TOS_MsgPtr msg, bool success) {
    SpanTreeRegion_RouteMsg *rmsg = (SpanTreeRegion_RouteMsg*)msg->data;
    struct tree_state *tree;

    dbg(DBG_USR2, "STRegionM: SendRoot.sendDone for root %d\n", rmsg->destaddr);
    tree = get_tree(rmsg->destaddr, FALSE);
    sendRoot_busy = FALSE;
    if (tree != NULL) {
      if (tree->parent != EMPTY_ADDR) {
	if (success) enforce_parent(tree);
	else discourage_parent(tree);
      }
    }
    signal SendToRoot.sendDone(msg, success);
    return SUCCESS;
  }

  default event result_t SendToRoot.sendDone(TOS_MsgPtr msg, bool success) {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReceiveAtRoot.receive(TOS_MsgPtr msg) {
    return msg;
  }

  /** 
   * Route a message to the root of the spanning tree.
   */
  command result_t SendToRoot.send(uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    SpanTreeRegion_RouteMsg *rmsg = (SpanTreeRegion_RouteMsg*)route_packet.data;
    struct tree_state *tree = get_tree(address, FALSE);

    if (tree == NULL) return FAIL;
    if (tree->parent == EMPTY_ADDR) return FAIL;
    if (length > sizeof(rmsg->data)) return FAIL;
    if (sendRoot_busy) return FAIL;

    dbg(DBG_USR2, "STRegionM: SendRoot to %d parent %d hopcount %d\n",
	address, tree->parent, tree->hopcount);

    sendRoot_busy = TRUE;
    memcpy(rmsg->data, msg->data, length);
    rmsg->destaddr = tree->root;
    rmsg->length = length;
    if (!call SendRoot.send(tree->parent, sizeof(SpanTreeRegion_RouteMsg), 
	  &route_packet)) {
      sendRoot_busy = FALSE;
      return FAIL;
    }
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveRoot.receive(TOS_MsgPtr recv_packet) {
    SpanTreeRegion_RouteMsg *rmsg = (SpanTreeRegion_RouteMsg*)recv_packet->data;
    dbg(DBG_USR2, "STRegionM: ReceiveRoot.receive: destaddr %d length %d\n", rmsg->destaddr, rmsg->length);
    if (rmsg->destaddr == TOS_LOCAL_ADDRESS) {
      // It's for us
      memcpy(root_packet.data, rmsg->data, rmsg->length);
      root_packet.length = rmsg->length;
      signal ReceiveAtRoot.receive(&root_packet);
      return recv_packet;

    } else {
      // Route to parent
      struct tree_state *tree = get_tree(rmsg->destaddr, FALSE);
      if (tree == NULL) return recv_packet;
      if (tree->parent == EMPTY_ADDR) return recv_packet;
      if (sendRoot_busy) return recv_packet;
      dbg(DBG_USR2, "STRegionM: ReceiveRoot.receive: sending to parent %d\n", tree->parent);
      sendRoot_busy = TRUE;
      memcpy(route_packet.data, recv_packet->data, recv_packet->length);
      if (!call SendRoot.send(tree->parent, recv_packet->length, &route_packet)) {
	sendRoot_busy = FALSE;
	return recv_packet;
      }
    }
    return recv_packet;
  }

}
