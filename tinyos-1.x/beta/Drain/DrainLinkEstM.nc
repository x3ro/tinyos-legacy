//$Id: DrainLinkEstM.nc,v 1.24 2005/09/29 02:37:15 kaminw Exp $

/*								       
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

includes Drain;
includes Attrs;

/**
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

module DrainLinkEstM {

  provides {
    interface StdControl;
    interface DrainLinkEst;
    interface Drain;

    interface RouteControl;

    interface AttrList<uint16_t> as DrainNextHop 
      @nucleusAttr("DrainNextHop", ATTR_DrainNextHop);

    interface AttrList<uint16_t> as DrainNextHopCost 
      @nucleusAttr("DrainNextHopCost", ATTR_DrainNextHopCost);

    interface AttrList<uint16_t> as DrainNextHopLinkEst 
      @nucleusAttr("DrainNextHopLinkEst", ATTR_DrainNextHopLinkEst);

    interface AttrList<uint16_t> as DrainNextHopSuccessRate 
      @nucleusAttr("DrainNextHopSuccessRate", ATTR_DrainNextHopSuccessRate);

    interface AttrList<uint16_t> as DrainNextHopSwitches 
      @nucleusAttr("DrainNextHopSwitches", ATTR_DrainNextHopSwitches);
  }

  uses {
    interface Timer;

    interface Random;

    interface SendMsg;
    interface ReceiveMsg;

    interface DrainGroup;

    interface Leds;
  }
}

implementation {

  DrainRouteEntry routes[DRAIN_MAX_ROUTES];

  uint8_t seqNo;

  bool msgBufBusy;
  TOS_Msg msgBuf;

  bool timerRunning;

#define MAX(a_,b_) (a_ > b_ ? a_ : b_)
#define MIN(a_,b_) (a_ < b_ ? a_ : b_)
#define BIT_GET(x, i) ((x) & (1 << (i)))
#define BIT_SET(x, i) ((x) | (1 << (i)))
#define BIT_CLEAR(x, i) ((x) & ~(1 << (i)))

  uint16_t adjustLQI(uint8_t val);

  DrainRouteEntry* newRoute(uint16_t dest, bool defaultRoute);
  void clearRoute(DrainRouteEntry* route);
  DrainRouteEntry* getRoute(uint16_t dest);
  DrainRouteEntry* getDefaultRoute(uint16_t dest);
  DrainRouteEntry* getReadyRoute();
  void sendRoute(DrainRouteEntry* route);

  bool isGroup(uint16_t dest);
  void startTimer();

  command result_t StdControl.init() {
    
    uint8_t i;

    msgBufBusy = FALSE;
    seqNo = 0;

    for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
      clearRoute(&routes[i]);
    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  command result_t DrainLinkEst.initializeFields(TOS_MsgPtr Msg, 
						 uint8_t id, 
						 uint16_t dest, 
						 uint8_t length) {
    
    DrainMsg *pMHMsg = (DrainMsg *)&Msg->data[0];

    Msg->addr = 0;
    Msg->length = offsetof(DrainMsg,data) + length;

    if (dest == TOS_DEFAULT_ADDR) {
      if (routes[0].dest == DRAIN_INVALID_DEST) {
	dest = TOS_BCAST_ADDR;
      } else {
	dest = routes[0].dest;
      }
    }
    
    pMHMsg->type = id;
    pMHMsg->ttl = DRAIN_MAX_TTL - 1;
    pMHMsg->seqNo = seqNo++;
    pMHMsg->source = TOS_LOCAL_ADDRESS;
    pMHMsg->dest = dest;
      
    return SUCCESS;
  }

  command result_t DrainLinkEst.forwardFields(TOS_MsgPtr Msg) {

    DrainMsg *pMHMsg = (DrainMsg *)&Msg->data[0];

    Msg->addr = 0;

    pMHMsg->ttl--;
    
    if (pMHMsg->ttl == 0)
      return FAIL;
    
    return SUCCESS;
  }

  command result_t DrainLinkEst.selectRoute(TOS_MsgPtr Msg) {
					    
    DrainMsg* pMHMsg = (DrainMsg *)&Msg->data[0];
    DrainRouteEntry* route;

    if (pMHMsg->dest == TOS_BCAST_ADDR) {
      
      Msg->addr = TOS_BCAST_ADDR;
      
    } else if (pMHMsg->dest == TOS_UART_ADDR) {
      
      Msg->addr = TOS_UART_ADDR;
      
    } else {

      if (isGroup(pMHMsg->dest)) {

	route = getDefaultRoute(pMHMsg->dest);
	
      } else {
	
	route = getRoute(pMHMsg->dest);
	
      }

      if (route != NULL) {
	Msg->addr = route->nextHop;
      } else {
	Msg->addr = TOS_BCAST_ADDR;
      }
    }

    Msg->ack = 0;

    return SUCCESS;
  }

  DrainRouteEntry* getRoute(uint16_t dest) {
    DrainRouteEntry* route;
    uint8_t i;

    for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
      route = &routes[i];
      if (route->dest != DRAIN_INVALID_DEST && route->dest == dest) {
	return route;
      }
    }
    return NULL;
  }

  DrainRouteEntry* getDefaultRoute(uint16_t dest) {
    DrainRouteEntry* route;
    uint8_t i;

    for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
      route = &routes[i];
      if (route->dest != DRAIN_INVALID_DEST &&
	  route->defaultRoute == TRUE) {
	return route;
      }
    }
    return NULL;
  }

  bool isGroup(uint16_t dest) {
    return (dest >= 0xFE00 && dest <= 0xFEFF);
  }

  command result_t DrainLinkEst.messageSent(TOS_MsgPtr msg,
					    result_t success) {
    
    DrainMsg* drainMsg = (DrainMsg*) &msg->data[0];
    DrainRouteEntry* route = getRoute(drainMsg->dest);
    
    route->sentPackets++;
    if (success) {
      route->successPackets++;
    }
    return SUCCESS;
  }

  command bool DrainLinkEst.isRoot() {
    return (getRoute(TOS_LOCAL_ADDRESS) != NULL);
  }

  command result_t Drain.buildTree() {
    return call Drain.buildTreeInstance(call Random.rand() & 0xFF, FALSE);
  }

  command result_t Drain.buildTreeDefaultRoute() {
    return call Drain.buildTreeInstance(call Random.rand() & 0xFF, TRUE);
  }

  command result_t Drain.buildTreeInstance(uint8_t instance, bool defaultRoute) {

    DrainRouteEntry* route = newRoute(TOS_LOCAL_ADDRESS, defaultRoute);

    if (route == NULL) 
      return FAIL;
    
    dbg(DBG_ROUTE, "DrainLinkEstM: buildTree(instance=%d,defaultRoute=%d)\n", 
	instance, defaultRoute);

    route->treeInstance = instance;

    route->announceSeqno = 0;
    route->announceDelay = 1;

    route->nextHop = TOS_LOCAL_ADDRESS;
    route->nextHopCost = 0;
    route->nextHopLinkEst = 0;
    route->destDistance = 0;

    route->sendWaiting = TRUE;

    call Timer.start(TIMER_ONE_SHOT, 10);

    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {

    DrainBeaconMsg *pRP = (DrainBeaconMsg *)&Msg->data[0];
    DrainRouteEntry *route;
    uint16_t linkEst = 0;
    uint32_t curCost, newCost;
    bool retransmit = FALSE;

#if defined(_CC2420CONST_H)
    linkEst = adjustLQI(Msg->lqi);
#elif defined(PLATFORM_PC)
    linkEst = 
      abs(pRP->linkSource % 10 - TOS_LOCAL_ADDRESS % 10) +
      abs(pRP->linkSource / 10 - TOS_LOCAL_ADDRESS / 10);

//    dbg(DBG_ROUTE, "DrainLinkEstM: source=%d, dest=%d, est=%d\n",
//	pRP->linkSource, TOS_LOCAL_ADDRESS, linkEst);
#else
    linkEst = Msg->strength;
#endif

    dbg(DBG_ROUTE,"DrainLinkEstM: receive DrainBeaconMsg(linkSource=%d,source=%d,parent=%d,cost=%d,ttl=%d,seqno=%d,delay=%d,instance=%d,linkEst=%d)\n",
	pRP->linkSource, pRP->source, pRP->parent, pRP->cost, pRP->ttl,
	pRP->beaconSeqno, pRP->beaconDelay, pRP->treeInstance, linkEst);

    if (pRP->source == TOS_LOCAL_ADDRESS) {
      return Msg;
    }
    
    route = getRoute(pRP->source);

    if (route == NULL) {
      route = newRoute(pRP->source, pRP->defaultRoute);
      if (route == NULL) {
	dbg(DBG_ROUTE, "DrainLinkEstM: no slot for new route to dest=%d\n", pRP->source);
	return Msg;
      }
      dbg(DBG_ROUTE, "DrainLinkEstM: new route 0x%x to dest=%d\n", route, route->dest);
    }

    /*** Retransmission stuff (check for new, set the retransmit timer) ***/

    // If it's a new tree instance, discard the old sequence numbering
    // Always retransmit
    if (pRP->treeInstance != route->treeInstance) {

      if (pRP->beaconSeqno == 0) {

	// reset the sequence number to 1
	route->announceSeqno = 1;

      } else {

	// always take the sequence number
	route->announceSeqno = pRP->beaconSeqno;
      }

      retransmit = TRUE;

    } else {
      // If it's a refinement of my current tree instance, only
      // retransmit if it has a newer sequence number
      // If it wants me to bump my sequence number, do it.

      if (pRP->beaconSeqno == 0) {

	// increment the sequence number
	route->announceSeqno++;
	if (route->announceSeqno == 0)
	  route->announceSeqno++;

	retransmit = TRUE;

      } else if ((int8_t)(pRP->beaconSeqno - route->announceSeqno) > 0) {

	// if it's newer, take the sequence number
	route->announceSeqno = pRP->beaconSeqno;	
	
	retransmit = TRUE;
      }
    }

    /*** Routing stuff ***/
    curCost = (uint32_t) route->nextHopCost + (uint32_t) route->nextHopLinkEst;
    newCost = (uint32_t) pRP->cost + (uint32_t) linkEst;

    /* When to update my route:
     * - If it's a new tree.
     * - If it's from my parent.
     * - If it's from a lower-cost node that's not my child.
     */
    if (pRP->treeInstance != route->treeInstance ||
	pRP->linkSource == route->nextHop ||
	( pRP->parent != TOS_LOCAL_ADDRESS &&
	  newCost < curCost )) {

      if (pRP->treeInstance != route->treeInstance) {
	route->parentSwitches = 0;
      } else {
	if (route->nextHop != pRP->linkSource) {
	  route->parentSwitches++;
	}
      }

      dbg(DBG_ROUTE, "DrainLinkEstM: route update(dest=%d, treeInstance=%d, oldNextHop=%d, nextHop=%d, oldCost=%d, newCost=%d, distance=%d)\n",
	  pRP->source, pRP->treeInstance, route->nextHop, pRP->linkSource,
	  curCost, newCost, DRAIN_MAX_TTL - pRP->ttl);

      if (route->nextHop != pRP->linkSource) {
	route->sentPackets = 0;
	route->successPackets = 0;
      }

      route->dest = pRP->source;
      route->destDistance = DRAIN_MAX_TTL - pRP->ttl;

      route->nextHop = pRP->linkSource;
      route->nextHopCost = pRP->cost;
      route->nextHopLinkEst = linkEst;
      
      route->treeInstance = pRP->treeInstance;
    }

    if (retransmit) {
      dbg(DBG_ROUTE, "DrainLinkEstM: Preparing to retransmit beacon:dest=%d,instance=%d,seqno=%d\n", route->dest, route->treeInstance, route->announceSeqno);

      route->announceDelay = pRP->beaconDelay;
      route->announceOffset = 
	(call Random.rand() % 
	 (1024 * route->announceDelay)) + 1;

      route->sendWaiting = TRUE;
      route->announceCountdown = pRP->beaconOffset + route->announceOffset;

      startTimer();
    }

    return Msg;
  }

  uint16_t adjustLQI(uint8_t val) {
    uint16_t result = (80 - (val - 50));
    result = (((result * result) >> 3) * result) >> 3;

    /* experimenting with alternate scalings for LQI */
//    uint16_t result = 110 - val;
//    result = result * result;

    return result; 
  }

  void startTimer() {
    DrainRouteEntry* route;
    uint16_t minCountdown = 0xFFFF;
    uint8_t i;

    if (timerRunning) {
      dbg(DBG_ROUTE, "startTimer() - timer running. Returning.\n");
      return;
    }

    for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
      route = &routes[i];

      dbg(DBG_ROUTE, "route[%d] 0x%x - dest=%d, sendWaiting=%d\n", i, route, route->dest, route->sendWaiting);

      if (route->dest != DRAIN_INVALID_DEST &&
	  route->sendWaiting == TRUE) {

	dbg(DBG_ROUTE, "route[%d] fires in %d ms\n", i, route->announceCountdown);
	if (route->announceCountdown < minCountdown) {
	  minCountdown = route->announceCountdown;
	}
      }
    }

    if (minCountdown < 0xFFFF) {

      timerRunning = TRUE;
      
      for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
	route = &routes[i];
	if (route->dest != DRAIN_INVALID_DEST &&
	    route->sendWaiting == TRUE) {
	  route->announceCountdown -= minCountdown;
	}
      }
      
      if (minCountdown == 0) {
	minCountdown = 5;
      }

      call Timer.start(TIMER_ONE_SHOT, minCountdown);
    }
  }

  event result_t Timer.fired() {
    DrainRouteEntry *route;

    timerRunning = FALSE;

    route = getReadyRoute();
    if (route != NULL) {
      sendRoute(route);
    }

    startTimer();

    return SUCCESS;
  }

  DrainRouteEntry* getReadyRoute() {
    DrainRouteEntry* route;
    uint8_t i;

    for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
      route = &routes[i];
      if (route->dest != DRAIN_INVALID_DEST && 
	  route->sendWaiting == TRUE &&
	  route->announceCountdown == 0) {
	return route;
      }
    }
    return NULL;
  }

  void sendRoute(DrainRouteEntry* route) {

    TOS_MsgPtr pMsgBuf = &msgBuf;
    DrainBeaconMsg *pRP = (DrainBeaconMsg *)&pMsgBuf->data[0];

#ifdef DRAIN_ENDPOINT_ONLY
    return;
#endif

    dbg(DBG_ROUTE, "DrainLinkEstM: sending route update\n");

    if (route->dest == DRAIN_INVALID_DEST ||
	route->destDistance == DRAIN_MAX_TTL) {
      dbg(DBG_ROUTE, "DrainLinkEstM: couldn't send route (dest=%d, destDistance=%d)\n", 
	  route->dest, route->destDistance);
      route->sendWaiting = FALSE;
      return;
    }

    if (msgBufBusy) {
      return;
    }
    
    atomic msgBufBusy = TRUE;
    
    pRP->linkSource = TOS_LOCAL_ADDRESS;
    
    pRP->source = route->dest;
    pRP->parent = route->nextHop;
    pRP->cost = route->nextHopCost + route->nextHopLinkEst;
    pRP->ttl = DRAIN_MAX_TTL - route->destDistance - 1;
    pRP->treeInstance = route->treeInstance;
    pRP->beaconSeqno = route->announceSeqno;
    pRP->beaconDelay = route->announceDelay;
    pRP->beaconOffset = (route->announceDelay * 1024) - route->announceOffset;
    pRP->defaultRoute = route->defaultRoute;

    if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(DrainBeaconMsg), pMsgBuf)) {

      dbg(DBG_ROUTE,"DrainLinkEstM: send DrainBeaconMsg(linkSource=%d,source=%d,parent=%d,cost=%d,ttl=%d,seqno=%d,delay=%d,instance=%d)\n",
	  pRP->linkSource, pRP->source, pRP->parent, pRP->cost, pRP->ttl,
	  pRP->beaconSeqno, pRP->beaconDelay, pRP->treeInstance);

      route->sendWaiting = FALSE;

    } else {
      dbg(DBG_ROUTE, "send DrainBeaconMsg FAILED\n");
      // how to handle the retries if the radio is busy?
      atomic msgBufBusy = FALSE;
    }
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    if (pMsg == &msgBuf) {
      atomic msgBufBusy = FALSE;
    }
    return SUCCESS;
  }

  DrainRouteEntry* newRoute(uint16_t dest, bool defaultRoute) {
    DrainRouteEntry* route;    
    uint8_t i;
    uint8_t slot = DRAIN_INVALID_SLOT;

    if (defaultRoute) {
      for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
	route = &routes[i];
	if (route->dest != DRAIN_INVALID_DEST &&
	    route->defaultRoute == TRUE) {
	  slot = i;
	  break;
	}
      }
    }
    
    if (slot == DRAIN_INVALID_SLOT) {
      for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
	route = &routes[i];
	if (route->dest == DRAIN_INVALID_DEST) {
	  slot = i;
	  break;
	}
      }
    }

    if (slot == DRAIN_INVALID_SLOT) {
      for(i = 0; i < DRAIN_MAX_ROUTES; i++) {
	route = &routes[i];
	if (route->dest != DRAIN_INVALID_DEST &&
	    route->defaultRoute == FALSE) {
	  slot = i;
	  break;
	}
      }
    }

    if (slot == DRAIN_INVALID_SLOT) {
      return NULL;
    }

    dbg(DBG_ROUTE, "DrainLinkEstM: new route in slot %d 0x%x\n", slot, &routes[slot]);

    route = &routes[slot];

    clearRoute(route);
    route->dest = dest;
    route->defaultRoute = defaultRoute;
    return route;
  }

  void clearRoute(DrainRouteEntry* route) {

    route->dest = DRAIN_INVALID_DEST;
    route->nextHop = TOS_BCAST_ADDR;
    
    route->nextHopCost = 0xFFFF;
    route->nextHopLinkEst = 0xFFFF;
    
    route->destDistance = 0;
    route->treeInstance = 0;

    route->announceSeqno = 1;
    route->announceDelay = 0;

    route->defaultRoute = 0;
  }

  command uint16_t RouteControl.getParent() {
    return routes[0].nextHop;
  }

  command uint8_t RouteControl.getDepth() {
    return routes[0].destDistance;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    return 0;
  }

  command uint8_t RouteControl.getOccupancy() {
    return 0;
  }

  command uint8_t RouteControl.getQuality() {
    return 0;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) {
    return FAIL;
  }

  command result_t RouteControl.manualUpdate() {
    return FAIL;
  }

  command result_t DrainNextHop.get(uint16_t* buf, uint8_t idx) {
    if (idx >= DRAIN_MAX_ROUTES) {
      return FAIL;
    }
    memcpy(buf, &routes[idx].nextHop, sizeof(uint16_t));
    signal DrainNextHop.getDone(buf);
    return SUCCESS;
  }

  command result_t DrainNextHopCost.get(uint16_t* buf, uint8_t idx) {
    uint32_t curCost;

    if (idx >= DRAIN_MAX_ROUTES) {
      return FAIL;
    }
    curCost = (uint16_t)((uint32_t) routes[idx].nextHopCost + 
			 (uint32_t) routes[idx].nextHopLinkEst);

    memcpy(buf, &curCost, sizeof(uint16_t));
    signal DrainNextHopCost.getDone(buf);
    return SUCCESS;
  }

  command result_t DrainNextHopLinkEst.get(uint16_t* buf, uint8_t idx) {
    if (idx >= DRAIN_MAX_ROUTES) {
      return FAIL;
    }
    memcpy(buf, &routes[idx].nextHopLinkEst, sizeof(uint16_t));
    signal DrainNextHopLinkEst.getDone(buf);
    return SUCCESS;
  }

  command result_t DrainNextHopSwitches.get(uint16_t* buf, uint8_t idx) {
    if (idx >= DRAIN_MAX_ROUTES) {
      return FAIL;
    }
    memcpy(buf, &routes[idx].parentSwitches, sizeof(uint16_t));
    signal DrainNextHopSwitches.getDone(buf);
    return SUCCESS;
  }

  command result_t DrainNextHopSuccessRate.get(uint16_t* buf, uint8_t idx) {
    uint16_t successRate;
    DrainRouteEntry* route;
    if (idx >= DRAIN_MAX_ROUTES) {
      return FAIL;
    }
    route = &routes[idx];
    if (route->sentPackets == 0) {
      successRate = 0;
    } else {
      successRate = 
	(((uint32_t)route->successPackets) << 8) / 
	((uint32_t)route->sentPackets);
    }
    memcpy(buf, &successRate, sizeof(uint16_t));
    signal DrainNextHopSuccessRate.getDone(buf);
    return SUCCESS;
  }
}

