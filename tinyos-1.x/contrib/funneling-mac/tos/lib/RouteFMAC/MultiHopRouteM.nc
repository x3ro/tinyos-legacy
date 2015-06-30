// $Id: MultiHopRouteM.nc,v 1.1.1.1 2007/07/06 03:44:07 ahngang Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
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
includes MultiHop;

#ifndef MHOP_QUEUE_SIZE
#define MHOP_QUEUE_SIZE	16
#endif

module MultiHopRouteM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Send[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface RouteControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface ReceiveMsg[uint8_t id];
    interface SendMsg[uint8_t id];
    interface StdControl as SubControl;
    interface CommControl;
    interface StdControl as CommStdControl;
    interface Random;
  }
}

implementation {

  enum {
    NUM_NEIGHBORS = 16,                // Total max # neighbors
    TIMER_RATE = 2000,
    TIMER_NEIGHBOR_TIMEOUT_COUNT = 4,  // Timer ticks for neighbor timeout
    TIMEOUT_SCALE = 4,                 // Number of 'failed' recv per timeout
    TIMER_PLQ_UPDATE_COUNT = 4,        // Timer ticks per PLQ update
    SMOOTH_THRESHOLD = 4,              // events per EWMA calculation
    PARENT_THRESHOLD = 64,             // Min Parent link quality threshold
    ROOT_BEACON_THRESHOLD = 30,        // PLQ threshold for prefering root
    TIMEOUT_THRESHOLD = 10,            // Max timeouts before removal **remove
    GOODNESS_THRESHOLD = 20,           // Neighbor must be this good
    UNINIT_GOODNESS = 255,             // Uninitialized goodness symbol
    INIT_HOPCOUNT = 64,
    MAX_SEQNO_GAP = 20,		       // Max seqno gap
    MAX_PARENT_COUNT = 16,	       // Msgs per force re-estimation
    FWD_QUEUE_SIZE = MHOP_QUEUE_SIZE, // Forwarding Queue
    EMPTY = 0xff
  };


  TOS_MHopNeighbor neighbors[NUM_NEIGHBORS];
  
  /* Routing status of local node */

  TOS_MHopNeighbor *pParent;
  uint8_t  my_hopcount;
  uint8_t  parent_count;
  int16_t  cur_seqno;

  /* Internal storage and scheduling state */
  struct TOS_Msg FwdBuffers[FWD_QUEUE_SIZE];
  struct TOS_Msg *FwdBufList[FWD_QUEUE_SIZE];

  uint8_t iFwdBufHead, iFwdBufTail;
  uint8_t update_count;
  uint32_t timer_rate;
  int timer_ticks;
  
  /***********************************************************************
   * Initialization 
   ***********************************************************************/

  static void init_neighbor(TOS_MHopNeighbor *neighbor) {
    neighbor->addr = EMPTY;
    neighbor->hopcount = INIT_HOPCOUNT;
    neighbor->timeouts = 0;
    neighbor->recv_count = 0;
    neighbor->fail_count = 0;
    neighbor->last_seqno = 0;
    //neighbor->is_child = FALSE;
    neighbor->goodness = UNINIT_GOODNESS;
  }

  static void initialize() {
    int n;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
    }
    for (n=0; n < FWD_QUEUE_SIZE; n++) {
      FwdBufList[n] = &FwdBuffers[n];
    } 
    cur_seqno = 0;
    pParent = NULL;
    parent_count = 0;
    my_hopcount = INIT_HOPCOUNT;
    timer_rate = TIMER_RATE;
    timer_ticks = 0;
    update_count = 0;
    iFwdBufHead = iFwdBufTail = 0;
  }

  command result_t StdControl.init() {
    initialize();
    call Random.init();
	call CommStdControl.init();
    return call SubControl.init();
  }

  command result_t StdControl.start() {
	call CommStdControl.start();
    call SubControl.start();
    call CommControl.setPromiscuous(TRUE);
    return call Timer.start(TIMER_REPEAT, timer_rate);
  }

  command result_t StdControl.stop() {
    call SubControl.stop();
	// XXX message doesn't get received if we stop then start radio
    call CommStdControl.stop();
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
	//dbg(DBG_ROUTE, "MHOP: setting new goodness to %d\n",*goodness);
      } else {
	*goodness = (uint8_t)((((unsigned int)(*goodness) * 3)  + new_ave) / 4);
	//dbg(DBG_ROUTE, "MHOP: adjusting goodness to %d\n",*goodness);
      }
      return TRUE;
    }
  }
             
  /***********************************************************************
   * Neighbor management
   ***********************************************************************/

  static TOS_MHopNeighbor *get_neighbor(uint16_t addr, int16_t Seqno, bool evict) {
    int n;
    int victim;
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	return &neighbors[n];
      }
    }

    if (!evict) {
      return NULL;
    }

    Seqno--; // Decrement seqno by one to avoid tripping duplicate supressors
    // First try to find an empty slot in the neighbor table
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY) {
        init_neighbor(&neighbors[n]);
        neighbors[n].addr = addr;
	neighbors[n].last_seqno = Seqno;
	return &neighbors[n];
      }
    }

    // None empty - try to evict. Don't care if we evict our parent!
    victim = (call Random.rand()) % NUM_NEIGHBORS;
    if (pParent == &neighbors[victim]) {
      victim++; 
      victim %= NUM_NEIGHBORS;
      //pParent = NULL;
    }
    init_neighbor(&neighbors[victim]);
    neighbors[victim].addr = addr;
    neighbors[victim].last_seqno = Seqno;
    return &neighbors[victim];
  }

  static TOS_MHopNeighbor *link_update(TOS_MHopMsg *msg, bool *isDup) {
    // First update status for sourceaddr (link-level)
    TOS_MHopNeighbor *pNeighbor = get_neighbor(msg->sourceaddr, msg->seqno, TRUE);
    // Overflow and underflow make the wrap-around case work correctly here.
    int16_t sDelta = msg->seqno - pNeighbor->last_seqno;

    if (sDelta > 0) {
      pNeighbor->recv_count++;
      pNeighbor->fail_count += (sDelta - 1);
      pNeighbor->last_seqno = msg->seqno;
      pNeighbor->hopcount = msg->hopcount;
      *isDup = FALSE;
    }
    else {
      pNeighbor->last_seqno = msg->seqno; /* MDW */
      *isDup = TRUE;
    }

    return pNeighbor;
  }

  /* update neighbor_goodness
  *
  *  Internal estimation of neighbor
  */
  static void update_neighbor_goodness(TOS_MHopNeighbor *neighbor) {
    int fail;
    if (neighbor->addr != EMPTY) {
      fail = neighbor->fail_count + (TIMEOUT_SCALE * neighbor->timeouts);
      if (update_goodness (&(neighbor->goodness), neighbor->recv_count, fail)) {
	  dbg(DBG_ROUTE,"Updating nbr %d goodness to %d\n",
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

  /**********************************************************************
   * Route Management
   **********************************************************************/

  task void route_update() {
    uint8_t best = 255, best_goodness = 0, best_hopcount = 255, n;
    //    uint32_t delay;

    dbg(DBG_ROUTE,"Route Update\n");
    // First pass: min hopcount
    for (n = 0; n < NUM_NEIGHBORS; n++) {
      if ((neighbors[n].addr != EMPTY) &&
	  (neighbors[n].goodness != UNINIT_GOODNESS) &&          
	  (neighbors[n].goodness > GOODNESS_THRESHOLD)) {
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
	  (neighbors[n].goodness > GOODNESS_THRESHOLD)) {
	if (neighbors[n].goodness > best_goodness) {
	  best_goodness = neighbors[n].goodness;
	  best = n;
	}
      }
    }
    if ((best != 255) &&
	((pParent == NULL) || 
	 ((my_hopcount > (best_hopcount + 1)) &&
	  (pParent->goodness < best_goodness)))) {    // Found new parent
      pParent = &neighbors[best];
      my_hopcount = neighbors[best].hopcount + 1;
      parent_count = 0;
      update_count++;
    } else { // no good candidate
      dbg(DBG_ROUTE, "MHop: No new parent. BstGdns=%d\n",best_goodness);
      //pParent = NULL;
      //my_hopcount = INIT_HOPCOUNT;
    }
  }

  /*
   * Update Routing State
   *
   */

  static void break_cycle() {
    dbg(DBG_USR1, "MHop: Breaking cycle\n");

    // Drop our parent
    pParent = NULL;
    my_hopcount = INIT_HOPCOUNT;
    post route_update();
  }

  task void update_routing() {
    dbg(DBG_ROUTE,"Updating routing\n");
    update_neighbors();

    if ((pParent == NULL) ||
	(pParent->goodness < PARENT_THRESHOLD) || 
	(parent_count > MAX_PARENT_COUNT))
      post route_update();
  }


  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  event result_t Timer.fired() {
    // dbg(DBG_USR1, "MHop: -\n");
    timer_ticks++;

    if (timer_ticks % TIMER_PLQ_UPDATE_COUNT == 0) {
      dbg(DBG_ROUTE, "MHop: posting update routing\n");
      post update_routing();
    }
    return SUCCESS;
  }

  command result_t Send.send[uint8_t id](TOS_MsgPtr pMsg, uint16_t PayloadLen) {

    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;
    uint16_t usMHLength = offsetof(TOS_MHopMsg,data) + PayloadLen;

    if ((pParent == NULL) || (usMHLength > TOSH_DATA_LENGTH)) {
      return FAIL;
    }

    dbg(DBG_ROUTE,"MHop: send 0x%x\n",pParent->addr);
    pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->hopcount = my_hopcount;
    pMHMsg->seqno = cur_seqno++;

    dbg(DBG_ROUTE,"MHop: out pkt 0x%x\n",pMHMsg->seqno);
    
    if (call SendMsg.send[id](pParent->addr, usMHLength, pMsg) != SUCCESS) {
      return FAIL;
    }
    return SUCCESS;

  } 

  command void *Send.getBuffer[uint8_t id](TOS_MsgPtr pMsg, uint16_t* length) {
    
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;
    
    *length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);

    return (&pMHMsg->data[0]);

  }

#if 0  
  static void forward(uint16_t destaddr, TOS_MHopMsg *pRcvMsg, uint16_t Len, uint8_t id) {
    TOS_MHopMsg *pFwdMsg;

    if (((iFwdBufHead + 1) % FWD_QUEUE_SIZE) == iFwdBufTail) {
      // Drop message if forwarding queue is full.
      return;
    }
    
    pFwdMsg = (TOS_MHopMsg *) &FwdBuffer[iFwdBufHead].data;

    memcpy(pFwdMsg,pRcvMsg,sizeof(TOS_MHopMsg));
    pFwdMsg->sourceaddr = TOS_LOCAL_ADDRESS;
    pFwdMsg->hopcount = my_hopcount;
    pFwdMsg->seqno = cur_seqno++;

    dbg(DBG_USR1, "MHop: Forwarding packet (seqno 0x%x)\n", cur_seqno);
    if (call SendMsg.send[id](destaddr, Len,&FwdBuffer[iFwdBufHead]) == SUCCESS) {
      iFwdBufHead++; iFwdBufHead %= FWD_QUEUE_SIZE;
    }
  }
#endif

  static TOS_MsgPtr mForward(TOS_MsgPtr pMsg, uint8_t id, uint16_t DestAddr) {
    TOS_MsgPtr	pNewBuf = pMsg;
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;

    if (((iFwdBufHead + 1) % FWD_QUEUE_SIZE) != iFwdBufTail) {
      pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
      pMHMsg->hopcount = my_hopcount;
      pMHMsg->seqno = cur_seqno++;
      
      if (call SendMsg.send[id](DestAddr,pMsg->length,pMsg) == SUCCESS) {
	pNewBuf = FwdBufList[iFwdBufHead];
	FwdBufList[iFwdBufHead] = pMsg;
	iFwdBufHead++; iFwdBufHead %= FWD_QUEUE_SIZE;
      }
    }

    return pNewBuf;

  }

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr pMsg) {
    TOS_MHopNeighbor	*pNeighbor;
    TOS_MHopMsg		*pMHMsg = (TOS_MHopMsg *)pMsg->data;
    uint16_t		PayloadLen = pMsg->length - offsetof(TOS_MHopMsg,data);
    bool		isDuplicate;

    call Leds.greenToggle();
    dbg(DBG_ROUTE, "MHop: Msg Rcvd, src 0x%02x, org 0x%02x, parent 0x%02x\n", 
	pMHMsg->sourceaddr, pMHMsg->originaddr, 0 /*pMHMsg->parentaddr*/);

    // Update link information
    pNeighbor = link_update(pMHMsg,&isDuplicate);

    // Check for cycles in the route tree
    if (pMHMsg->originaddr == pMsg->addr) {
      if (pMsg->addr == TOS_LOCAL_ADDRESS) 
	break_cycle();
    }
    // If this is a root beacon, may use it to override parent selection
    else if (id == AM_MULTIHOPMSG) {
      dbg(DBG_ROUTE, "MHop: Rootbeacon src=0x%x, hc=0x%x \n", pMHMsg->sourceaddr, my_hopcount);
      dbg(DBG_ROUTE, "MHop: RB goodness = %d\n",pNeighbor->goodness);
      
      if (pNeighbor->goodness > ROOT_BEACON_THRESHOLD)  {
	dbg(DBG_ROUTE, "MHop: Setting parent to %x\n", pMHMsg->sourceaddr);
	my_hopcount = pMHMsg->hopcount+1; // had better be 1

	if (pParent != pNeighbor) {
	  parent_count = 0;
	  pParent = pNeighbor;
	}
      }

      if (0 == pMHMsg->hopcount) {
	pMHMsg->hopcount++;
	//forward (TOS_BCAST_ADDR, pMHMsg, pMsg->length, id);
	mForward(pMsg,id,TOS_BCAST_ADDR);
      }
    } 
    // Ordinary message requiring forwarding
    else if ((pMsg->addr == TOS_LOCAL_ADDRESS) &&  // Addressed to local node
	     (!isDuplicate) && // Not a duplicate message from child
	     (my_hopcount < pMHMsg->hopcount)) { // Isn't going down the tree
      if ((signal Intercept.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen)) == SUCCESS) {
	if (!pParent) { 
	  // If no parent, drop message and initiate a routing update
	  post route_update();
	}
	else {
	  // Otherwise forward it
	  parent_count++;
	  //forward(pParent->addr, pMHMsg, pMsg->length, id);
	  pMsg = mForward(pMsg,id,pParent->addr);
	}
      }
    } 
    else {
      // Snoop the packet for permiscuous applications
      signal Snoop.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen);
    }

    return pMsg;
  }

  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr pMsg, bool success) {
    dbg(DBG_ROUTE, "MHop: senddone 0x%x 0x%x\n", pMsg, success);  
#ifdef PLATFORM_MICA
    if (pParent) {
      if (success == SUCCESS) {
	call Leds.redOff();
	pParent->recv_count++;
      }
      else {
	call Leds.redOn();
	pParent->fail_count++;
      }
    }
#endif
    if (pMsg == FwdBufList[iFwdBufTail]) { // Msg was from forwarding queue
      iFwdBufTail++; iFwdBufTail %= FWD_QUEUE_SIZE;
    } else {
      signal Send.sendDone[id](pMsg, success);
    } 
    return SUCCESS;
  }

  command uint16_t RouteControl.getParent() {
	if (pParent == NULL)
	  return 0xffff;
    return pParent->addr;
  }

  command uint8_t RouteControl.getQuality() {
	if (pParent == NULL)
	  return 0xff;
    return pParent->goodness;
  }

  command uint8_t RouteControl.getDepth() {
    return my_hopcount;
  }

  command uint8_t RouteControl.getOccupancy() {
    uint16_t uiOutstanding = (uint16_t)iFwdBufTail - (uint16_t)iFwdBufHead;
    uiOutstanding %= FWD_QUEUE_SIZE;
    return (uint8_t)uiOutstanding;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    TOS_MHopMsg		*pMHMsg = (TOS_MHopMsg *)msg->data;
    return pMHMsg->sourceaddr;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) {
    result_t result;

    call Timer.stop();
    timer_rate = (Interval * 1024);  // * 1024 to make the math simpler
    result = call Timer.start(TIMER_REPEAT,gUpdateInterval);

    return result;


  }

  command result_t RouteControl.manualUpdate() {

  }


  default event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }

  default event result_t Intercept.intercept[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
							 uint16_t payloadLen) {
    return SUCCESS;
  }

  default event result_t Snoop.intercept[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
						       uint16_t payloadLen) {
    return SUCCESS;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
						       uint16_t payloadLen) {
    return pMsg;
  }



}
