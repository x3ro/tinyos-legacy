includes UARTPacket;

module UARTPacketM {
  provides {
    interface MinTransDBPacket;
    
  }
  uses {
    interface VCSend as MinTransDBSend;
    interface RouteHelp;
  }

}
implementation {
  
  // #define PLOT_PACKET 1

  typedef struct RouteDBMsg {
    uint8_t decision;

    uint8_t oldParent;
    uint16_t oldParentLinkCost;
    uint16_t oldParentCost;
    uint8_t oldParentSendEst;
    uint8_t oldParentReceiveEst;

    uint8_t bestParent;
    uint16_t bestParentLinkCost;
    uint16_t bestParentCost;
    uint8_t bestParentSendEst;
    uint8_t bestParentReceiveEst;
    
    uint8_t parent;
    uint8_t dbSeqnum;
  } RouteDBMsg;

  uint8_t dbSeqnum;

  TOS_Msg dbMsg;
  uint8_t dbSending;

  command void MinTransDBPacket.storeOldParentInfo(uint8_t oldParent, uint16_t oldParentLinkCost, 
						   uint16_t oldParentCost, 
						   uint8_t oldParentSendEst, 
						   uint8_t oldParentReceiveEst) {
    RouteDBMsg *routeDbMsg;
    if (dbSending == 1) return;
    routeDbMsg = (RouteDBMsg *) call MinTransDBSend.getUsablePortion(dbMsg.data);
    routeDbMsg->oldParent = oldParent;
    routeDbMsg->oldParentLinkCost = oldParentLinkCost;
    routeDbMsg->oldParentCost = oldParentCost;
    routeDbMsg->oldParentSendEst = oldParentSendEst;
    routeDbMsg->oldParentReceiveEst = oldParentReceiveEst;
  }
  command void MinTransDBPacket.storeBestParentInfo(uint8_t bestParent, 
						    uint16_t bestParentLinkCost, 
						    uint16_t bestParentCost, 
						    uint8_t bestParentSendEst, 
						    uint8_t bestParentReceiveEst) {
    RouteDBMsg *routeDbMsg;
    if (dbSending == 1) return;
    routeDbMsg = (RouteDBMsg *) call MinTransDBSend.getUsablePortion(dbMsg.data);
    routeDbMsg->bestParent = bestParent;
    routeDbMsg->bestParentLinkCost = bestParentLinkCost;
    routeDbMsg->bestParentCost = bestParentCost;
    routeDbMsg->bestParentSendEst = bestParentSendEst;
    routeDbMsg->bestParentReceiveEst = bestParentReceiveEst;
  }

  command void MinTransDBPacket.sendDbMsg(uint8_t decision, uint8_t parent) {
    RouteDBMsg *routeDbMsg;
    dbSeqnum++;
    if (dbSending == 1) return;
    routeDbMsg = (RouteDBMsg *) call MinTransDBSend.getUsablePortion(dbMsg.data);
    routeDbMsg->decision = decision;
    routeDbMsg->dbSeqnum = dbSeqnum;
    routeDbMsg->parent = parent;
    dbSending = call MinTransDBSend.send(TOS_UART_ADDR, sizeof(RouteDBMsg), &dbMsg);
  }
  
  event void MinTransDBSend.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    dbSending = 0;
  }

  event uint8_t MinTransDBSend.sendDoneFailException(TOS_MsgPtr msg) {
    return 0;
  }

  event void RouteHelp.receiveRoute() {

  }


}
