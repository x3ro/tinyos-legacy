/*
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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
 */


includes MutationRoute;


module RouteDiscoveryM {
  provides interface RouteDiscovery;

  uses {
    interface Timer as TimerReset;
    interface Timer as TimerRoute;
    interface Timer as TimerQSend;
    interface Timer as TimerPSend;
    interface SendMsg as SndRREQ;
    interface SendMsg as SndRREP;
    interface ReceiveMsg as RcvRREQ;
    interface ReceiveMsg as RcvRREP;
    interface ReceiveMsg as RcvRoute;
    interface Random;
    interface LinkQHood;
    interface MutationHood;
  }
}

implementation {
  uint16_t parent;
  uint16_t child;
  uint16_t children[MR_NUM_NEIGHBORS];
  //uint8_t costs[MR_NUM_NEIGHBORS];
  uint16_t used_children[MR_NUM_NEIGHBORS];
  uint8_t cost;
  uint16_t seqNo;
  uint8_t state;
  EREndpoint m_dest;
  TOS_Msg tosmsg;
  TOS_MsgPtr pmsg = &tosmsg;
  bool msg_in_use;
  short rrep_fail;
  bool resending;

  command result_t RouteDiscovery.init() {
    int i;
    state = IDLE;
    parent = 0;
    child = 0;
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      children[i] = 0;
      //costs[i] = 0;
      used_children[i] = 0;
    }
    cost = 0;
    seqNo = 0;
    m_dest = 0;
    msg_in_use = FALSE;
    rrep_fail = 0;
    resending = FALSE;
    call Random.init();
    call LinkQHood.init();
    return SUCCESS;
  }

  result_t RREQSend(EREndpoint dest) {
    uint16_t delay = (call Random.rand() % 200) + 300;
    m_dest = dest;
    call TimerReset.start(TIMER_ONE_SHOT, ROUTE_TIMEOUT);
    if (!msg_in_use) {
      call TimerQSend.start(TIMER_ONE_SHOT, delay);
      //dbg(DBG_USR3, "waiting %d microseconds to send RREQ ....\n", delay);
      return SUCCESS;
    }
    else {
      //dbg(DBG_USR3, "msg buffer in use\n");
      return FAIL;
    }
  }

  result_t RREPSend(EREndpoint dest) {
    RREPMsg *msg;

    if (msg_in_use) {
      //dbg (DBG_USR3, "RouteDiscovery RREPSend buffer in use");
      return FAIL;
    }
    msg = (RREPMsg*)pmsg->data;
    msg->id = TOS_LOCAL_ADDRESS;
    msg->dest = dest;
    m_dest = dest;
    msg->seqNo = seqNo;
    resending = TRUE;
    call TimerPSend.stop();
    call TimerPSend.start(TIMER_REPEAT, 50);
    return SUCCESS;
  }

  command result_t RouteDiscovery.findRoute(EREndpoint dest) {
    return call RouteDiscovery.findRouteWithCost(dest, 0);
  }

  command result_t RouteDiscovery.findRouteWithCost(EREndpoint dest, uint8_t c) {
    if (state == RREQ) {
      return SUCCESS;
    }
    state = RREQ;
    cost = c;
    RREQ_SEQ_NUMBER++;
    seqNo = RREQ_SEQ_NUMBER;
    parent = 0;
    child = TOS_LOCAL_ADDRESS;
    //dbg(DBG_USR3, "starting new Route Discovery flood\n");
    if (dest == MA_ALL) {
      return RREQSend(MA_PURSUER1);
    }
    else {
      return RREQSend(dest);
    }
  }

  event result_t SndRREQ.sendDone(TOS_MsgPtr msg, result_t success) {
    msg_in_use = FALSE;
    //dbg(DBG_USR3, "freeing RREQ buffer\n");
    return SUCCESS;
  }

  event result_t SndRREP.sendDone(TOS_MsgPtr msg, result_t success) {
    msg_in_use = FALSE;
    //dbg(DBG_USR3, "freeing RREP buffer\n");
    return SUCCESS;
  }

  event result_t TimerReset.fired() {
    state = IDLE;
    cost = 0;
    msg_in_use = FALSE;
    resending = FALSE;
    call TimerPSend.stop();
    call TimerReset.stop();
    call TimerRoute.stop();
    call TimerQSend.stop();
    return SUCCESS;
  }

  event result_t TimerRoute.fired() {
    RREPSend(m_dest);
    signal RouteDiscovery.routeFound(parent, child, cost, seqNo);
    return SUCCESS;
  }

  event result_t TimerQSend.fired() {
    RREQMsg *msg;
    if (msg_in_use) {
      //dbg(DBG_USR3, "msg already being sent\n");
      return SUCCESS;
    }
    msg_in_use = TRUE;
    msg = (RREQMsg*)pmsg->data;
    msg->id = TOS_LOCAL_ADDRESS;
    msg->dest = m_dest;
    msg->cost = cost;
    msg->seqNo = seqNo;
    call LinkQHood.messageSent(TOS_BCAST_ADDR, seqNo);
    dbg(DBG_USR3, "sending RREQ {id = %d, dest = %d, seqNo = %d, cost = %d}\n", TOS_LOCAL_ADDRESS, m_dest, seqNo, cost);
    return call SndRREQ.send(TOS_BCAST_ADDR, sizeof(RREQMsg), pmsg);
  }

  event result_t TimerPSend.fired() {
    RREPMsg *msg;
    if (msg_in_use) {
      resending = FALSE;
      //dbg(DBG_USR3, "msg already being sent\n");
      call TimerPSend.stop();
      return SUCCESS;
    }
    if (rrep_fail == 0) {
      dbg(DBG_USR3, "sending RREP {id = %d, dest = %d, seqNo = %d,} to %d\n", TOS_LOCAL_ADDRESS, m_dest, seqNo, child);
    }
    else {
      resending = TRUE;
      call TimerPSend.stop();
      call TimerPSend.start(TIMER_REPEAT, 75);
      dbg(DBG_USR3, "resending RREP {id = %d, dest = %d, seqNo = %d,} to %d\n", TOS_LOCAL_ADDRESS, m_dest, seqNo, child);
    }
    rrep_fail++;
    msg_in_use = TRUE;
    msg = (RREPMsg*)pmsg->data;
    msg->id = TOS_LOCAL_ADDRESS;
    msg->dest = m_dest;
    msg->seqNo = seqNo;
    call LinkQHood.messageSent(child, seqNo);
    call SndRREP.send(child, sizeof(RREPMsg), pmsg);
    if (rrep_fail > 2) {
      uint16_t linkQchildren[MR_NUM_NEIGHBORS];
      int i,j;
      if (child == TOS_LOCAL_ADDRESS) {
	resending = FALSE;
	call TimerPSend.stop();
	return SUCCESS;
      }
      rrep_fail = 0;
      for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
	if (used_children[i] == 0) {
	  used_children[i] = child;
	  break;
	}
      }
      call LinkQHood.getNeighbors(linkQchildren, MR_NUM_NEIGHBORS, FALSE);
      for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
	for (j = 0; j < MR_NUM_NEIGHBORS; j++) {
	  if (linkQchildren[i] == used_children[j]) {
	    break;
	  }
	}
	if (j == MR_NUM_NEIGHBORS) {
	  child = linkQchildren[i];
	  cost = call MutationHood.getCost(child) + 1;
	  break;
	}
      }
      if (i == MR_NUM_NEIGHBORS) {
	resending = FALSE;
	call TimerPSend.stop();
      }
    }
    return SUCCESS;
  }

  event TOS_MsgPtr RcvRREQ.receive(TOS_MsgPtr pMsg) {
    int ind;
    RREQMsg *msg = (RREQMsg*)pMsg->data;
    dbg(DBG_USR3, "Discovery DIRECTED GRAPH: add edge %d color: 0xCCCCCC timeout: 400\n", msg->id);
    state = RREQ;
    dbg(DBG_USR3, "received RREQ {id = %d, dest = %d, seqNo = %d, cost = %d}\n", msg->id, msg->dest, msg->seqNo, msg->cost);
    call LinkQHood.messageReceived(msg->id, msg->macSeqNo, msg->seqNo);
    call MutationHood.setID(msg->id);
    call MutationHood.setCost(msg->id, msg->cost);
    for (ind = 0; ind < MR_NUM_NEIGHBORS; ind++) {
      if (children[ind] == msg->id) {
	break;
      }
    }
    if (ind == MR_NUM_NEIGHBORS) {
      for (ind = 0; ind < MR_NUM_NEIGHBORS; ind++) {
	if (children[ind] == 0) {
	  children[ind] = msg->id;
	  break;
	}
      }
    }
    if (ind == MR_NUM_NEIGHBORS) {
      //dbg(DBG_ERROR, "TOO MANY NEIGHBORS\n");
      return pMsg;
    }
    call TimerReset.stop();
    call TimerReset.start(TIMER_ONE_SHOT, ROUTE_TIMEOUT);

    if (msg->dest == generic_adc_read(TOS_LOCAL_ADDRESS, 73, 0L)) {
      int i;
      state = IDLE;
      dbg(DBG_USR3, "RouteDiscovery destination\n");
      call TimerRoute.stop();
      child = msg->id;
      cost = msg->cost;
      for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
	if (children[i] != 0 && call MutationHood.getCost(children[i]) < cost) {
	  child = children[i];
	  cost = call MutationHood.getCost(children[i]);
	}
      }
      cost++;
      seqNo = msg->seqNo;
      parent = TOS_BCAST_ADDR;
      dbg(DBG_USR3, "Route%d DIRECTED GRAPH: clear\n", msg->dest);
      m_dest = msg->dest;
      call TimerRoute.start(TIMER_ONE_SHOT, 500);
    }

    else if (msg->seqNo == seqNo) {
      if (msg->cost >= cost) {
	//dbg(DBG_USR3, "RouteDiscovery heard higher or equal cost, not rebroadcasting\n");
	return pMsg;
      }
      else if (msg->cost < (cost - 1)) {
	//dbg(DBG_USR3, "RouteDiscovery heard lower cost child\n");
	cost =  msg->cost + 1;
	child = msg->id;
      }
      if (pmsg != NULL) {
	uint16_t delay = (call Random.rand() % 200) + 300;
	call TimerQSend.stop();
	call TimerQSend.start(TIMER_ONE_SHOT, delay);
	//dbg(DBG_USR3, "now waiting %d microseconds to send RREQ ....\n", delay);
      }
      else {
	RREQSend(msg->dest);
      }
    }

    else if (msg->seqNo > seqNo) {
      //dbg(DBG_USR3, "RouteDiscovery heard new flood\n");
      cost = msg->cost + 1;
      seqNo = msg->seqNo;
      child = msg->id;
      RREQSend(msg->dest);
    }

    return pMsg;
  }

  event TOS_MsgPtr RcvRREP.receive(TOS_MsgPtr pMsg) {
    RREPMsg *msg  = (RREPMsg*)pMsg->data;
    call LinkQHood.messageReceived(msg->id, msg->macSeqNo, msg->seqNo);
    if (parent != 0) {
      if (msg->id == child) {
	resending = FALSE;
	//dbg(DBG_USR3, "heard child send RREP, stoping resend timer ....\n");
	signal RouteDiscovery.routeFound(parent, msg->id, cost, msg->seqNo);
	call TimerPSend.stop();
      }
      else {
	int i;
	for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
	  if (msg->id == used_children[i]) {
	    resending = FALSE;
	    //dbg(DBG_USR3, "heard old child send RREP, stoping resend timer ....\n");
	    signal RouteDiscovery.routeFound(parent, msg->id, cost, msg->seqNo);
	    call TimerPSend.stop();
	  }
	}
      }
    }
    if (pMsg->addr != TOS_LOCAL_ADDRESS) {
      return pMsg;
    }

    dbg(DBG_USR3, "received RREP {id = %d, dest = %d, seqNo = %d}\n", msg->id, msg->dest, msg->seqNo);
    if (state == IDLE) {
      return pMsg;
    }

    state = IDLE;

    if (parent != 0) {
      dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", msg->dest, parent);
    }
    parent = msg->id;
    dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3 timeout: 30000\n", msg->dest, parent);
    RREPSend(msg->dest);
    signal RouteDiscovery.routeFound(parent, child, cost, seqNo);

    return pMsg;
  }

  event TOS_MsgPtr RcvRoute.receive(TOS_MsgPtr pMsg) {
    if (resending) {
      resending = FALSE;
      //dbg(DBG_USR3, "heard a Routing message, stopping resend timer ....\n");
      call TimerPSend.stop();
    }
    return pMsg;
  }

}
