/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * Author: Matt Welsh, David Culler
 * Last updated: Jan 13, 2003
 * 
 */

/*
 * Algorithmic strategy
 *
 * A neighbor table is maintained to track link history and relationship to
 *  nodes within radio range.  Information in the table is based on what
 *  we receive from the node.
 *
 * Similar information is maintained about our routing parent based on
 * acks/nacks on messages sent to the parent.
 *
 * Link estimation technique is an EWMA of windowed average success rates.
 * For neighbors, on packet arrival we can calculate the number of missing
 * packets based on the seq. no. difference.  We also assume that we should
 * receive a packet from each neighbor in each interval, which is a small 
 * multiple of the basic timer interval.  If not, we accumulate a timeout
 * count.  A multiple of the timeout count is taken as an estimate of the
 * number of losses since last received packet.  
 *
 * For parent estimation, the ack associated with each packet is used to 
 * feed the average.
 */

includes AM;
includes Surge;

/**
 *   ***DEC should be able to separate multihop and surge
 **/

module multihopM {
  provides {
    interface StdControl;
    interface IntOutput;
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
  }
}

implementation {

  enum {
    NUM_NEIGHBORS = 16,                // Total max # neighbors
    TIMER_NEIGHBOR_TIMEOUT_COUNT = 4,  // Timer ticks for neighbor timeout
    TIMEOUT_SCALE = 4,                 // Number of 'failed' recv per timeout
    TIMER_PLQ_UPDATE_COUNT = 4,        // Timer ticks per PLQ update
    SMOOTH_THRESHOLD = 4,              // events per EWMA calculation
    PARENT_THRESHOLD = 64,             // Min Parent link quality threshold
    ROOT_BEACON_THRESHOLD = 30,        // PLQ threshold for prefering root
    TIMEOUT_THRESHOLD = 10,            // Max timeouts before removal **remove
    GOODNESS_THRESHOLD = 20,           // Neighbor must be this good
    UNINIT_GOODNESS = 255,             // Uninitialized goodness symbol
    MAX_SEQNO_GAP = 20,		       // Max seqno gap
    MAX_PARENT_COUNT = 16	       // Msgs per force re-estimation
  };

  /* Fields of neighbor table */
  struct neighbor {
    uint16_t addr;                     // state provided by nbr
    uint8_t hopcount;
    uint8_t timeouts;			// since last recv
    uint8_t recv_count;                 // since last goodness update
    uint8_t fail_count;                 // since last goodness, adjusted by TOs
    uint8_t last_seqno;
    bool    is_child;
    uint8_t goodness;
  } neighbors[NUM_NEIGHBORS];

  /* Routing status of local node */
  uint16_t my_parent;
  uint8_t  my_hopcount;
  uint8_t  parent_xmit_success;
  uint8_t  parent_xmit_fail;
  uint8_t  parent_link_quality;
  uint8_t  parent_count;
  uint8_t  cur_seqno;

  /* Internal storage and scheduling state */
  bool send_busy;
  struct TOS_Msg forward_packet, data_packet;
  uint8_t update_count;
  bool rebroadcast_data_packet;
  int timer_rate;
  int timer_ticks;
  bool resynch;
  uint32_t debug_code;


  /***********************************************************************
   * Initialization 
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY;
    neighbor->hopcount = 0;
    neighbor->timeouts = 0;
    neighbor->recv_count = 0;
    neighbor->fail_count = 0;
    neighbor->last_seqno = -1;
    neighbor->is_child = FALSE;
    neighbor->goodness = UNINIT_GOODNESS;
  }

  static void initialize() {
    int n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    cur_seqno = 0;
    my_parent = EMPTY;
    my_hopcount = INITIAL_HOPCOUNT;
    parent_xmit_success = 0;
    parent_xmit_fail = 0;
    parent_link_quality = UNINIT_GOODNESS;
    timer_rate = INITIAL_TIMER_RATE;
    timer_ticks = 0;
    resynch = FALSE;
    debug_code = 0;
    update_count = 0;
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

  /*  Link Estimation */

  /*
   * Update goodness
   *
   * Goodness is an EWMA of windowed average link rates.
   *  - represented as an unsigned byte with 128 == 100%
   *  - here the EWMA constant is 7/8
   * maintain a bin of success and fails since last goodness update
   * Once bins are sufficiently full, perform EWMA accumulate into goodness
   * Return whether update was performed
   */
  static bool update_goodness(uint8_t *goodness, uint8_t success, uint8_t fails) {
    unsigned int new_ave;
    unsigned int total = success + fails;
    if (total < SMOOTH_THRESHOLD) {
      return FALSE;
    } else {
      new_ave = (128 * success) / total;
      if (*goodness == UNINIT_GOODNESS) {
	*goodness = new_ave;
	//Surgedbg(DBG_USR2, "MHOP: setting new goodness to %d\n",*goodness);
      } else {
	*goodness = (uint8_t)((((unsigned int)(*goodness) * 3)  + new_ave) / 4);
	//Surgedbg(DBG_USR2, "MHOP: adjusting goodness to %d\n",*goodness);
      }
      return TRUE;
    }
  }
             
  /***********************************************************************
   * Neighbor management
   ***********************************************************************/

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

   static void link_update(SurgeMsg *msg) {
    // First update status for sourceaddr (link-level)
    struct neighbor *neighbor = get_neighbor(msg->sourceaddr, TRUE);
    if ((neighbor == NULL) || (neighbor->last_seqno == msg->seqno)) return;

    neighbor->recv_count++;
    if (msg->seqno > neighbor->last_seqno) {
       neighbor->fail_count += (msg->seqno - neighbor->last_seqno - 1);
    } else {
       neighbor->fail_count += (255 + msg->seqno - neighbor->last_seqno);
    }
    neighbor->last_seqno = msg->seqno;
    neighbor->hopcount = msg->hopcount;
    neighbor->is_child = (msg->parentaddr == TOS_LOCAL_ADDRESS);
  }

  /* update neighbor_goodness
  *
  *  Internal estimation of neighbor
  */
  static void update_neighbor_goodness(struct neighbor *neighbor) {
    int fail;
    if (neighbor->addr != EMPTY) {
      fail = neighbor->fail_count + (TIMEOUT_SCALE * neighbor->timeouts);
      if (update_goodness (&(neighbor->goodness), neighbor->recv_count, fail)) {
	  Surgedbg(DBG_USR2,"Updating nbr %d goodness to %d\n",
		   neighbor->addr,neighbor->goodness);
   	  neighbor->recv_count = 0;
	  neighbor->fail_count = 0;  
	  neighbor->timeouts   = 0;
      }
    }
  }

  void update_neighbors() {
    int n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if ((neighbors[n].recv_count == 0) && 
          (neighbors[n].hopcount != 0)) ++neighbors[n].timeouts;
      update_neighbor_goodness(&neighbors[n]);
    }
  }

