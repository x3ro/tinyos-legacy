/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: MinTransM.nc,v 1.1 2003/03/19 01:11:50 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Rewrite of Minimum Transmission Algorithm
 * Author: Alec Woo, Terence Tong
 */
/*////////////////////////////////////////////////////////*/
#include "Estimator.h"
module MinTransM {
  provides {
    interface RouteHeader;
    interface StdControl;
    interface RouteState;
  }
  uses {
    interface CommNotifier;
    interface RouteHelp;
    interface Timer;
    interface Random;
    interface Timer as OffsetTimer;
    interface Leds;       
  }
}
implementation {

  uint8_t estimatorTicks;
  uint32_t numSendParentSuccess;
  uint32_t numSendParentFail;
  uint32_t parentLinkCost;
  uint8_t delayToInvalidateNeighborsCache;

  enum {
    // Number of ROUTE update messages to send to invalidate neighbors
    DELAY_TO_CLEAR_NEIGHBOR_CACHE = 2,
    // Min link quality for a neighbor E(num of trans) (unit of 256)
    PARENT_MAX_LINK_COST = 5 * 256,
    // COST metric threshold to switch parent (unit of 256)
    PARENT_SELECTION_THRESHOLD = 128
  };

  /**************************************************************************/
  /*
   * So what the heck is this?
   * the cost is stored in a finer granularity. cost of 4 means 1 expected transmission.
   * this is the unit for exchanging cost infomation
   * so we scale it down by 2 bits. then...
   * the idea is to do cost = parnet cost + 1 / (sendEst * receiveEst)
   * notice that sendEst and receiveEst is using one byte to simulate a float
   * so it would be parent cost + 65535 / (sendEst * receiveEst)
   * but check this out, if we do a integer division, there will be not difference between
   * these two cases sendEst = 0.7 receiveEst = 1 and sendEst = 0.8, receiveEst = 1
   * so the approach iz to scale up everything
   * cost * 256 + 65536 * 256 / (sendEst * receiveEst). we use this to compare and finally
   * we round off and scale down back to (cost of 4 equal 1)
   * @author: alec, terence
   * @param: cost, parent cost
   * @param: sendEst, send estimation, uint8_t floating point
   * @param: receiveEst, receive estimation, uint8_t floating point
   * @return: uint32_t intermmediate cost
   */


  uint32_t evaluateCost(cost_t cost, uint8_t sendEst, uint8_t receiveEst) {
    uint32_t transEst = (uint32_t) sendEst * (uint32_t) receiveEst;
    uint32_t immed = ((uint32_t) 1 << 24);
    // DO NOT change this LINE! mica compiler is WEIRD!
    immed = immed / transEst;
    immed += ((uint32_t) cost << 6);
    return immed;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * When the time to update the current parent quality, we update our
   * parent estimation and flush our data. We didn't use the estimator
   * to measure parent quality because we can have a much better infomration
   * of our parent, through statistic on retransmission
   * @author: alec
   * @param: void
   * @return: void
   */


  void updateParentQuality() {
    uint32_t transEst;
    uint32_t total;
    // we don't update our parent quality until the right time come
    if (estimatorTicks != 0) return;
    // transEst is the 256 / estimate probability (scale of 1). we need 256 because
    // we are going to raise the precission for better comparision
    // estimate probablity = success / total
    // 256 / (success / total) = 256 * total / success
    if (numSendParentSuccess == 0) {
      // to prevent overflow
      transEst = ((uint32_t) 1 << 24);
    } else {
      total = numSendParentSuccess + numSendParentFail;
      transEst = (256 * total) / numSendParentSuccess;
    }
    // save the new info
    parentLinkCost = transEst;
    // flush the data
    numSendParentSuccess = 0;
    numSendParentFail = 0;
    estimatorTicks = (estimatorTicks + 1) % ESTIMATE_TO_ROUTE_RATIO; 
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * choose parent based on alec's minimum transmission algorithm
   * It goes through all the neighbor on by one and compare
   * @author: alec, terence
   * @param: void
   * @return: void
   */

  task void chooseParent() {
    uint8_t id[ROUTE_TABLE_SIZE], avaliableNeighbors, i, isDirectChild;
    uint8_t oldParent, parent, hop, sendEst, receiveEst;
    bool isDescendent;
    cost_t cost;
    uint32_t resultingCost, currentCost = (uint32_t) -1, finalCost, oldParentCost = (uint32_t) -1;
    uint8_t currentParent = ROUTE_INVALID, currentHop = ROUTE_INVALID;
    uint8_t oldParentHop = ROUTE_INVALID;
    uint8_t currentParentSendEst = 1, currentParentReceiveEst = 1;
    
    // If I am the base station, ignore the rest.
    if (TOS_LOCAL_ADDRESS == BASE_STATION) {
      call RouteHelp.sendRoute();
      return;
    }
    // record the old parent
    oldParent = call RouteState.getParent();
    // If we are in the state of delaying, we want to keep on 
    // Invalidate's neighbors cache by sending out a route packet telling everybody
    // your newest infomation
    if (delayToInvalidateNeighborsCache != 0) {
      call RouteHelp.sendRoute();
      return;
    }
    // get the top neighbor based on pathest 
    avaliableNeighbors = call RouteHelp.getTopByCost(id, ROUTE_TABLE_SIZE);
    for (i = 0; i < avaliableNeighbors; i++) {
      call RouteHelp.getNeighborInfo(id[i], &parent, &hop, &cost, &sendEst, &receiveEst, &isDescendent);

      // kill all those whose parent is myself
      isDirectChild = (parent == TOS_LOCAL_ADDRESS);
      // avoid divided by zero exception, don't bother if information are invalid
      if (sendEst == 0 || receiveEst == 0) continue;
      // No cost, no message
      if (cost == (cost_t) ROUTE_INVALID) continue;
      // no parent, no money, no talk
      if (parent == (uint8_t) ROUTE_INVALID) continue;
      // Negative Reinforcement
      if (hop == (uint8_t) ROUTE_INVALID) continue;
      // if it is my direct child or my descendent, kill it
      if (isDescendent || isDirectChild) continue;
      // calculate the cost using our cost function
      resultingCost = evaluateCost(cost, sendEst, receiveEst);

      // trying to find the min cost here by keep track of current min
      if (currentCost > resultingCost) {
        // save down parent, hop, pathest for the best so far
        currentCost = resultingCost; // (unit of 256)
        currentParent = id[i];
        currentHop = hop + 1;
        currentParentSendEst = sendEst;
        currentParentReceiveEst = receiveEst;
      }
      // if it is my old parent, save down its info for later comparisoin
      if (id[i] == oldParent) {
        oldParentCost = parentLinkCost + (cost << 6); //(unit of 256)
        oldParentHop = hop + 1;
      }
    }
        // If i don't have a valid parent, no valid path
    if (currentParent == (uint8_t) ROUTE_INVALID && currentHop == (uint8_t) ROUTE_INVALID) {
      // then i am going to delay!
      // delayToInvalidateNeighborsCache = DELAY_TO_CLEAR_NEIGHBOR_CACHE;
      // make my route invalid
      call RouteHelp.setInfo(ROUTE_INVALID, ROUTE_INVALID, ROUTE_INVALID);
      // Broadcast out the latest route information
      call RouteHelp.sendRoute();
      return;
    }
       
    // If the best parent is the old parent, declare invalid route if 
    // the parentLinkCost is really BAD or old 
    if (currentParent == oldParent && parentLinkCost >= PARENT_MAX_LINK_COST) {
      // no valid path!
      delayToInvalidateNeighborsCache = DELAY_TO_CLEAR_NEIGHBOR_CACHE;
      call RouteHelp.setInfo(ROUTE_INVALID, ROUTE_INVALID, ROUTE_INVALID);
      // Broadcast out the latest route information
      call RouteHelp.sendRoute();
      return;
    }
    // Only switch to a new parent if improvement is greater than noise margin
    if (currentParent != oldParent && oldParentCost - currentCost > PARENT_SELECTION_THRESHOLD) {
      // Switch to this new parent!
      // scale the cost down!
      // DO NOT change this LINE! mica compiler is WEIRD!
      finalCost = currentCost >> 6;
      // final change
      call RouteHelp.setInfo(currentParent, currentHop, finalCost);  
      // parentLinkCost has unit of 256
      parentLinkCost = evaluateCost(0, currentParentSendEst, currentParentReceiveEst);
      numSendParentSuccess = 0;
      numSendParentFail = 0;
      // Broadcast out the latest route information
      call RouteHelp.sendRoute();
      return;
    }
    // so after all thses, decided to keep the old parent
    finalCost = oldParentCost >> 6;
    // final change
    call RouteHelp.setInfo(oldParent, oldParentHop, finalCost);  
    call RouteHelp.sendRoute();
    return;
    
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to update our estimation. the first one is to update
   * our current table, and their our parent quality
   * @author: alec
   * @param: void
   * @return: void
   */

  task void updateLinks() {
    // update our table, neighbor estimation
    call RouteHelp.updateTable();
    // update our parent quality
    updateParentQuality();


  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This schedule the timer to be fired every some multiple of data
   * frequency plus some random time
   * @author: alec, terence
   * @param: void
   * @return: void
   */

  void scheduleTimer() {
    uint16_t randomizedTime, BITRANGE = 8;
    // minimium route message interval
    randomizedTime = DATA_TO_ROUTE_RATIO * DATA_FREQ;
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
      // basestatino has cost of 0
      call RouteHelp.setInfo(TOS_UART_ADDR, 0, 0);
    } else {
      // rest of it should be hugh number
      call RouteHelp.setInfo(ROUTE_INVALID, ROUTE_INVALID, ROUTE_INVALID);
    }
    call OffsetTimer.start(TIMER_ONE_SHOT, DATA_FREQ / 2);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t RouteState.getParent() {
    return call RouteHelp.getParent();
  }

  command cost_t RouteState.getCost() {
    return call RouteHelp.getCost();
  }

  command result_t RouteState.getHop() {
    return call RouteHelp.getHop();
  }
  command uint8_t RouteState.getNeighborsEstimate(uint8_t *id, uint8_t *quality, uint8_t size) {
    uint8_t num = call RouteHelp.getNeighborsEstimate(id, quality, size);
    // because we are using our speical parent estimation
    // so need to fill it in
    uint32_t total = (uint32_t) numSendParentSuccess + (uint32_t) numSendParentFail;
    uint32_t numerator = (uint32_t) numSendParentSuccess * (uint32_t) 256;
    // if it is zero don't touch it
    uint8_t parentEstimate = (total == 0) ? quality[0] : numerator / total;
    quality[0] = parentEstimate;
    return num;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * when a data packet comes, we filled out the header
   * @author: alec, terence
   * @param: msg, the msg going to be sent
   * @param: isOriginated: 1 if originated from here, 0 if forward
   * @return: void
   */

  command void RouteHeader.fillHeader(TOS_MsgPtr msg, uint8_t isOriginated) {
    // we get some new information about our children, check cycle again
    if (call RouteHelp.isCycle()) {
      // if yes, choose parent, and send route message tell every one about the new info
      post chooseParent();
      // Drop this message since there is a cycle
      call RouteHelp.fillDropHeader(msg);
      return;
    }
    // fill the header
    call RouteHelp.fillHeader(msg, isOriginated);
    // to hardwire a path, uncomment this out
    /*
      if (TOS_LOCAL_ADDRESS == BASE_STATION) {
      msg->addr = TOS_UART_ADDR;
      } else {
      msg->addr = TOS_LOCAL_ADDRESS - 1;
      }
    */  

  }
  /*////////////////////////////////////////////////////////*/
  /*
   * The point of having this is to send route message in the middle of DATA_MSG
   * so that corrupting packet and conflicting packet will be minimize
   * @author: alec, terence
   * @param: 
   * @return: 
   */

  event result_t OffsetTimer.fired() {
    scheduleTimer();
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Route timer fired. So what do we do. We update the link qualities, 
   * then we choose a parent. send a route packet tell every body your new info
   * schedule next timer
   * @author: alec, terence
   * @param: void
   * @return: success
   */

  event result_t Timer.fired() {
    scheduleTimer();
    // Delay to invalidate's neighbors cache
    if (delayToInvalidateNeighborsCache != 0) {
      // decrease the tick
      delayToInvalidateNeighborsCache--;
      // if it reach zero, clear children cache
      if (delayToInvalidateNeighborsCache == 0)
        call RouteHelp.clearChildren();
    }
    // update neighbor info, parent estimation
    post updateLinks();
    // pick a route
    post chooseParent();

    return SUCCESS;

  }
  /*////////////////////////////////////////////////////////*/
  /**
   * when we receive a message from the air, we sniff it. basically 
   * feed the packet to the estimator. This receive is for all message types.
   * @author: alec, terence
   * @param: msg, the tos message sniff from the air, not neccessary directed
   * to this mote, just same am type
   * @return: void 
   */

  event void CommNotifier.notifyReceive(TOS_MsgPtr msg) {
    call RouteHelp.estimateNode(msg);
    call RouteHelp.updateChildEntry(msg);
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Comm stack has tried its best and given up or it is just a success
   * @author: alec
   * @param: msg, the message pointer just send out
   * @param: delivered, indicate if it really get send out
   * @return: void
   */

  event void CommNotifier.notifySendDone(TOS_MsgPtr msg, bool delivered) {
    // we only increase number of parent success, if it get send out
    // if we give up, that doesn't count
    if (delivered == TRUE)
      numSendParentSuccess++;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This sendDoneSuccess and sendDoneFailure is only for multihop routing.
   * This means last packet didn't get an ACK.
   * @author: alec
   * @param: msg, the message just get send, but no ack
   * @param: retransmit, the decision made by mhsender to retransmit
   * @return: void
   */

  event void CommNotifier.notifySendDoneFail(TOS_MsgPtr msg, bool retransmit) {
    numSendParentFail++;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * try to choose a new parent, if we choose a different parent, we send a route message
   * about the new info
   * @author: alec, terence
   * @param: void
   * @return: void
   */
    

  event void RouteHelp.receiveRoute() {
    uint8_t parent = call RouteHelp.getParent();
    if (parent == (uint8_t) ROUTE_INVALID) {
      post chooseParent();
    }
  }


}




