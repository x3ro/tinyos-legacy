/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: RouteHelp.nc,v 1.11 2003/03/15 10:08:39 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * library funciton for routing component
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

interface RouteHelp {
  command void setInfo(uint8_t parent, uint8_t hop, cost_t cost);
  command uint8_t getParent();
  command uint8_t getCost();
  command uint8_t getHop();
  command void setQuality(uint8_t id, uint8_t quality);
  command uint8_t getNeighborsEstimate(uint8_t *id, uint8_t *quality, uint8_t size);
  command uint8_t getNeighbors(uint8_t *ids, uint8_t length);
  command void getNeighborInfo(uint8_t id, uint8_t *parent, uint8_t *hop, cost_t *cost,
			       uint8_t *sendEst, uint8_t *receiveEst, bool *isChild);

  command void fillDropHeader(TOS_MsgPtr msg);
  command void fillHeader(TOS_MsgPtr msg, uint8_t isOriginated);
 
  command uint8_t isCycle();
  command void clearChildren();
  command void updateChildEntry(TOS_MsgPtr msg);

  command void updateTable();
  command void estimateNode(TOS_MsgPtr msg);
  
  command void sendRoute();
  event void receiveRoute();

  command void sendTablePacket();
}