#if 0
 static void link_update(SurgeMsg *msg) {
    // First update status for sourceaddr (link-level)
    struct neighbor *neighbor = get_neighbor(msg->sourceaddr, TRUE);
    if (neighbor == NULL) return;
    neighbor->recv_count++;
    if (neighbor->goodness != UNINIT_GOODNESS) {
      if (msg->seqno - neighbor->last_seqno > MAX_SEQNO_GAP) {
	// We've got a big gap or a seqno rollover, so purge entry
        // Provides a wierd sort of refresh
	init_neighbor(neighbor);
	//neighbor->addr = EMPTY;
	return;
      }
      neighbor->fail_count += (msg->seqno - neighbor->last_seqno);
      neighbor->timeouts = 0;
    }

    neighbor->last_seqno = msg->seqno;

    // Now update status for originaddr (global)
    // *** DEC removed.  These ain't neighbors
    //neighbor = get_neighbor(msg->originaddr, TRUE);
    //neighbor->hopcount = msg->hopcount;
    //neighbor->is_child = (msg->parentaddr == TOS_LOCAL_ADDRESS)?TRUE:FALSE;
  }

  /* calc_goodness
   *
   *  Internal estimation of neighbor
   */
  static void calc_goodness(struct neighbor *neighbor) {
    int fail;
    if (neighbor->addr == EMPTY) return;
    fail = neighbor->fail_count + (TIMEOUT_SCALE * neighbor->timeouts);
    if (update_goodness (&(neighbor->goodness), neighbor->recv_count, fail)) {
      Surgedbg(DBG_USR2,"Updating nbr %d goodness to %d. S=%d F=%d\n",
	       neighbor->addr,neighbor->goodness,neighbor->recv_count,fail);
      neighbor->recv_count = 0;
      neighbor->fail_count = 0;  
    }
  }

  // DEC: This will no longer find anybody.  Should go away.  Get neighbor can
  // discard

  static void neighbor_timeout() {
    int n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY) {
	if (++neighbors[n].timeouts >= TIMEOUT_THRESHOLD) {
	  neighbors[n].addr = EMPTY; 	  // Clear out neighbor
	}
      }
    }
  }



  void update_neighbors() {
    int n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      calc_goodness(&neighbors[n]);
    }
  }
