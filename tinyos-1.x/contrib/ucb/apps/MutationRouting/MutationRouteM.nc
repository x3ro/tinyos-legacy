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
 * AUTHOR: August Joki
 * DATE:   6/14/04
 */


includes MutationRoute;

module MutationRouteM {
  provides {
    interface MRoute;
    interface StdControl;
  }
  uses {
    interface LinkQHood;
    interface StdControl as LinkQMsg;
    interface SendMsg as RouteSend;
    interface ReceiveMsg as RouteRecv;
    interface CommControl;
    interface RouteDiscovery;
    interface MutationHood;
    interface Timer;
    interface Timer as TimerRetry;
    interface Leds;
    interface Random;
  }
}
implementation {
  float LINK_THRESHOLD = .6;
  TOS_Msg bufff;
  TOS_MsgPtr msgbuf = &bufff;
  TOS_Msg fmsg;
  TOS_Msg tmsg;
  TOS_Msg nmsg;
  TOS_MsgPtr retry_msg = &tmsg;
  short retry_fail;
  bool mroute;
  bool new_leader;
  bool still_open;

  uint16_t trigger_id;

  uint16_t oldChild;
  uint8_t shortcutFailCount;
  uint8_t recruitFailCount;
  uint8_t state;
  uint8_t wait;
  bool cost_changed;

  // ------------------ HELPERS & INIT  ---------------------

  void zeroChildrensFailCount(uint16_t nodeID) {
    uint16_t node = nodeID;
    uint8_t cost = call MutationHood.getCost(node);
    uint16_t child = call MutationHood.getChild(node);
    if (child == node || !(call MutationHood.getSeqNo(child))
	|| cost <= call MutationHood.getCost(child)) {
      return;
    }
    node = child;
    cost = call MutationHood.getCost(child);
    while(call MutationHood.setFailCount(node,0)) {
      child = call MutationHood.getChild(node);
      if (!(call MutationHood.getSeqNo(child)) || child == node
	  || cost <= call MutationHood.getCost(child)) {
	break;
      }
      node = child; // if i have heard child and not a repeat
      cost = call MutationHood.getCost(child);
    }
  }

  result_t forward(TOS_MsgPtr pMsg) {
    MRMsg* msg;
    TOS_MsgPtr buf = &fmsg;
    msg = (MRMsg*) buf->data;
    memcpy(msg, pMsg->data, sizeof(MRMsg));

    msg->id = TOS_LOCAL_ADDRESS;
    msg->dest = ((MRMsg*) pMsg->data)->dest;
    msg->child = call MutationHood.getChild(TOS_LOCAL_ADDRESS);
    msg->cost = call MutationHood.getCost(TOS_LOCAL_ADDRESS);
    msg->seqNo = call MutationHood.getSeqNo(TOS_LOCAL_ADDRESS);

    if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != TOS_BCAST_ADDR) {
      dbg(DBG_USR3, "Routing DIRECTED GRAPH: add edge %d color: 0xFF0000 timeout: 400\n", call MutationHood.getParent(TOS_LOCAL_ADDRESS));
      call MutationHood.setFailCount(TOS_LOCAL_ADDRESS, (call MutationHood.getFailCount(TOS_LOCAL_ADDRESS) + 1));
    }
    dbg(DBG_USR3, "sending to %d { id = %d, dest = %d, child = %d, cost = %d, seqNo = %d }\n", call MutationHood.getParent(TOS_LOCAL_ADDRESS), msg->id, msg->dest, msg->child, msg->cost, msg->seqNo);
    call LinkQHood.messageSent(call MutationHood.getParent(TOS_LOCAL_ADDRESS), msg->seqNo);
    call RouteSend.send(call MutationHood.getParent(TOS_LOCAL_ADDRESS), sizeof(MRMsg), buf);
    if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != TOS_BCAST_ADDR) {
      memcpy(retry_msg->data, msg, sizeof(MRMsg));
      if (state != RECRUIT) {
	call TimerRetry.start(TIMER_REPEAT, 300);
      }
    }
    call Timer.stop();
    call Timer.start(TIMER_ONE_SHOT, NODE_TIMEOUT);
    return SUCCESS;
  }

  command result_t StdControl.init() {
    state = RESERVE;
    oldChild = 0;
    shortcutFailCount = 0;
    recruitFailCount = 0;
    mroute = FALSE;
    new_leader = FALSE;
    still_open = FALSE;
    trigger_id = 0;
    retry_fail = 0;
    cost_changed = FALSE;
    call Random.init();
    wait = (call Random.rand() % 6) + 2;
    call LinkQMsg.init();
    call MutationHood.init();
    call RouteDiscovery.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.setPromiscuous(TRUE);
    call MutationHood.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }



  // ------------------ OUTBOUND  ---------------------

  command result_t MRoute.build(EREndpoint dest) {
    state = RESERVE;
    dbg(DBG_USR3, "Initiating route discovery: commanded by a higher power");
    call RouteDiscovery.findRoute(dest);
    return SUCCESS;
  }


  command result_t MRoute.send(EREndpoint dest, uint8_t dataLen, uint8_t * data) {
    MRMsg *msg;
    uint8_t fc;

    if (generic_adc_read(TOS_LOCAL_ADDRESS, 73, 0L) != 1) {
      return SUCCESS;
    }

    msg = (MRMsg*)msgbuf->data;
    memcpy(msg->data,data,dataLen);
    msg->dest = dest;

    fc = call MutationHood.getFailCount(TOS_LOCAL_ADDRESS);
    if (state == ROUTER && fc >= MAX_MY_FAILCOUNT) {
      //dbg(DBG_USR3, "MRoute.send: state = ROUTER, fail count >= MAX\n");
      dbg(DBG_USR3, "Initiating route discovery: lost my parent");
      call RouteDiscovery.findRoute(dest);
    }
    else if ((state == ROUTER || state == SHORTCUT) && fc < MAX_MY_FAILCOUNT) {
      //dbg(DBG_USR3, "MRoute.send: state = ROUTER, fail count < MAX\n");
      call MutationHood.setID(TOS_LOCAL_ADDRESS);
      ROUTE_SEQ_NUMBER++;
      call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, ROUTE_SEQ_NUMBER);
      call MutationHood.setCost(TOS_LOCAL_ADDRESS, 0);
      call Leds.set(0);
      call MutationHood.setChild(TOS_LOCAL_ADDRESS, TOS_LOCAL_ADDRESS);
      mroute = TRUE;
      dbg(DBG_USR3, "sending routing message: dest = %d, seqNo = %d\n", dest, ROUTE_SEQ_NUMBER);
      forward(msgbuf);
    }
    else if (state == RECRUIT) {
      //dbg(DBG_USR3, "MRoute.send: state = RECRUIT\n");
      dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
      if (call MutationHood.getRoot() == TOS_LOCAL_ADDRESS) {
	//dbg(DBG_USR3, "I'm root\n");
	dbg(DBG_USR3, "Initiating route discovery: was recruit, now leader, I'm root");
	return call RouteDiscovery.findRoute(dest);
      }
      if (call MutationHood.getRoot()) {
	//dbg(DBG_USR3, "know root\n");
	state = ROUTER;
	call MutationHood.setID(TOS_LOCAL_ADDRESS);
	call MutationHood.setParent(TOS_LOCAL_ADDRESS, call MutationHood.getRoot());
	call MutationHood.setChild(TOS_LOCAL_ADDRESS, TOS_LOCAL_ADDRESS);
	ROUTE_SEQ_NUMBER++;
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, ROUTE_SEQ_NUMBER);
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	mroute = TRUE;
	dbg(DBG_USR3, "sending routing message: dest = %d, seqNo = %d\n", dest, ROUTE_SEQ_NUMBER);
	forward(msgbuf);
      }
      else {
	//dbg(DBG_USR3, "don't know root\n");
	dbg(DBG_USR3, "Initiating route discovery: was recruit, now leader, don't know root");
	return call RouteDiscovery.findRoute(dest);
      }
    }
    else if (state == CERTIFIED) {
      //dbg(DBG_USR3, "MRoute.send: state = CERTIFIED\n");
      state = ROUTER;
      call MutationHood.setID(TOS_LOCAL_ADDRESS);
      dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
      call MutationHood.setChild(TOS_LOCAL_ADDRESS, TOS_LOCAL_ADDRESS);
      ROUTE_SEQ_NUMBER++;
      call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, ROUTE_SEQ_NUMBER);
      mroute = TRUE;
      dbg(DBG_USR3, "sending routing message: dest = %d, seqNo = %d\n", dest, ROUTE_SEQ_NUMBER);
      forward(msgbuf);
    }
    else if (state == RESERVE && call MutationHood.getNumNeighbors(TOS_LOCAL_ADDRESS) >= 1) {
      //dbg(DBG_USR3, "MRoute.send: state = RESERVE, num neighbors >= 1\n");
      if (call MutationHood.getRoot()) {
	//dbg(DBG_USR3, "know root\n");
	state = ROUTER;
	call MutationHood.setID(TOS_LOCAL_ADDRESS);
	call MutationHood.setParent(TOS_LOCAL_ADDRESS, call MutationHood.getRoot());
	call MutationHood.setChild(TOS_LOCAL_ADDRESS, TOS_LOCAL_ADDRESS);
	ROUTE_SEQ_NUMBER++;
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, ROUTE_SEQ_NUMBER);
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	mroute = TRUE;
	dbg(DBG_USR3, "sending routing message: dest = %d, seqNo = %d\n", dest, ROUTE_SEQ_NUMBER);
	forward(msgbuf);
      }
      else {
	//dbg(DBG_USR3, "don't know root\n");
	dbg(DBG_USR3, "Initiating route discovery: was reserve, now leader, don't know root");
	return call RouteDiscovery.findRoute(dest);
      }
    }
    else if (state == RESERVE && call MutationHood.getNumNeighbors(TOS_LOCAL_ADDRESS) == 0) {
      //dbg(DBG_USR3, "MRoute.send: state = RESERVE, num neighbors = 0\n");
      dbg(DBG_USR3, "Initiating route discovery: was reserve, now leader, no neighbors");
      return call RouteDiscovery.findRoute(dest);
    }
    return SUCCESS;
  }

  command result_t MRoute.pursuer(EREndpoint dest) {
    call MutationHood.setChild(TOS_LOCAL_ADDRESS, call MutationHood.getHighestCostNeighbor(TOS_LOCAL_ADDRESS));
    call MutationHood.setParent(TOS_LOCAL_ADDRESS, TOS_BCAST_ADDR);
    dbg(DBG_USR3, "leader\n");
    return SUCCESS;
  }

  event result_t RouteDiscovery.routeFound(uint16_t parent, uint16_t child, uint8_t cost, uint16_t seqNo) {
    state = ROUTER;
    call MutationHood.setID(TOS_LOCAL_ADDRESS);
    call MutationHood.setParent(TOS_LOCAL_ADDRESS, parent);
    call MutationHood.setChild(TOS_LOCAL_ADDRESS, child);
    call MutationHood.setCost(TOS_LOCAL_ADDRESS, cost);
    call Leds.set(cost);
    call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, seqNo);
    call Timer.start(TIMER_ONE_SHOT, NODE_TIMEOUT);
    return SUCCESS;
  }

  default event result_t MRoute.sendDone (EREndpoint dest, uint8_t * data) {
    //dbg(DBG_USR3, "mroute.senddone\n");
    return SUCCESS;
  }

  event result_t RouteSend.sendDone(TOS_MsgPtr msg, result_t success) {
    //dbg(DBG_USR3, "routesend.senddone\n");
    if (mroute) {
      mroute = FALSE;
    }
    return SUCCESS;
  }


  // ------------------ RECV  ---------------------

  event TOS_MsgPtr RouteRecv.receive(TOS_MsgPtr pMsg) {
    MRMsg * msg = (MRMsg*)pMsg->data;
    uint16_t highestNode = call MutationHood.getHighestCostNeighbor(TOS_LOCAL_ADDRESS);
    //dbg(DBG_USR3, "MutationRoute.RouteRecv.receive from %d\n", msg->id);
    call LinkQHood.messageReceived(msg->id, msg->macSeqNo, msg->seqNo);
    if (highestNode == TOS_LOCAL_ADDRESS) {
      if (state == SHORTCUT) {
	highestNode = oldChild;
      }
      else {
	highestNode = call MutationHood.getChild(TOS_LOCAL_ADDRESS);
      }
    }
    if (highestNode == msg->id) {
      if (msg->cost == call MutationHood.getCost(msg->id)) {
	if (wait == 0) {
	  wait = (call Random.rand() % 6) + 2;
	  //dbg(DBG_USR3, "resetting wait to %d\n", wait);
	}
	else {
	  //dbg(DBG_USR3, "decrementing wait\n");
	  wait--;
	}
      }
      else {
	wait = (call Random.rand() % 6) + 2;
	cost_changed = TRUE;
	//dbg(DBG_USR3, "cost changed, resetting wait\n");
      }
    }
    else if (msg->seqNo == 0) {
      //dbg(DBG_USR3, "decrementing wait\n");
      if (wait > 0) {
	wait--;
      }
    }
    /*
    else if (call MutationHood.getCost(highestNode) < msg->cost) {
      dbg(DBG_USR3, "cost of highest node (%d) < msg cost(%d)\n", call MutationHood.getCost(highestNode), msg->cost);
      wait = (call Random.rand() % 6) + 2;
      cost_changed = TRUE;
      dbg(DBG_USR3, "cost changed, resetting wait\n");
    }
    */
    //dbg(DBG_USR3, "wait is %d\n", wait);

    call MutationHood.setID(msg->id);
    call MutationHood.setParent(msg->id, pMsg->addr);
    call MutationHood.setChild(msg->id, msg->child);
    call MutationHood.setCost(msg->id, msg->cost);
    call MutationHood.setSeqNo(msg->id, msg->seqNo);
    if (pMsg->addr != TOS_LOCAL_ADDRESS && pMsg->addr != TOS_BCAST_ADDR) {
      call MutationHood.setFailCount(msg->id, call MutationHood.getFailCount(msg->id)+1);
    }
    if (msg->id == call MutationHood.getParent(TOS_LOCAL_ADDRESS)) {
      //dbg(DBG_USR3, "receieved implicit ack\n");
      call MutationHood.setFailCount(TOS_LOCAL_ADDRESS, 0);
      //dbg(DBG_USR3, "stoping retry timer....\n");
      call TimerRetry.stop();
      retry_fail = 0;
    }
    zeroChildrensFailCount(msg->id);

    if(pMsg->addr == TOS_BCAST_ADDR && generic_adc_read(TOS_LOCAL_ADDRESS, 73, 0L) > 1) {
      MRReport_t report;
      report.x = generic_adc_read(TOS_LOCAL_ADDRESS, 128, 0);
      report.y = generic_adc_read(TOS_LOCAL_ADDRESS, 129, 0);
      dbg(DBG_USR3, "LEADER ELECTION: pursuer leader x: %d y %d\n", report.x, report.y);
      dbg(DBG_USR3, "Pursuer leader received routing message: %d\n", msg->seqNo);
      if (state == RECRUIT) {
	dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
      }
      else if (state == SHORTCUT) {
	dbg(DBG_USR3, "failed shortcut: new destination\n");
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
      }
      else if (state == CERTIFIED) {
	dbg(DBG_USR3, "certifying failed: new destination\n");
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
      }
      else if (state == ROUTER) {
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	if (still_open) {
	  dbg(DBG_USR3, "Hop DIRECTED GRAPH: remove edge %d\n", call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	}
      }
      if (still_open) {
	still_open = FALSE;
	dbg(DBG_USR3, "Hop DIRECTED GRAPH: remove edge %d\n", call MutationHood.getChild(TOS_LOCAL_ADDRESS));
      }
      state = ROUTER;
      new_leader = TRUE;
      call MutationHood.setID(TOS_LOCAL_ADDRESS);
      call MutationHood.setParent(TOS_LOCAL_ADDRESS, TOS_BCAST_ADDR);
      call MutationHood.setChild(TOS_LOCAL_ADDRESS, msg->id);
      call MutationHood.setCost(TOS_LOCAL_ADDRESS, msg->cost+1);
      call Leds.set(msg->cost+1);
      call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
      forward(pMsg);
    }
    else if (state == ROUTER) {
      //dbg(DBG_USR3, "state = ROUTER\n");
      if (msg->seqNo <= call MutationHood.getSeqNo(TOS_LOCAL_ADDRESS)) {
	//dbg(DBG_USR3, "msg seq number already heard\n");
      }
      /*
	if (pMsg->addr == TOS_BCAST_ADDR && msg->child == TOS_LOCAL_ADDRESS && call MutationHood.getParent(TOS_LOCAL_ADDRESS) == TOS_BCAST_ADDR) {
	  call MutationHood.setParent(TOS_LOCAL_ADDRESS, msg->id);
	  dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	  dbg(DBG_USR3, "Routing DIRECTED GRAPH: add edge %d color: 0xFF0000 timeout: 400\n", call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	  return pMsg;
	  }
	  else */
      if (pMsg->addr != TOS_LOCAL_ADDRESS
	  && msg->cost < (call MutationHood.getCost(TOS_LOCAL_ADDRESS) - 1)
	  && !oldChild && !(call MutationHood.getOnShortcutBlacklist(msg->id))) {
	//dbg(DBG_USR3, "msg cost < (my cost-1), no shortcut child, id is not on shortcut blacklist\n");
	if (wait > 3) wait = 3; // don't need to wait that long for just a shortcut
	if (!wait) {
	  if (call LinkQHood.getRecvQ(msg->id) > LINK_THRESHOLD) {
	    state = SHORTCUT;
	    dbg(DBG_USR3, "trying to shortcut\n");
	    oldChild = call MutationHood.getChild(TOS_LOCAL_ADDRESS);
	    if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != msg->id) {
	      call MutationHood.setChild(TOS_LOCAL_ADDRESS, msg->id);
	    }
	    dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: add edge %d color: 0xFF9900\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	  }
	  else {
	    //dbg(DBG_USR3, "receive link quality from %d not good enough to use as child\n", msg->id);
	  }
	}
      }
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->seqNo && generic_adc_read(TOS_LOCAL_ADDRESS > 1, 73, 0L)) {
	//dbg(DBG_USR3, "msg for me, msg->seqNo, destination\n");
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	call MutationHood.setParent(TOS_LOCAL_ADDRESS, TOS_BCAST_ADDR);
	if (state != SHORTCUT) {
	  if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != msg->id) {
	    call MutationHood.setChild(TOS_LOCAL_ADDRESS, msg->id);
	  }
	}
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, msg->cost+1);
	call Leds.set(msg->cost+1);
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	new_leader = FALSE;
	forward(pMsg);
      }
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && call MutationHood.getFailCount(TOS_LOCAL_ADDRESS) >= MAX_MY_FAILCOUNT) {
	//dbg(DBG_USR3, "msg is for me, fail count >= MAX\n");
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	call MutationHood.setFailCount(TOS_LOCAL_ADDRESS, 0);
	call TimerRetry.stop();
	dbg(DBG_USR3, "Initiating route discovery: forwarding message, lost parent");
	call RouteDiscovery.findRouteWithCost(msg->dest, call MutationHood.getCost(TOS_LOCAL_ADDRESS));
      }
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->seqNo && call MutationHood.getFailCount(TOS_LOCAL_ADDRESS) < MAX_MY_FAILCOUNT) {
	//dbg(DBG_USR3, "msg is for me, fail count < MAX\n");
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != msg->id) {
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, msg->id);
	}
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, msg->cost+1);
	call Leds.set(msg->cost+1);
	new_leader = FALSE;
	if (still_open) {
	  dbg(DBG_USR3, "Hop DIRECTED GRAPH: remove edge %d\n", call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	}
	forward(pMsg);
      }
      else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->child == TOS_LOCAL_ADDRESS
	       && msg->cost > call MutationHood.getCost(TOS_LOCAL_ADDRESS)
	       && (call MutationHood.getParent(TOS_LOCAL_ADDRESS) == TOS_BCAST_ADDR || call MutationHood.getSeqNo(call MutationHood.getParent(TOS_LOCAL_ADDRESS)) != 0)) {
	//dbg(DBG_USR3, "msg is NOT for me, child = me, msg cost > my cost\n");
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	if (call MutationHood.getChild(TOS_LOCAL_ADDRESS) != msg->id) {
	  call MutationHood.setParent(TOS_LOCAL_ADDRESS, msg->id);
	}
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
      }
	/*
	else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getParent(TOS_LOCAL_ADDRESS) && msg->child == msg->id) {
	  dbg(DBG_USR3, "parent is now evaider node\n");
	  state = RESERVE;
	  dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	  call MutationHood.setParent(TOS_LOCAL_ADDRESS, 0);
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, 0);
	  call Leds.set(0);
	  call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, 0);
	  call MutationHood.setFailCount(TOS_LOCAL_ADDRESS, 0);
	}
	*/
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->seqNo == 0 && msg->cost < call MutationHood.getCost(TOS_LOCAL_ADDRESS)
	       && !oldChild && !(call MutationHood.getOnShortcutBlacklist(msg->id))) {
	//dbg(DBG_USR3, "msg is for me, no seqNo, msg cost < my cost\n");
	if (wait > 3) wait = 3;
	if (!wait) {
	  if (call LinkQHood.getRecvQ(msg->id) > LINK_THRESHOLD) {
	    state = SHORTCUT;
	    dbg(DBG_USR3, "trying to shortcut\n");
	    oldChild = call MutationHood.getChild(TOS_LOCAL_ADDRESS);
	    if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != msg->id) {
	      call MutationHood.setChild(TOS_LOCAL_ADDRESS, msg->id);
	    }
	    dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: add edge %d color: 0xFF9900\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	  }
	  else {
	    //dbg(DBG_USR3, "receive link quality from %d not good enough to use as child\n", msg->id);
	  }
	}
      }
    }

    else if (state == SHORTCUT) {
      //dbg(DBG_USR3, "state = SHORTCUT\n");
      if (cost_changed) {
	//dbg(DBG_USR3, "cost changed resetting to ROUTER\n");
	state = ROUTER;
        dbg(DBG_USR3, "failed shortcut: cost changed\n");
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != oldChild) {
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, oldChild);
	  oldChild = 0;
	  call MutationHood.setOnShortcutBlacklist(msg->id, TRUE);
	  shortcutFailCount = 0;
	}
      }
      else if (shortcutFailCount >= MAX_SHORTCUT_FAILCOUNT) {
	//dbg(DBG_USR3, "shortcut fail count >= MAX\n");
	state = ROUTER;
	dbg(DBG_USR3, "shortcut failed: fail count\n");
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != oldChild) {
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, oldChild);
	  oldChild = 0;
	  call MutationHood.setOnShortcutBlacklist(msg->id, TRUE);
	  shortcutFailCount = 0;
	}
      }
      else if (pMsg->addr == TOS_BCAST_ADDR && generic_adc_read(TOS_LOCAL_ADDRESS, 73, 0L) > 1 && msg->id == oldChild) {
	state = ROUTER;
	dbg(DBG_USR3, "shortcut failed: new destination\n");
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != oldChild) {
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, oldChild);
	  oldChild = 0;
	  shortcutFailCount = 0;
	}
	forward(pMsg);
      }
      else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getChild(TOS_LOCAL_ADDRESS)) {
	//dbg(DBG_USR3, "msg is NOT for me, id is my shortcut child\n");
	shortcutFailCount++;
      }
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getChild(TOS_LOCAL_ADDRESS)) {
	//dbg(DBG_USR3, "msg is for me, id is my shortcut child\n");
	state = ROUTER;
	dbg(DBG_USR3, "shortcut succeded\n");
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, msg->cost+1);
	call Leds.set(msg->cost+1);
	shortcutFailCount = 0;
	oldChild = 0;
	if (msg->seqNo) {
	  call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	  forward(pMsg);
	}
      }
      /*   Only want shortcut child to take shortcut
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->cost < (call MutationHood.getCost(TOS_LOCAL_ADDRESS) - 1)) {
	state = ROUTER;
	dbg(DBG_USR3, "shorcut succeded\n");
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != msg->id) {
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, msg->id);
	  call MutationHood.setCost(TOS_LOCAL_ADDRESS, msg->cost+1);
	  call Leds.set(msg->cost+1);
	  shortcutFailCount = 0;
	  oldChild = 0;
	  //######### can set seq to 0?
	  if (msg->seqNo != 0) {
	    call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	  }
	}
	if (call MutationHood.getSeqNo(TOS_LOCAL_ADDRESS) != 0) {
	  forward(pMsg);
	}
      }
      */
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->id == oldChild) {
	//dbg(DBG_USR3, "msg is for me, msg id is old child\n");
	shortcutFailCount++;
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	forward(pMsg);
      }
	/*
	else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->child == TOS_LOCAL_ADDRESS
		 && msg->cost > (call MutationHood.getCost(TOS_LOCAL_ADDRESS) + 1)
		 && msg->id != call MutationHood.getParent(TOS_LOCAL_ADDRESS)) {
	  dbg(DBG_USR3, "msg is NOT for me, child = me, msg cost = my cost + 1, id is not my parent\n");
	  dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	  call MutationHood.setParent(TOS_LOCAL_ADDRESS, msg->id);
	  dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	}
	*/
    }
    else if (state == RESERVE) {
      //dbg(DBG_USR3, "state = RESERVE\n");
      if (pMsg->addr != TOS_LOCAL_ADDRESS && call MutationHood.getFailCount(msg->id) >= MAX_FAILCOUNT) {
	if (call MutationHood.getFailCount(msg->id) > (MAX_FAILCOUNT)) {
	  call MutationHood.setFailCount(msg->id, 0);
	}
	if (call MutationHood.getGrandparent(msg->id)) {
	  if (!wait) {
	    if (call LinkQHood.getRecvQ(msg->id) > LINK_THRESHOLD) {
	      uint16_t delay;
	      //dbg(DBG_USR3, "msg is NOT for me, msg fail count >= MAX, grandparent known\n");
	      state = RECRUIT;
	      dbg(DBG_USR3, "trying to recruit\n");
	      trigger_id = msg->id;
	      call MutationHood.setID(TOS_LOCAL_ADDRESS);
	      call MutationHood.setParent(TOS_LOCAL_ADDRESS, call MutationHood.getGrandparent(msg->id));
	      dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: add edge %d color: 0xFFFF00 offset: -3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	      call MutationHood.setCost(TOS_LOCAL_ADDRESS, call MutationHood.getCost(call MutationHood.getParent(TOS_LOCAL_ADDRESS)) - 1);
	      call Leds.set(call MutationHood.getCost(TOS_LOCAL_ADDRESS));
	      call MutationHood.setChild(TOS_LOCAL_ADDRESS, TOS_LOCAL_ADDRESS);
	      memcpy(((MRMsg*)retry_msg->data)->data, pMsg->data, sizeof(MRMsg));
	      delay = (call Random.rand() % 200) + 300;
	      call TimerRetry.start(TIMER_ONE_SHOT, delay);
	      //dbg(DBG_USR3, "setting delay of %d\n", delay);
	    }
	    else {
	      //dbg(DBG_USR3, "receive link quality from %d not good enough to use as child\n", msg->id);
	    }
	  }
	}
      }
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && call MutationHood.getParent(TOS_LOCAL_ADDRESS) && msg->seqNo != 0) {
	//dbg(DBG_USR3, "msg is for me, i have a parent\n");
	if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != msg->id) {
	  state = ROUTER;
	  call MutationHood.setID(TOS_LOCAL_ADDRESS);
	  call MutationHood.setCost(TOS_LOCAL_ADDRESS, msg->cost+1);
	  call Leds.set(msg->cost+1);
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, msg->id);
	  call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	  dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	}
	forward(pMsg);
      }
      else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->seqNo && call MutationHood.checkRecruit(TOS_LOCAL_ADDRESS)) {
	//dbg(DBG_USR3, "msg is NOT for me, posible recruit\n");
	if (!wait) {
	  if (call LinkQHood.getRecvQ(call MutationHood.getRecruit(TOS_LOCAL_ADDRESS)) > LINK_THRESHOLD) {
	    uint16_t delay;
	    state = RECRUIT;
	    dbg(DBG_USR3, "trying to recruit\n");
	    trigger_id = msg->id;
	    call MutationHood.setID(TOS_LOCAL_ADDRESS);
	    call MutationHood.setParent(TOS_LOCAL_ADDRESS, call MutationHood.getRecruit(TOS_LOCAL_ADDRESS));
	    dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: add edge %d color: 0xFFFF00 offset: -3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	    call MutationHood.setChild(TOS_LOCAL_ADDRESS, TOS_LOCAL_ADDRESS);
	    call MutationHood.setCost(TOS_LOCAL_ADDRESS, (call MutationHood.getCost(call MutationHood.getParent(TOS_LOCAL_ADDRESS)) - 1));
	    call Leds.set(call MutationHood.getCost(TOS_LOCAL_ADDRESS));
	    delay = (call Random.rand() % 200) + 300;
	    memcpy(((MRMsg*)retry_msg->data)->data, pMsg->data, sizeof(MRMsg));
	    call TimerRetry.start(TIMER_ONE_SHOT, delay);
	    //dbg(DBG_USR3, "setting delay of %d\n", delay);
	  }
	  else {
	    //dbg(DBG_USR3, "receive link quality from %d not good enough to use as child\n", msg->id);
	  }
	}
      }
      else if (msg->seqNo == 0) {
	dbg(DBG_USR3, "suppressing recruiting\n");
	call TimerRetry.stop();
	wait = (call Random.rand() % 6) + 2;
	//dbg(DBG_USR3, "resetting wait to %d\n", wait);
      }
    }

    else if (state == RECRUIT) {
      //dbg(DBG_USR3, "state = RECRUIT\n");
      if (msg->id == trigger_id && !cost_changed) {
	forward(pMsg);
      }
      if (cost_changed) {
	//dbg(DBG_USR3, "cost changed, reseting to RESERVE\n");
	state = RESERVE;
	dbg(DBG_USR3, "recruiting failed: cost changed\n");
	recruitFailCount = 0;
	dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	call MutationHood.setOnRecruitBlacklist(call MutationHood.getParent(TOS_LOCAL_ADDRESS), TRUE);
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, 0);
	call Leds.set(0);
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, 0);
      }
      else if(recruitFailCount >= MAX_RECRUIT_FAILCOUNT) {
	//dbg(DBG_USR3, "recruit fail count >= MAX\n");
	state = RESERVE;
	dbg(DBG_USR3, "recruiting failed: recruit fail count\n");
	recruitFailCount = 0;
	dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	call MutationHood.setOnRecruitBlacklist(call MutationHood.getParent(TOS_LOCAL_ADDRESS), TRUE);
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, 0);
	call Leds.set(0);
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, 0);
      }
      else if (call MutationHood.getFailCount(TOS_LOCAL_ADDRESS) >= MAX_MY_FAILCOUNT) {
	//dbg(DBG_USR3, "send fail count >= MAX\n");
	state = RESERVE;
	dbg(DBG_USR3, "recruiting failed: fail count\n");
	call MutationHood.setFailCount(TOS_LOCAL_ADDRESS, 0);
	call MutationHood.setOnRecruitBlacklist(call MutationHood.getParent(TOS_LOCAL_ADDRESS), TRUE);
	dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, 0);
	call Leds.set(0);
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, 0);
      }
      else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getParent(TOS_LOCAL_ADDRESS)
	       && msg->child != TOS_LOCAL_ADDRESS) {
	//dbg(DBG_USR3, "msg is NOT for me, id is my parent, child is not me\n");
	recruitFailCount++;
      }
      else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getParent(TOS_LOCAL_ADDRESS)
	       && msg->child == TOS_LOCAL_ADDRESS) {
	//dbg(DBG_USR3, "msg is NOT for me, id is my parent, child is me\n");
	state = CERTIFIED;
	dbg(DBG_USR3, "recruiting succeded\n");
	dbg(DBG_USR3, "trying to certify\n");
	trigger_id = 0;
	dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: add edge %d color: 0x00FF00 offset: 3\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	if (call MutationHood.getParent(TOS_LOCAL_ADDRESS) != call MutationHood.getLowestCostNeighbor(TOS_LOCAL_ADDRESS)) {
	  call MutationHood.setChild(TOS_LOCAL_ADDRESS, call MutationHood.getLowestCostNeighbor(TOS_LOCAL_ADDRESS));
	  dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: add edge %d color: 0xFF9900\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	}
      }
      /*
      else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getLowestCostNeighbor(TOS_LOCAL_ADDRESS)) {
	forward(pMsg);
      }
      else if (pMsg->addr == call MutationHood.getParent(TOS_LOCAL_ADDRESS)) {
	forward(pMsg);
      }
      */
      else if (msg->seqNo == 0) {
	//dbg(DBG_USR3, "heard somone else recruiting");
	state = RESERVE;
	dbg(DBG_USR3, "recruiting failed: heard another recruit\n");
	recruitFailCount = 0;
	dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	call MutationHood.setOnRecruitBlacklist(call MutationHood.getParent(TOS_LOCAL_ADDRESS), TRUE);
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, 0);
	call Leds.set(0);
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, 0);
      }
    }

    else if (state == CERTIFIED) {
      //dbg(DBG_USR3, "state = CERTIFIED\n");
      if (shortcutFailCount >= MAX_SHORTCUT_FAILCOUNT){
	state = RESERVE;
	dbg(DBG_USR3, "certifying failed: shorcut fail count\n");
	call MutationHood.setOnShortcutBlacklist(call MutationHood.getChild(TOS_LOCAL_ADDRESS), TRUE);
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, 0);
	call Leds.set(0);
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, 0);
      }
      else if (pMsg->addr != TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getChild(TOS_LOCAL_ADDRESS)) {
	shortcutFailCount++;
	forward(pMsg);
      }
      else if (pMsg->addr == TOS_LOCAL_ADDRESS && msg->id == call MutationHood.getChild(TOS_LOCAL_ADDRESS)) {
	state = ROUTER;
	dbg(DBG_USR3, "certifying succeded\n");
	call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, msg->seqNo);
	dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
	shortcutFailCount = 0;
	call MutationHood.setCost(TOS_LOCAL_ADDRESS, msg->cost+1);
	call Leds.set(msg->cost+1);
	forward(pMsg);
      }
    }
    if (cost_changed) {
      cost_changed = FALSE;
    }
    return pMsg;
  }

  event result_t TimerRetry.fired() {
    if (state == RECRUIT) {
      forward(retry_msg);
    }
    else {
      retry_fail++;
      //dbg(DBG_USR3, "resending to parent\n");
      forward(retry_msg);
      if (retry_fail > MAX_MY_FAILCOUNT) {
	call TimerRetry.stop();
	retry_fail = 0;
      }
      else {
	call MutationHood.setFailCount(TOS_LOCAL_ADDRESS, call MutationHood.getFailCount(TOS_LOCAL_ADDRESS) - 1);
      }
    }
    return SUCCESS;
  }



  event result_t Timer.fired() {
    if (state == SHORTCUT) {
      dbg(DBG_USR3, "failed shortcut: timed out\n");
      dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
      dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
    }
    else if (state == RECRUIT) {
      dbg(DBG_USR3, "recruiting failed: timed out\n");
      dbg(DBG_USR3, "Recruit%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
    }
    else if (state == CERTIFIED) {
      dbg(DBG_USR3, "certifying failed: timed out\n");
      dbg(DBG_USR3, "Shortcut%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getChild(TOS_LOCAL_ADDRESS));
      dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
    }
    else if (state == ROUTER) {
      dbg(DBG_USR3, "timed out\n");
      dbg(DBG_USR3, "Route%d DIRECTED GRAPH: remove edge %d\n", 2, call MutationHood.getParent(TOS_LOCAL_ADDRESS));
    }
    state = RESERVE;
    call MutationHood.setCost(TOS_LOCAL_ADDRESS, 0);
    call Leds.set(0);
    call MutationHood.setSeqNo(TOS_LOCAL_ADDRESS, 0);
    return SUCCESS;
  }


  command result_t MRoute.notLeader() {
    if (new_leader) {
      TOS_MsgPtr pmsg = &nmsg;
      new_leader = FALSE;
      still_open = TRUE;
      dbg(DBG_USR3, "Hop DIRECTED GRAPH: add edge %d color: 0x123456\n", call MutationHood.getChild(TOS_LOCAL_ADDRESS));
      forward(pmsg);
    }
    return SUCCESS;
  }
}
