/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: ShortestPathM.nc,v 1.4 2003/03/19 09:03:07 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Shortest Path with threshold
 * Author: Alec Woo, Terence Tong
 */
/*////////////////////////////////////////////////////////*/

#include "Estimator.h"
#include "math.h"
includes UARTPacket;

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
    interface Random;
    interface Timer as OffsetTimer;
    interface Leds;
    interface MinTransDBPacket;
    
  }
}

implementation {

  enum {
    MAX_ALLOWABLE_LINK_COST = 256 * 6
  };

  /*////////////////////////////////////////////////////////*/

  /**  
   * So what the heck is this? The idea is to have a higher 
   * precision but avoid using floating point
   * the cost is stored in a finer granularity. cost of 4 means 1 expected transmission.
   * this is the unit for the cost in route message
   * the idea is to do cost = parnet cost + 1 / (sendEst * receiveEst)
   * notice that sendEst and receiveEst is using one byte to simulate a float
   * so it would be parent cost + 65535 / (sendEst * receiveEst)
   * but check this out, we are doing a integer division, there will be * a lose of information
   * so the approach iz to scale up everything
   * cost * 256 + 65536 * 256 / (sendEst * receiveEst). we use this to compare and finally
   * we round off and scale down back to the unit (cost of 4 equal 1) when we pickED our parent
   * @author: terence
   * @param: cost, parent cost
   * @param: sendEst, send estimation, uint8_t floating point
   * @param: receiveEst, receive estimation, uint8_t floating point
   * @return: uint32_t intermmediate cost
   */


  uint32_t evaluateCost(cost_t cost, uint8_t sendEst, uint8_t receiveEst) {
    uint32_t transEst = (uint32_t) sendEst * (uint32_t) receiveEst;
    uint32_t immed = ((uint32_t) 1 << 24);

    if (transEst == 0) return ((uint32_t) 1 << (uint32_t) 16);
    // DO NOT change this LINE! mica compiler is WEIRD!
    immed = immed / transEst;
    immed += ((uint32_t) cost << 6);
    return immed;
  }




  void scheduleTimer() {
    uint16_t randomizedTime; // BITRANGE = 8;
    // minimium route message interval
    randomizedTime = DATA_TO_ROUTE_RATIO * DATA_FREQ;
    // plus some randomnized time
    // call the timer
    call Timer.start(TIMER_REPEAT, randomizedTime);
  }

  /*////////////////////////////////////////////////////////*/
  /*
   * choose parent based on alec's algorithm. notice that this is purely the mrp,
   * not th hybrid. It goes through all the neighbor on eby one and 
   * @author: terence
   * @param: void
   * @return: void
   */


  void chooseParent() {
    uint8_t id[ROUTE_TABLE_SIZE], avaliableNeighbors, i, isDirectChild;
    uint8_t parent, hop, sendEst, receiveEst, oldParent;
    bool isDescendent;
    cost_t cost;
    uint8_t currentParent = ROUTE_INVALID, currentHop = ROUTE_INVALID;
    uint32_t resultingLinkCost = (uint32_t) -1, currentLinkCost = (uint32_t) -1;
    uint8_t currentSendEst = 0, currentReceiveEst = 0;
    uint8_t smallerHop, equalHopBetterEstimate;

    if (TOS_LOCAL_ADDRESS == BASE_STATION) return;
    oldParent = call RouteHelp.getParent();
    // clear the old debug info
    call MinTransDBPacket.storeOldParentInfo(ROUTE_INVALID, ROUTE_INVALID, ROUTE_INVALID, 
                                             ROUTE_INVALID, ROUTE_INVALID);
    // get the top neighbor based on pathest
    avaliableNeighbors = call RouteHelp.getNeighbors(id, ROUTE_TABLE_SIZE);
    for (i = 0; i < avaliableNeighbors; i++) {
      // kill all the children
      call RouteHelp.getNeighborInfo(id[i], &parent, &hop, &cost, 
				     &sendEst, &receiveEst, &isDescendent);

      // kill all those whose parent is myself
      isDirectChild = (parent == TOS_LOCAL_ADDRESS);
      // avoid divided by zero exception, don't bother if infomation are invalid
      if (sendEst < 25 || receiveEst < 25) continue;
      if (parent == (uint8_t) ROUTE_INVALID) continue;
      if (hop == (uint8_t) ROUTE_INVALID) continue;
      if (isDescendent || isDirectChild) continue;

      resultingLinkCost = evaluateCost(0, sendEst, receiveEst);

      if (resultingLinkCost > MAX_ALLOWABLE_LINK_COST) continue;

      // if it is my old parent, save down its info for later comparisoin
      if (id[i] == oldParent) {
        call MinTransDBPacket.storeOldParentInfo(oldParent, resultingLinkCost, 
                                                 hop, sendEst, receiveEst);
      }
      smallerHop = hop < currentHop;
      equalHopBetterEstimate = hop == currentHop && currentLinkCost > resultingLinkCost;
      
      // if it is not my child and it is greater than the currentCost
      if (smallerHop == 1 || equalHopBetterEstimate == 1) {
	// save down parent, hop, pathest
	currentLinkCost = resultingLinkCost;
	currentParent = id[i];
	currentHop = hop;
        currentSendEst = sendEst;
        currentReceiveEst = receiveEst;
      }
    }

    call MinTransDBPacket.storeBestParentInfo(currentParent, currentLinkCost, currentHop, 
                                              currentSendEst, currentReceiveEst);

    if (currentParent == (uint8_t) ROUTE_INVALID && currentHop == (uint8_t) ROUTE_INVALID) {
      call RouteHelp.setInfo(ROUTE_INVALID, ROUTE_INVALID, ROUTE_INVALID);
      call MinTransDBPacket.sendDbMsg(DB_DECISION_INVALID, ROUTE_INVALID);
      return;
    }

    call MinTransDBPacket.sendDbMsg(DB_DECISION_SWITCH, currentParent);
    call RouteHelp.setInfo(currentParent, currentHop + 1, ROUTE_INVALID);
    

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


  task void timerFired() {
    uint8_t parent, oldParent;
    call RouteHelp.updateTable();

    oldParent = call RouteHelp.getParent();
    chooseParent();
    parent = call RouteHelp.getParent();
    if (parent != oldParent) {
      call RouteHelp.clearChildren();
    }
    call RouteHelp.sendRoute();
    call RouteHelp.sendTablePacket();

  }
  task void cycleDetected() {
    chooseParent();
    call RouteHelp.sendRoute();
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * try to choose a new parent, if we choose a different parent, we send a route message
   * about the new info
   * @author: terence
   * @param: void
   * @return: void
   */
  task void receiveRoute() {
    uint8_t parent, oldParent;
    oldParent = call RouteHelp.getParent();
    chooseParent();
    parent = call RouteHelp.getParent();
    if (parent != oldParent) {
      call RouteHelp.sendRoute();
    }
  }


  command result_t StdControl.init() {
    call Random.init();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    if (TOS_LOCAL_ADDRESS == BASE_STATION) {
      // basestatino has cost of 0
      call RouteHelp.setInfo(TOS_UART_ADDR, 0, ROUTE_INVALID);
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
  /*////////////////////////////////////////////////////////*/
  /**
   * The first slot is teh parent quality slot and the rest are neighbors
   * @author: terence
   * @param: id, array of id associate with quality to be return
   * @param: quality, the receive estimate of the correspoinding id
   * @param: size, the size of the array
   * @return: void
   */

  command uint8_t RouteState.getNeighborsEstimate(uint8_t *id, uint8_t *quality, uint8_t size) {
    uint8_t num = call RouteHelp.getNeighborsEstimate(id, quality, size);
    return num;
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

  event result_t Timer.fired() {
    post timerFired();
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

    // we get some new information about our children, check cycle again
    if (call RouteHelp.isCycle()) {
      // if yes, choose parent, and send route message tell every one about the new info
      call RouteHelp.fillDropHeader(msg);
      post cycleDetected();
      return;
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

  }

  event void RouteHelp.receiveRoute() {
    // post receiveRoute();
  }







}