#endif
  /**********************************************************************
   * Route Management
   **********************************************************************/

  task void route_update() {
    uint8_t best = 255, best_goodness = 0, best_hopcount = 255, n;
    //    uint32_t delay;

    Surgedbg(DBG_USR2,"Route Update\n");
    // First pass: min hopcount
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if ((neighbors[n].addr != EMPTY) &&
	  (neighbors[n].goodness != UNINIT_GOODNESS) &&          
	  (neighbors[n].goodness > GOODNESS_THRESHOLD) &&
	  (neighbors[n].is_child == FALSE)) {
	if (neighbors[n].hopcount < best_hopcount) {
	  best_hopcount = neighbors[n].hopcount;
	}
      }
    }

    // Second pass: max goodness at min good hopcount
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if ((neighbors[n].addr != EMPTY) &&
	  (neighbors[n].hopcount == best_hopcount) &&
	  (neighbors[n].goodness != UNINIT_GOODNESS) &&          
	  (neighbors[n].goodness > GOODNESS_THRESHOLD) &&
	  (neighbors[n].is_child == FALSE)) {
	if (neighbors[n].goodness > best_goodness) {
	  best_goodness = neighbors[n].goodness;
	  best = n;
	}
      }
    }
    if ((best != 255) &&
	((my_parent == EMPTY) || 
	 ((my_hopcount > (best_hopcount + 1)) &&
	  (parent_link_quality < best_goodness)))) {    // Found new parent
      my_parent = neighbors[best].addr;
      my_hopcount = neighbors[best].hopcount + 1;
      parent_xmit_success = 0;
      parent_xmit_fail = 0;
      parent_link_quality = best_goodness;
      parent_count = 0;
      update_count++;
      debug_code = ((unsigned long)42) << 24;
      debug_code |= ((unsigned long)best) << 16;
      debug_code |= ((unsigned long)best_goodness) << 8;
      debug_code |= (update_count & 0xff);
    } else { // no good candidate
      Surgedbg(DBG_USR2, "MHop: No new parent. BstGdns=%d\n",best_goodness);
      my_parent = EMPTY;
      my_hopcount = INITIAL_HOPCOUNT;
      parent_xmit_success = 0;
      parent_xmit_fail = 0;
      parent_link_quality = UNINIT_GOODNESS;
      //      call Timer.stop();
      //      resynch = TRUE;
      //      delay = (call Random.rand()) % timer_rate;
      //      call Timer.start(TIMER_ONE_SHOT, delay);
    }
  }

  /*
   * Update Routing State
   *
   */
  static void calc_plq() {
    if (update_goodness(&(parent_link_quality), parent_xmit_success, parent_xmit_fail)) {
      Surgedbg(DBG_USR2,"Updating parent goodness to %d\n", parent_link_quality);
      parent_xmit_success = 0;
      parent_xmit_fail = 0;
    }

  }

  static void enforce_parent() {
    parent_xmit_success++;
  }

  static void discourage_parent() {
    parent_xmit_fail++;
  }


  static void break_cycle() {
    struct neighbor *neighbor = get_neighbor(my_parent, FALSE);
    Surgedbg(DBG_USR1, "MHop: Breaking cycle\n");
    if (neighbor != NULL) {
      neighbor->is_child = TRUE;
    }
    // Drop our parent
    my_parent = EMPTY;
    my_hopcount = INITIAL_HOPCOUNT;
    parent_xmit_success = 0;
    parent_xmit_fail = 0;
    parent_link_quality = UNINIT_GOODNESS;
    post route_update();
  }

  task void update_routing() {
    Surgedbg(DBG_USR2,"Updating routing\n");
    update_neighbors();
    calc_plq();
    if (((parent_link_quality == UNINIT_GOODNESS)) ||
	(parent_link_quality < PARENT_THRESHOLD) || 
	(parent_count > MAX_PARENT_COUNT))
      post route_update();
  }


  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  task void restart () {
    call Timer.start(TIMER_REPEAT, timer_rate);
  }

  event result_t Timer.fired() {
    Surgedbg(DBG_USR1, "MHop: -\n");
    if (resynch) {
      post restart();
      resynch = FALSE;
      return SUCCESS;
    }
    timer_ticks++;

    //    if (timer_ticks % TIMER_NEIGHBOR_TIMEOUT_COUNT == 0) {
    //      neighbor_timeout();
    //    }

    if (timer_ticks % TIMER_PLQ_UPDATE_COUNT == 0) {
      Surgedbg(DBG_USR2, "MHop: posting update routing\n");
      post update_routing();
    }
    return SUCCESS;
  }

  command result_t IntOutput.output(uint16_t sensor_reading) {
    int n;
    SurgeMsg *send_msg = (SurgeMsg *)data_packet.data;
    Surgedbg(DBG_USR1, "MHop: sending reading 0x%x. my_parent=0x%x\n", 
	     sensor_reading, my_parent);

    if ((!send_busy) && (my_parent != EMPTY)) {
      send_msg->type = SURGE_TYPE_SENSORREADING;
      send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
      send_msg->originaddr = TOS_LOCAL_ADDRESS;
      send_msg->parentaddr = my_parent;
      send_msg->hopcount = my_hopcount;
      send_msg->seqno = cur_seqno++;
      send_msg->args.reading_args.reading = sensor_reading;
      send_msg->args.reading_args.parent_link_quality = parent_link_quality;
      for (n = 0; n < 4; n++) {
	send_msg->args.reading_args.nbrs[n] = (uint8_t) neighbors[n].addr;
	send_msg->args.reading_args.q[n] = neighbors[n].goodness;
      }
      send_msg->debug_code = debug_code;

      // Try to send packet, drop if enqueue refused
      Surgedbg(DBG_USR1, "MHop: Sending sensor packet (seqno 0x%x)\n", cur_seqno);
      if (my_parent == TOS_UART_ADDR) rebroadcast_data_packet = TRUE;
      send_busy = TRUE;
      if (call SendMsg.send(my_parent, sizeof(SurgeMsg), &data_packet) != SUCCESS) {
	send_busy = FALSE;
      }
      return SUCCESS;
    } else {
      Surgedbg(DBG_USR1, "MHop: Dropped reading 0x%x", sensor_reading);
      return FAIL;
    }
  }

  static void forward(uint16_t destaddr, SurgeMsg *recv_msg) {
    SurgeMsg *send_msg = (SurgeMsg *)forward_packet.data;
    if (send_busy) return; // Drop if busy
    memcpy(send_msg, recv_msg, sizeof(SurgeMsg));
    send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
    send_msg->seqno = cur_seqno++;
    // Queued send returns FAIL if concurrent enqueues are happening -
    // just drop message in that case. 
    Surgedbg(DBG_USR1, "MHop: Forwarding packet (seqno 0x%x)\n", cur_seqno);
    send_busy = TRUE;
    if (call SendMsg.send(destaddr, sizeof(SurgeMsg), &forward_packet) != SUCCESS) {
      send_busy = FALSE;
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    struct neighbor *neighbor;
    SurgeMsg *recv_msg = (SurgeMsg *)recv_packet->data;
    call Leds.yellowToggle();

    Surgedbg(DBG_USR2, "MHop: Msg Rcvd, src 0x%02x, org 0x%02x, parent 0x%02x, type 0x%02x\n", 
	     recv_msg->sourceaddr, recv_msg->originaddr, recv_msg->parentaddr, recv_msg->type);

    // Update link information
    link_update(recv_msg);

    // Drop messages from ourselves
    if (recv_msg->originaddr == TOS_LOCAL_ADDRESS) {
      Surgedbg(DBG_USR2, "MHop: Dropping message from self\n");
      // Is this a cycle? Our parent is not a "direct" child, but 
      // let's invalidate it and do a route update.
      if (recv_packet->addr == TOS_LOCAL_ADDRESS) {
	break_cycle();
      }
      return recv_packet;
    }

    // If this is a root beacon, may use it to override parent selection
    if (recv_msg->type == SURGE_TYPE_ROOTBEACON) {
#if 0
      if (recv_msg->sourceaddr == TOS_UART_ADDR) {
	my_parent = recv_msg->sourceaddr;
      }
#else
      Surgedbg(DBG_USR2, "MHop: Rootbeacon src %d, plq=%d hc=%d my_parent=%d\n", 
	       recv_msg->sourceaddr, parent_link_quality, my_hopcount, my_parent);
      neighbor = get_neighbor(recv_msg->sourceaddr, TRUE);
      Surgedbg(DBG_USR2, "MHop: RB goodness = %d\n",neighbor->goodness);
      if (neighbor &&
          ((neighbor->goodness >  ROOT_BEACON_THRESHOLD)  ||
           (neighbor->goodness == UNINIT_GOODNESS))) {
        Surgedbg(DBG_USR2, "MHop: Setting parent to %x\n", recv_msg->sourceaddr);
	my_hopcount = recv_msg->hopcount+1; // had better be 1
	if (my_parent != recv_msg->sourceaddr) {
          parent_xmit_success = 0;
    	  parent_xmit_fail = 0;
	  parent_link_quality = UNINIT_GOODNESS;
          parent_count = 0;
        }
	my_parent = recv_msg->sourceaddr;
	debug_code = 0x69; // Assigned parent from root beacon
      }
#endif
    }
    // If no parent, pick one
    if (my_parent == EMPTY) post route_update();

    // Forward if it was destined for us
    if (recv_packet->addr == TOS_LOCAL_ADDRESS && 
	my_parent != EMPTY &&
	recv_msg->type == SURGE_TYPE_SENSORREADING) {
      parent_count++;
      forward(my_parent, recv_msg);
    }
    return recv_packet;
  }

  event void sendFail(uint16_t destaddr) {
    if (destaddr == my_parent) {
      Surgedbg(DBG_USR2,"MHop: sendFail.\n");
      call Leds.redOn();
      discourage_parent();
    }
  }

  event void sendSucceed(uint16_t destaddr) {
    if (destaddr == my_parent) {
      Surgedbg(DBG_USR2,"MHop: sendSucceed.\n");
      call Leds.redOff();
      enforce_parent();
    }
  }

  task void rebroadcastUART () {
    Surgedbg(DBG_USR2, "MHop: Rebroadcasting sensor packet\n");
    call SendMsg.send(TOS_BCAST_ADDR, sizeof(SurgeMsg), &data_packet);
  }

  /* SendDone Event
   *
   * This can be one of three messages:
   *   - forwarding message
   *   - originating message not for UART, so already broadcast
   *   - originating message that requires rebroadcast on radio
   *   - rebroadcast of an originating message
   */
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    Surgedbg(DBG_USR2, "MHop: senddone 0x%x 0x%x\n", msg, success);    
    if (msg == &forward_packet) {
      send_busy = FALSE;
    } else if (rebroadcast_data_packet) { 
      rebroadcast_data_packet = FALSE;
      post rebroadcastUART();
    } else {
      send_busy = FALSE;
      signal IntOutput.outputComplete(success);
    }
    return SUCCESS;
  }

}


