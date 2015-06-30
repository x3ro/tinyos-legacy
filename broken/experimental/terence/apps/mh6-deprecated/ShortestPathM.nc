/*////////////////////////////////////////////////////////*/
/**
 * alec's mrp algorithm with my modification
 * @author: terence
 * @param: 
 * @return: 
 */
module ShortestPathM {
  provides {
    interface RouteHeader;
    interface StdControl;
    interface RouteState;
  }
  uses {
    interface CommNotifier;
    interface RouteHelp;
    interface Timer;
    interface Children;
    interface Random;
    interface Timer as OffsetTimer;
    interface Leds;

  }
}

implementation {


  void scheduleTimer() {
    uint16_t randomizedTime, BITRANGE = 8;
    // minimium route message interval
    randomizedTime = 2 * DATA_FREQ;
    // plus some randomnized time
    randomizedTime += call Random.rand() >> (16 - BITRANGE);
    // call the timer
    call Timer.start(TIMER_ONE_SHOT, randomizedTime);
  }

  command result_t StdControl.init() {
    call Random.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (TOS_LOCAL_ADDRESS == BASE_STATION) {
      call RouteHelp.setInfo(TOS_UART_ADDR, 0, 255);
    } else {
      call RouteHelp.setInfo(ROUTE_INVALID, ROUTE_INVALID, 0);
    }
    call OffsetTimer.start(TIMER_ONE_SHOT, DATA_FREQ / 2);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  command result_t RouteState.getParent() {
    uint8_t parent, hop, cost;
    call RouteHelp.getInfo(&parent, &hop, &cost);
    return parent;

  }
  command result_t RouteState.getCost() {
    uint8_t parent, hop, cost;
    call RouteHelp.getInfo(&parent, &hop, &cost);
    return cost;

  }
  command result_t RouteState.getHop() {
    uint8_t parent, hop, cost;
    call RouteHelp.getInfo(&parent, &hop, &cost);
    return hop;
  }


  /*////////////////////////////////////////////////////////*/
  /**
   * trying to detect if there is a cycle
   * @author: terence
   * @param: void
   * @return: 1 if cycle, 0 if not
   */

  uint8_t detectCycle() {
    uint8_t parent, hop, cost;
    uint8_t pParent, pHop, pCost, pSendEst, pReceiveEst;
    call RouteHelp.getInfo(&parent, &hop, &cost);
    // if my child, grand child, grand grand child is my parent, CRAP!
    // or if my child, grand child... is me, CRAP
    if (call Children.isChild(parent) || call Children.isChild(TOS_LOCAL_ADDRESS))
      return 1;
    // check the same thing, with different resources
    call RouteHelp.getNeighborInfo(parent, &pParent, &pHop, &pCost, &pSendEst, &pReceiveEst);
    if (pParent == TOS_LOCAL_ADDRESS) 
      return 1;
    return 0;
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * choose parent based on alec's algorithm. notice that this is purely the mrp,
   * not th hybrid. It goes through all the neighbor on eby one and 
   * @author: terence
   * @param: void
   * @return: void
   */

  void chooseParent() {
    uint8_t id[ROUTE_TABLE_SIZE], avaliableNeighbors, i, isChild, isDirectChild;
    uint8_t parent, hop, cost, sendEst, receiveEst;
    uint8_t resultingCost;
    uint8_t currentCost = 0, currentParent = ROUTE_INVALID, currentHop = ROUTE_INVALID;
    if (TOS_LOCAL_ADDRESS == BASE_STATION) return;
    // get the top neighbor based on pathest
    avaliableNeighbors = call RouteHelp.getTopByCost(id, ROUTE_TABLE_SIZE);
    for (i = 0; i < avaliableNeighbors; i++) {
      // kill all the children
      isChild = call Children.isChild(id[i]);
      call RouteHelp.getNeighborInfo(id[i], &parent, &hop, &cost, &sendEst, &receiveEst);
      // kill all those whose parent is myself
      isDirectChild = (parent == TOS_LOCAL_ADDRESS);
      resultingCost = cost * sendEst / 256;
      // don't even thing about it if estimation i1s less that 0.1
      if (resultingCost < 25) continue;
      // if it is not my child and it is greater than the currentCost
      if (!isChild && !isDirectChild && currentCost <= resultingCost) {
				// save down parent, hop, pathest
	currentCost = resultingCost;
	currentParent = id[i];
	currentHop = hop + 1;
      }
    }
    if (currentParent == (uint8_t) ROUTE_INVALID && currentHop == (uint8_t) ROUTE_INVALID) return;
    // finally change
    call RouteHelp.setInfo(currentParent, currentHop, currentCost);
  }



  /*////////////////////////////////////////////////////////*/
  /**
   * The point of having this is to send route message in the middle of DATA_MSG
   * so that corrupting packet and conflicting packet will be minimize
   * @author: terence
   * @param: 
   * @return: 
   */

  event result_t OffsetTimer.fired() {
    scheduleTimer();
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Route timer fired. So what do we do. We decrease the liveliness of the table
   * then we choose a parent. send a route packet tell every body your new info
   * schedule next timer
   * @author: terence
   * @param: void
   * @return: success
   */

  event result_t Timer.fired() {
    uint8_t parent, hop, cost, oldParent;
    call RouteHelp.decreaseLiveliness();
    call RouteHelp.getInfo(&parent, &hop, &cost);
    chooseParent();
    call RouteHelp.getInfo(&oldParent, &hop, &cost);
    if (parent != oldParent) {
      call Children.clear();
    }
    call RouteHelp.sendRoute();
    scheduleTimer();
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * when a data packet comes, we filled out the header
   * @author: terence
   * @param: msg, the msg going to be sent
   * @param: isOriginated: 1 if originated from here, 0 if forward
   * @return: void
   */
  command void RouteHeader.fillHeader(TOS_MsgPtr msg, uint8_t isOriginated) {
    VirtualCommHeader *vch = (VirtualCommHeader *) msg->data;
    // if it is forward message, ask the children component to log it
    if (isOriginated == 0) {
      call Children.receivePacket(vch->source);
    }
    // we get some new information about our children, check cycle again
    if (detectCycle()) {
      // if yes, choose parent, and send route message tell every one about the new info
      chooseParent();
      call RouteHelp.sendRoute();
    }
    // fill the header
    call RouteHelp.fillHeader(msg, isOriginated);
    /*
      if (TOS_LOCAL_ADDRESS == BASE_STATION) {
      msg->addr = TOS_UART_ADDR;
      } else {
      msg->addr = TOS_LOCAL_ADDRESS - 1;
      }
    */


  }

  /*////////////////////////////////////////////////////////*/
  /**
   * when we receive a message from the air, we sniff it. basically 
   * feed the packet to the estimator
   * @author: terence
   * @param: 
   * @return: 
   */

  event void CommNotifier.notifyReceive(TOS_MsgPtr msg) {
    call RouteHelp.sniffData(msg);
  }
  event void CommNotifier.notifySendDoneSuccess(TOS_MsgPtr msg) {
  }
  event void CommNotifier.notifySendDoneFail(TOS_MsgPtr msg, uint8_t retransmit) {
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * try to choose a new parent, if we choose a different parent, we send a route message
   * about the new info
   * @author: terence
   * @param: void
   * @return: void
   */

  event void RouteHelp.receiveRoute() {
    uint8_t parent, hop, cost, oldParent;
    call RouteHelp.getInfo(&parent, &hop, &cost);
    chooseParent();
    call RouteHelp.getInfo(&oldParent, &hop, &cost);
    if (parent != oldParent) {
      call RouteHelp.sendRoute();
    }
  }
	

}
