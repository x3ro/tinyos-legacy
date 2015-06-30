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
 * Author: Matt Welsh
 * Last updated: 1 Oct 2002
 * 
 */

includes AM;
includes Surge;

/**
 * 
 **/
module SurgeM {
  provides {
    interface StdControl;
    event void sendFail(uint16_t destaddr);
    event void sendSucceed(uint16_t destaddr);
  }
  uses {
    interface ADC;
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

  bool sleeping;
  bool focused;
  bool not_forwarding;
  bool send_busy;
  bool rebroadcast_adc_packet;
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
    sleeping = FALSE;
    not_forwarding = FALSE;
    rebroadcast_adc_packet = FALSE;
    focused = FALSE;
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

  static void link_update(SurgeMsg *msg) {
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
    dbg(DBG_USR1, "SurgeM: Breaking cycle\n");
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
    dbg(DBG_USR1, "SurgeM: Timer fired\n");
    timer_ticks++;
    if (timer_ticks % TIMER_GETADC_COUNT == 0) {
      // Only send our own data if we have a parent
      if (my_parent != EMPTY) call ADC.getData();
    }
    if (timer_ticks % TIMER_NEIGHBOR_TIMEOUT_COUNT == 0) {
      neighbor_timeout();
    }
    if (timer_ticks % TIMER_PLQ_UPDATE_COUNT == 0) {
      calc_plq();
    }
    // If we're the focused node, chirp
    if (focused && timer_ticks % TIMER_CHIRP_COUNT == 0) {
      call Sounder.start();
    }
    // If we're the focused node, chirp
    if (focused && timer_ticks % TIMER_CHIRP_COUNT == 1) {
      call Sounder.stop();
    }
    return SUCCESS;
  }

  event result_t ADC.dataReady(uint16_t data) {
    SurgeMsg *send_msg = (SurgeMsg *)adc_packet.data;
    sensor_reading = data;
    dbg(DBG_USR1, "SurgeM: Got ADC reading: 0x%x\n", sensor_reading);

    if (!send_busy) {
      send_msg->type = SURGE_TYPE_SENSORREADING;
      send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
      send_msg->originaddr = TOS_LOCAL_ADDRESS;
      send_msg->parentaddr = my_parent;
      send_msg->hopcount = my_hopcount;
      send_msg->seqno = cur_seqno++;
      send_msg->args.reading_args.reading = sensor_reading;
      send_msg->args.reading_args.parent_link_quality = parent_link_quality;
      send_msg->debug_code = debug_code;

      // Queued send returns FAIL if concurrent enqueues are happening -
      // just drop message in that case. 
      dbg(DBG_USR1, "SurgeM: Sending sensor packet (seqno 0x%x)\n", cur_seqno);
      if (my_parent == TOS_UART_ADDR) rebroadcast_adc_packet = TRUE;
      if (call SendMsg.send(my_parent, sizeof(SurgeMsg), &adc_packet) == SUCCESS) {
	send_busy = TRUE;
      }
    }
    return SUCCESS;
  }

  static void forward(uint16_t destaddr, SurgeMsg *recv_msg) {
    SurgeMsg *send_msg = (SurgeMsg *)forward_packet.data;
    if (send_busy) return; // Drop if busy
    memcpy(send_msg, recv_msg, sizeof(SurgeMsg));
    send_msg->sourceaddr = TOS_LOCAL_ADDRESS;
    send_msg->seqno = cur_seqno++;

    // Queued send returns FAIL if concurrent enqueues are happening -
    // just drop message in that case. 
    dbg(DBG_USR1, "SurgeM: Forwarding packet (seqno 0x%x)\n", cur_seqno);
    if (call SendMsg.send(destaddr, sizeof(SurgeMsg), &forward_packet) == SUCCESS) {
      send_busy = TRUE;
    }
  }

  static void broadcast_cmd(SurgeMsg *recv_msg) {
    if (recv_msg->type != last_cmd_type) {
      cmd_broadcast_count = 0;
      last_cmd_type = recv_msg->type;
    }
    if (++cmd_broadcast_count < CMD_BROADCAST_THRESHOLD) {
      forward(TOS_BCAST_ADDR, recv_msg);
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    SurgeMsg *recv_msg = (SurgeMsg *)recv_packet->data;
    call Leds.yellowToggle();

    dbg(DBG_USR1, "SurgeM: Message received, source 0x%02x, origin 0x%02x, parent 0x%02x, type 0x%02x\n", recv_msg->sourceaddr, recv_msg->originaddr, recv_msg->parentaddr, recv_msg->type);

    // Drop messages from ourselves
    if (recv_msg->originaddr == TOS_LOCAL_ADDRESS) {
      // Is this a cycle? Our parent is not a "direct" child, but 
      // let's invalidate it and do a route update.
      if (recv_packet->addr == TOS_LOCAL_ADDRESS) {
	break_cycle();
      }
      dbg(DBG_USR1, "SurgeM: Dropping message from self\n");
      return recv_packet;
    }

    // If this is a root beacon...
    if (recv_msg->type == SURGE_TYPE_ROOTBEACON) {
      dbg(DBG_USR1, "SurgeM: Rootbeacon, plq=%d hc=%d my_parent=%d\n", parent_link_quality, my_hopcount, my_parent);
      if ((parent_link_quality == -1 || 
	    parent_link_quality < ROOT_BEACON_THRESHOLD) &&
	  (recv_msg->hopcount < my_hopcount) &&
	  (my_parent != recv_msg->sourceaddr)) {
        dbg(DBG_USR1, "SurgeM: Setting root to %x\n", recv_msg->sourceaddr);
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

    // Interpret command messages
    if (recv_msg->type == SURGE_TYPE_SETRATE) {
      // Set timer rate
      timer_rate = recv_msg->args.newrate;
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, timer_rate);
      broadcast_cmd(recv_msg);
      return recv_packet;

    } else if (recv_msg->type == SURGE_TYPE_SLEEP) {
      // Go to sleep - ignore everything until a SURGE_TYPE_WAKEUP
      sleeping = TRUE;
      call Timer.stop();
      call Leds.greenOff();
      call Leds.yellowOff();
      call Leds.redOff();
      broadcast_cmd(recv_msg);
      return recv_packet;
      
    } else if (recv_msg->type == SURGE_TYPE_WAKEUP) {
      // Wake up from sleep state
      if (sleeping) {
	initialize();
        call Timer.start(TIMER_REPEAT, timer_rate);
	sleeping = FALSE;
      }
      broadcast_cmd(recv_msg);
      return recv_packet;

    } else if (recv_msg->type == SURGE_TYPE_FOCUS) {
      // Cause just one node to chirp and increase its sample rate;
      // all other nodes stop sending samples (for demo)
      if (recv_msg->args.focusaddr == TOS_LOCAL_ADDRESS) {
	// OK, we're focusing on me
	focused = TRUE;
	call Sounder.init();
	call Timer.stop();
	call Timer.start(TIMER_REPEAT, FOCUS_TIMER_RATE);
      } else {
	// Focusing on someone else
	call Timer.stop();
	call Timer.start(TIMER_REPEAT, FOCUS_NOTME_TIMER_RATE);
      }
      broadcast_cmd(recv_msg);
      return recv_packet;

    } else if (recv_msg->type == SURGE_TYPE_UNFOCUS) {
      // Return to normal after focus command
      focused = FALSE;
      call Sounder.stop();
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, timer_rate);
      broadcast_cmd(recv_msg);
      return recv_packet;
    }

    // Drop all other messages if sleeping
    if (sleeping) {
      return recv_packet;
    }

    // Update link information
    link_update(recv_msg);

    // If no parent, pick one
    if (my_parent == EMPTY) post route_update();

    // Forward if it was destined for us
    if (recv_packet->addr == TOS_LOCAL_ADDRESS && my_parent != EMPTY && 
	!not_forwarding) {
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
    if (rebroadcast_adc_packet) {
      rebroadcast_adc_packet = FALSE;
      // Don't care about success/failure
      dbg(DBG_USR1, "SurgeM: Rebroadcasting sensor packet to BCAST\n");
      call SendMsg.send(TOS_BCAST_ADDR, sizeof(SurgeMsg), &adc_packet);
    }
    return SUCCESS;
  }

}


