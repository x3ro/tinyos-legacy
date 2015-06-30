/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: RouteHelperM.nc,v 1.29 2003/03/31 22:55:23 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * library of helper function for routing component
 * intenetion is to decouple algorithm with detail implementation
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/
#include "Estimator.h"
#include "fatal.h"
includes VirtualComm;
includes AM;

module RouteHelperM {
  provides {
    interface RouteHelp;
    interface StdControl;
  }
  uses {
    interface VCSend;
    interface Estimator;
    interface ReceiveMsg as RouteReceive;
    interface VCSend as TablePacketSend;
  }

}
implementation {
  uint8_t parent;
  uint8_t hop;
  cost_t cost;

  uint8_t routeSending;
  uint8_t trialCounter;
  TOS_Msg routeMsg;

  uint8_t estimatorTicks;

  typedef struct TableEntry {
    uint8_t id;
    uint8_t valid;
    uint8_t liveliness;
    uint8_t parent;
    uint8_t hop;
    cost_t cost;
    uint8_t receiveEst;
    uint8_t sendEst;
    uint8_t childLiveliness;
    uint8_t trackInfo[TRACK_INFO_SIZE];
  } TableEntry;
  TableEntry routeTable[ROUTE_TABLE_SIZE];
  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to find an entry by node id, return the index of the table
   * @author: terence
   * @param: id
   * @return: index, if not found return ROUTE_INVALID
   */

  uint8_t findEntry(uint8_t id) {
    uint8_t i = 0;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if (routeTable[i].valid == 1 && routeTable[i].id == id) {
        return i;
      }
    }
    return ROUTE_INVALID;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This funciton determined which entry should be replace
   * in this case, we find the one with the lease send estimate
   * @author: terence
   * @param: void
   * @return: index of the table
   */

  uint8_t findEntryToBeReplaced() {
    uint8_t i = 0;
    uint8_t minSendEst = -1;
    uint8_t minSendEstIndex = ROUTE_INVALID;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if (routeTable[i].valid == 0) {
        return i;
      }
      if (routeTable[i].valid == 1 && minSendEst >= routeTable[i].sendEst) {
        minSendEst = routeTable[i].sendEst;
        minSendEstIndex = i;
      }
    }
    return minSendEstIndex;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to make a new entry give an index and a id
   * @author: terence
   * @param: index, the index of the table
   * @param: id, the node id 
   * @return: void
   */

  void newEntry(uint8_t indes, uint8_t id) {
    routeTable[indes].id = id;
    routeTable[indes].valid = 1;
    routeTable[indes].liveliness = ROUTE_MAX_LIVELINESS;
    routeTable[indes].parent = ROUTE_INVALID;
    routeTable[indes].hop = ROUTE_INVALID;
    routeTable[indes].cost = ROUTE_INVALID;  //ALEC:  NOT 0!
    routeTable[indes].receiveEst = 0;
    routeTable[indes].sendEst = 0;
    routeTable[indes].childLiveliness = 0;
    call Estimator.clearTrackInfo(routeTable[indes].trackInfo);
  }


  /*////////////////////////////////////////////////////////*/
  /**
   * it try to find a valid entry, if not, it will kill one, 
   * clear the entry return that index
   * @author: terence
   * @param: id, node id
   * @return: index
   */

  uint8_t findPreparedIndex(uint8_t id) {
    uint8_t indes = findEntry(id);
    if (indes == (uint8_t) ROUTE_INVALID) {
      indes = findEntryToBeReplaced();
      newEntry(indes, id);
    }
    return indes;
  }
  ////////////////////////////////////////////
  // packet format
  struct RoutePacket {
    uint8_t parent;
    uint8_t hop;
    cost_t cost;
    uint8_t estLength;
  };

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    estimatorTicks = 1;
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void RouteHelp.setInfo(uint8_t inputParent, uint8_t inputHop, cost_t inputCost) {
    parent = inputParent;
    hop = inputHop;
    cost = inputCost;
  }
  command uint8_t RouteHelp.getParent() {
    return parent;
  }
  command uint8_t RouteHelp.getCost() {
    return cost;
  }
  command uint8_t RouteHelp.getHop() {
    return hop;
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
  command uint8_t RouteHelp.getNeighborsEstimate(uint8_t *id, uint8_t *quality, uint8_t size) {
    uint8_t indes = findEntry(parent), i = 0, counter = 0;
    id[0] = parent;
    quality[0] = (indes == (uint8_t) ROUTE_INVALID) ? 0xff : routeTable[indes].sendEst;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if (counter == size) 
        break;
      if (routeTable[i].valid == 0) {
        continue;
      }
      if (routeTable[i].id == parent) {
        continue;
      }
      id[counter + 1] = routeTable[i].id;
      quality[counter + 1] = routeTable[i].sendEst;
      counter++;
    }
    return counter;
  }
  /*
  command uint8_t RouteHelp.getNeighborsEstimate(uint8_t *id, uint8_t *quality, uint8_t size) {
    uint8_t indes = findEntry(parent), i = 0, counter = 0;
    id[0] = parent;
    quality[0] = (indes == (uint8_t) ROUTE_INVALID) ? 0xff : routeTable[indes].sendEst;
    quality[1] = (indes == (uint8_t) ROUTE_INVALID) ? 0xff : routeTable[indes].cost;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if (counter == size) 
        break;
      if (routeTable[i].valid == 0) {
        continue;
      }
      if (routeTable[i].id == parent) {
        continue;
      }
      id[counter + 1] = routeTable[i].id;
      quality[2 * counter + 2] = routeTable[i].sendEst;
      quality[2 * counter + 3] = routeTable[i].cost;
      counter++;
    }
    return counter;
  }
  */
 

  command void RouteHelp.fillDropHeader(TOS_MsgPtr msg) {
    msg->addr = TOS_BCAST_ADDR;
  }
  command void RouteHelp.fillHeader(TOS_MsgPtr msg, uint8_t isOriginated) {
    // this will prevent retransmission, make the chanell more congestion when everyone is invalid
    if (parent == (uint8_t) ROUTE_INVALID) {
      msg->addr = TOS_BCAST_ADDR;
    } else {
      msg->addr = parent;
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * trying to detect if there is a cycle, this have to BE FAST!!!!
   * since we are not puting this into a task
   * @author: alec, terence
   * @param: void
   * @return: 1 if cycle, 0 if not
   */

  command uint8_t RouteHelp.isCycle() {
    uint8_t pParent, pIsChild;
    uint8_t indes;
    if (parent == (uint8_t) ROUTE_INVALID) return 0;
    indes = findEntry(parent);
    if (indes == (uint8_t) ROUTE_INVALID) return 0;
    pParent = routeTable[indes].parent;
    pIsChild = (routeTable[indes].childLiveliness != 0);
    if (pParent == TOS_LOCAL_ADDRESS || pIsChild == 1)
      return 1;
    return 0;
  }
  command void RouteHelp.clearChildren() {
    uint8_t i;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      routeTable[i].childLiveliness = 0;
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * so basically there is an incoming packet, fill in the child 
   * field of the table. it is so compilcated because we are going to
   * filled in the child field only if we can possibly hear it. That is
   * in our neighbhood table
   * @author: terence
   * @param: msg, the incoming message
   * @return: void
   */

  command void RouteHelp.updateChildEntry(TOS_MsgPtr msg) {
    uint8_t realSource, source, indes, *data = msg->data;
    MHSenderHeader *mhsenderHeader;
    VirtualCommHeader *vch = (VirtualCommHeader *) data;
    // if this is not a data message, return
    // msg are filter, only message to this guy
    if (msg->type != RS_DATA_TYPE || msg->addr != TOS_LOCAL_ADDRESS) return;
    // extract the real source and source
    mhsenderHeader = (MHSenderHeader *) 
      &msg->data[sizeof(VirtualCommHeader) + sizeof(RoutingHeader)];
    source = vch->source;
    realSource = (mhsenderHeader->realSource == TOS_LOCAL_ADDRESS) ?
      parent : mhsenderHeader->realSource;
    // find the index of the table
    indes = findEntry(realSource);
    // if there is such entry or it is a immediate source, dumb it in!
    if (indes != (uint8_t) ROUTE_INVALID) {
      routeTable[indes].childLiveliness = ROUTE_MAX_LIVELINESS; return;
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * We are going to decrease liveliness, call our estimator to 
   * call our periodic update
   * @author: terence
   * @param: void
   * @return: void
   */

  command void RouteHelp.updateTable() {
    uint8_t i = 0, temp;
    for(i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if (routeTable[i].valid != 1) continue;
      // for all valid entries
      if (routeTable[i].liveliness != 0){
        // WARNING
	// routeTable[i].liveliness--;
      }
      if (routeTable[i].childLiveliness != 0){
	routeTable[i].childLiveliness--;
      }
      if (routeTable[i].liveliness == 0) {
        routeTable[i].valid = 0;
      }
      
      // optional: (depends on whether the estimator needs a periodic timer command)
      temp = routeTable[i].receiveEst;
      routeTable[i].receiveEst 
        = call Estimator.timerUpdate(routeTable[i].trackInfo, routeTable[i].id, estimatorTicks);
    }
    // to prevent overflow
    estimatorTicks = (estimatorTicks + 1) % ESTIMATE_TO_ROUTE_RATIO;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * there is an incoming packet, we are going to ask our estimate 
   * to do an estimation
   * @author: terence
   * @param: msg, incoming message
   * @return: void
   */

  command void RouteHelp.estimateNode(TOS_MsgPtr msg) {
    uint8_t *data = msg->data, source, indes;
    int8_t seqnum;
    uint8_t temp;
    VirtualCommHeader *vch = (VirtualCommHeader *) data;
    source = vch->source;
    seqnum = vch->seqnum;       

    indes = findPreparedIndex(source);
    
    temp = routeTable[indes].receiveEst;
    routeTable[indes].receiveEst = call Estimator.estimate(routeTable[indes].trackInfo, seqnum);
    routeTable[indes].liveliness = ROUTE_MAX_LIVELINESS;

  }


  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to sort the table by cost and we are going 
   * to filled the input array
   * @author: terence
   * @param: ids, the input array going to be filled in
   * @param: length, the maximum length of the array
   * @return: how many entry do we filled in. notice that it can be smaller
   * than the input lenght
   */

  command uint8_t RouteHelp.getNeighbors(uint8_t *ids, uint8_t length) {
    uint8_t i, counter = 0;

    for (i = 0; i < length; i++) {
      if(routeTable[i].valid == 1) {
        ids[counter] = routeTable[i].id;
        counter++;
      }
    }
    return counter;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * someone call this function asking for information about
   * this node
   * @author: terence
   * @param: all the infomation pointer
   * @return: void
   */

  command void RouteHelp.getNeighborInfo(uint8_t id, uint8_t *parentInput, uint8_t *hopInput, 
                                         cost_t *costInput, uint8_t *sendEstInput, 
                                         uint8_t *receiveEstInput, bool *isDescendent) {
    uint8_t indes = findEntry(id);
    if (indes == (uint8_t) ROUTE_INVALID) {
      *parentInput = ROUTE_INVALID;
      *hopInput = ROUTE_INVALID;
      *costInput = 0;
      *sendEstInput = 0;
      *receiveEstInput = 0;
      *isDescendent = FALSE;
    } else {
      *parentInput = routeTable[indes].parent;
      *hopInput = routeTable[indes].hop;
      *costInput = routeTable[indes].cost;
      *sendEstInput = routeTable[indes].sendEst;
      *receiveEstInput = routeTable[indes].receiveEst;
      *isDescendent = (routeTable[indes].childLiveliness > 0);
    }
  }

  command void RouteHelp.setQuality(uint8_t id, uint8_t quality) {
    uint8_t indes = findEntry(id);
    if (indes == (uint8_t) ROUTE_INVALID)
      return;
    // just give a penalty, so next time it wouldn't get considered
    // if it get overwrite later, sendEst by routeMsg, receiveEst by Estimator, be my guest
    routeTable[indes].sendEst = quality; 
    routeTable[indes].receiveEst = quality;
  }
  /*//////////////////////////////////////////////////////// */

  /*
   * send a packet out, filled in the route packet with the current info
   * in terms of regulat expression would be 
   * parent hop cost estlength (node id + receiveEst) 
   * and then send it out to virtual comm
   * @author: terence
   * @param: void
   * @return: void
   */
  
  struct SimpleEntry {
    uint8_t valid;
    uint8_t id;
    uint8_t receiveEst;
    uint8_t sendEst;
    cost_t cost;
  };

  /*//////////////////////////////////////////////////////// */
  
  /*
   * Well, sort by the receive estimate, used by qsort for the get top receive function
   * @author: terence
   * @param: x, y two point of entries
   * @return: 1 means to the y should be the left, -1 means x should be on the left
   */

  int sortByReceiveEstFcn(const void *x, const void *y) {
    struct SimpleEntry *nx = (struct SimpleEntry *) x;
    struct SimpleEntry *ny = (struct SimpleEntry *) y;
    uint8_t xReceiveEst = nx->receiveEst, yReceiveEst = ny->receiveEst;
    if (nx->valid == 0 && ny->valid == 1) return 1;
    if (nx->valid == 0 && ny->valid == 0) return 0;
    if (nx->valid == 1 && ny->valid == 0) return -1;
    if (nx->valid == 1 && ny->valid == 1) {
      if (xReceiveEst > yReceiveEst) return -1;
      if (xReceiveEst == yReceiveEst) return 0;
      if (xReceiveEst < yReceiveEst) return 1;
    }
    return 0; // shouldn't reach here becasue it covers all the cases
  }


  command void RouteHelp.sendRoute() {
    uint8_t *data = call VCSend.getUsablePortion(routeMsg.data), i;
    struct RoutePacket *rp = (struct RoutePacket *) data;
    uint8_t maxSize = (TOSH_DATA_LENGTH - sizeof(VirtualCommHeader) - sizeof(struct RoutePacket)) / 2;
    uint8_t length, maxEstLength = 0, estLength = 0;
    struct SimpleEntry simpleEntry[ROUTE_TABLE_SIZE];
    
    // if we are sending before, why send it out
    if (routeSending == 1) return;
    // fill in the first portion of the packet
    rp->parent = parent;
    rp->hop = hop;
    rp->cost = cost;
    data = &data[sizeof(struct RoutePacket)];
    length = sizeof(struct RoutePacket);
    // we are sending it out in the order of receive estimate
    
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      simpleEntry[i].valid = routeTable[i].valid;
      simpleEntry[i].id = routeTable[i].id;
      simpleEntry[i].receiveEst = routeTable[i].receiveEst;
      simpleEntry[i].sendEst = routeTable[i].sendEst;
      simpleEntry[i].cost = routeTable[i].cost;
    }
    qsort(simpleEntry, ROUTE_TABLE_SIZE, sizeof(struct SimpleEntry), sortByReceiveEstFcn);


    // find out how much source + estimation pair we can fill
    maxEstLength = (maxSize > ROUTE_TABLE_SIZE) ? ROUTE_TABLE_SIZE : maxSize;
    for (i = 0; i < maxEstLength; i ++) {
      // is this valid
      if (simpleEntry[i].valid == 1) {
        // fill in the source, estimation pair
        data[2*i] = simpleEntry[i].id;
        data[2*i+1] = simpleEntry[i].receiveEst;
        length += 2;
        estLength += 2;
      } else {
        break;
      }
    }
    rp->estLength = estLength;
    
    // send it to virtual comm
    // if it fail, doesn't count, if success, set route sending to true
    routeSending = call VCSend.send(TOS_BCAST_ADDR, length, &routeMsg);
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * standard retrnamsission function
   */

  event void VCSend.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    trialCounter = 0;
    routeSending = 0;
  }
  event uint8_t VCSend.sendDoneFailException(TOS_MsgPtr msg) {
    uint8_t decision = 0;
    routeSending = 1;
    if (trialCounter >= ROUTE_MSG_RETRANSMIT) {
      trialCounter = 0;
      decision = 0;
    } else {
      trialCounter++;
      decision = 1;
    }
    return decision;
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * extract the packet and put it back to the table, after all this
   * signal to routing component about the packet coming
   * @author: terence
   * @param: msg, the receive packet
   * @return: pointer give back to the lower level comm layer
   */

  event TOS_MsgPtr RouteReceive.receive(TOS_MsgPtr msg) {
    // save down the packet
    uint8_t i, *data = msg->data, source, seqnum, indes;
    VirtualCommHeader *vch = (VirtualCommHeader *) data;
    struct RoutePacket *rp = (struct RoutePacket *) call VCSend.getUsablePortion(data);
    // extract the source seqnum
    source = vch->source;
    seqnum = vch->seqnum;
    
    indes = findPreparedIndex(source);
    // find a entry (prossibly kicking someone out)
    routeTable[indes].parent = rp->parent;
    routeTable[indes].hop = rp->hop;
    routeTable[indes].cost = rp->cost;
    // find out my address, extract the estimation
    data = &msg->data[sizeof(VirtualCommHeader) + sizeof(struct RoutePacket)];
    for (i = 0; i < rp->estLength; i += 2) {
      if (data[i] == TOS_LOCAL_ADDRESS) {
        routeTable[indes].sendEst = data[i + 1];
      }
    }
    routeTable[indes].liveliness = ROUTE_MAX_LIVELINESS;
    // signal up the receive route event
    signal RouteHelp.receiveRoute();
    return msg;
  }

  struct DumpTableEntry {
    uint8_t id;
    uint8_t receiveEst;
    uint8_t sendEst;
    cost_t cost;
  };
  TOS_Msg tablePacket;
  uint8_t tablePacketSending;
  uint8_t tablePacketIndex;
  task void sendTablePacketTask() {
    uint8_t counter = 0;
    uint8_t original = tablePacketIndex;
    
    struct DumpTableEntry *dte 
      = (struct DumpTableEntry *) call TablePacketSend.getUsablePortion(tablePacket.data);

    if (tablePacketSending == 1) return;

    
    while (counter < 5) {
      tablePacketIndex = (tablePacketIndex + 1) % ROUTE_TABLE_SIZE;
      if (tablePacketIndex == original) break;
      if (routeTable[tablePacketIndex].valid == 0) continue;
      dte[counter].id = routeTable[tablePacketIndex].id;
      dte[counter].receiveEst = routeTable[tablePacketIndex].receiveEst;
      dte[counter].sendEst = routeTable[tablePacketIndex].sendEst;
      dte[counter].cost = routeTable[tablePacketIndex].cost;

      counter++;

    }
        
    tablePacketSending = call TablePacketSend.send(TOS_UART_ADDR, 25, &tablePacket);
    
  }

  command void RouteHelp.sendTablePacket() {
    post sendTablePacketTask();
  }

  event void TablePacketSend.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    tablePacketSending = 0;
  }
  event uint8_t TablePacketSend.sendDoneFailException(TOS_MsgPtr msg) {
    return 0;
  }



}
