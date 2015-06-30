/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: MHDispatcherM.nc,v 1.5 2003/02/14 23:40:53 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * This is basically a hub
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

#include "fatal.h"
includes MHSender;
includes VirtualComm;
includes Routing;
includes RoutingStackShared;

module MHDispatcherM {
  provides {
    interface MultiHopSend[uint8_t msgId];
    interface MHSend2Comm;
    interface CommNotifier;
    interface ReceiveMsg as ForwardReceive;
  }
  uses {
    interface BareSendMsg as Originated[uint8_t msgId];
    interface RouteHeader;
    interface VCSend;
    interface ReceiveMsg as ReceiveAll;

  }
}


implementation {
  // order is vc header, routing header, mhsender header
  uint8_t getOtherHeaderSize() {
    uint8_t size = 0;
    size += sizeof(MHSenderHeader);
    size += sizeof(RoutingHeader);
    return size;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * the useable portion is the data offseted by all the header
   * @author: terence
   * @param: 
   * @return: 
   */

  command uint8_t* MultiHopSend.getUsablePortion[uint8_t msgId](uint8_t *data) {
    data += sizeof(VirtualCommHeader);
    data += getOtherHeaderSize();
    return data;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * when mulihop appliation try to send a packet, we immediatlly put the adjusted 
   * length to the packet
   * and call mhsender to hander it
   * @author: terence
   * @param: msg, the message multihop application want to send
   * @param: length, the length of the data multihop application put in
   * @return: 
   */

  command result_t MultiHopSend.send[uint8_t msgId](TOS_MsgPtr msg, uint8_t length) {
    msg->length = length + getOtherHeaderSize();
    return call Originated.send[msgId](msg);
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * we signal the multihop appliation of the final result
   * @author: terence
   * @param: 
   * @return: 
   */

  event result_t Originated.sendDone[uint8_t msgId](TOS_MsgPtr msg, result_t success) {
    signal MultiHopSend.sendDone[msgId](msg, success);
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * just want to make sure everything we send are of am type RS_DATA_TYPE
   * ask routing to fill it out and send it to virtual comm
   * @author: terence
   * @param: msg, the message mhsender want to send out
   * @param: isOriginated: it is a forward packet, or oritinated from this mote
   * @return: the result of the virtual comm sending
   */

  command result_t MHSend2Comm.send(TOS_MsgPtr msg, uint8_t isOriginated) {

    msg->type = RS_DATA_TYPE;
    // ask Routing to fill out header
    call RouteHeader.fillHeader(msg, isOriginated);
    // call VCSend to really send data out
    return call VCSend.send(msg->addr, msg->length, msg);
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * so signal mhsender that we are done with th epacket
   * @author: terence
   * @param: msg, the msg just sent
   * @return: void
   */
  event void VCSend.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    signal CommNotifier.notifySendDone(msg, delivered);
    signal MHSend2Comm.moveOnNextPacket(msg);
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * tell mhsender that it fail, does it want to retransmit?
   * also tell routing about that
   * @author: terence
   * @param: msg, the message just got send but fail
   * @return: the retransmit decision
   */

  event uint8_t VCSend.sendDoneFailException(TOS_MsgPtr msg) {
    uint8_t retransmitDecision;
    retransmitDecision = signal MHSend2Comm.sendDoneFailException(msg);
    signal CommNotifier.notifySendDoneFail(msg, retransmitDecision);
    return retransmitDecision;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * this event comes from inside the AM stack, it sniff all the packet
   * if this is a uart message, it discard it
   * if the message is for this mote and right am type, it is forward data
   * sniff the packet
   * @author: terence
   * @param: 
   * @return: 
   */

  event TOS_MsgPtr ReceiveAll.receive(TOS_MsgPtr msg) {
    if (msg->addr == TOS_UART_ADDR) return msg;
    if (msg->group != TOS_AM_GROUP) return msg;
    signal CommNotifier.notifyReceive(msg);
    if (msg->addr == TOS_LOCAL_ADDRESS &&
        msg->type == RS_DATA_TYPE) {
      msg->length -= sizeof(VirtualCommHeader);
      return signal ForwardReceive.receive(msg);
    }
    return msg;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * not suppose to happen
   * @author: terence
   * @param: msg
   * @param: success
   * @return: void
   */

  default event void MultiHopSend.sendDone[uint8_t msgId](TOS_MsgPtr msg, uint8_t success) {
    FATAL("MHDispatcher: signal to unknown applications");
  }

}



