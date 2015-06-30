//$Id: DripSendM.nc,v 1.1 2005/10/27 21:29:43 gtolle Exp $

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

/**
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

generic module DripSendM() {
  provides interface StdControl;
  provides interface Send;
  provides interface SendMsg;
  provides interface Receive;

  uses interface Receive as DripReceive;
  uses interface Drip;
  uses interface GroupManager;
  uses interface Leds;
}
implementation {
  
  enum {
    DRIPSEND_OUTBUF_SIZE = TOSH_DATA_LENGTH - offsetof(DripMsg,data),
  };

  TOS_MsgPtr msgHolder;
  uint8_t outBuf[DRIPSEND_OUTBUF_SIZE];
  uint8_t outLength;
  bool outBufBusy;

  uint16_t receivedMsgs;
  uint16_t forwardedMsgs;

  task void sendDoneTask();
  task void sendMsgDoneTask();

  command result_t StdControl.init() {
    call Drip.init();
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  command void* Send.getBuffer(TOS_MsgPtr pMsg, uint16_t* length) {
    DripMsg* dripMsg = (DripMsg*) &pMsg->data[0];
    AddressMsg* addressMsg = (AddressMsg*) &dripMsg->data[0];

    *length = TOSH_DATA_LENGTH - 
      offsetof(DripMsg,data) - offsetof(AddressMsg, data);
    
    return &addressMsg->data[0];
  }

  command result_t Send.send(TOS_MsgPtr msg, uint16_t length) {

    DripMsg* dripMsgIn = (DripMsg*) &msg->data[0];
    AddressMsg* addressMsgIn = (AddressMsg*) &dripMsgIn->data[0];
    AddressMsg* addressMsgOut = (AddressMsg*) &outBuf[0];
    
    if (outBufBusy) {
      return FAIL;
    }

    memcpy(addressMsgOut, addressMsgIn, length);

    outLength = length;
    msgHolder = msg;

    dbg(DBG_USR1, "Addrmsg = %x, addrIn->dest=%d\n", &dripMsgIn->data[0],
	addressMsgIn->dest);

    dbg(DBG_USR1, "DripSendM: Bridge-sending a message to group %d, length=%d\n", 
	addressMsgOut->dest, length);

    call Drip.change();

    post sendDoneTask();
    return SUCCESS;
  }

  command result_t SendMsg.send(uint16_t dest, uint8_t length, TOS_MsgPtr msg) {

    DripMsg* dripMsgIn = (DripMsg*) &msg->data[0];
    AddressMsg* addressMsgIn = (AddressMsg*) &dripMsgIn->data[0];
    AddressMsg* addressMsgOut = (AddressMsg*) &outBuf[0];

    if (outBufBusy) {
      return FAIL;
    }

    addressMsgOut->source = TOS_LOCAL_ADDRESS;
    addressMsgOut->dest = dest;
    
    memcpy(&addressMsgOut->data[0], &addressMsgIn->data[0], length);

    dbg(DBG_USR1, "Addrmsg = %x, addrIn->dest=%d\n", &dripMsgIn->data[0],
	addressMsgIn->dest);

    outLength = offsetof(AddressMsg,data) + length;
    msgHolder = msg;

    dbg(DBG_USR1, "DripSendM: Sending a message to group %d\n", 
	addressMsgOut->dest);

    call Drip.change();

    post sendMsgDoneTask();
    return SUCCESS;
  }

  task void sendDoneTask() {
    signal Send.sendDone(msgHolder, SUCCESS);
    outBufBusy = FALSE;
  }

  task void sendMsgDoneTask() {
    signal SendMsg.sendDone(msgHolder, SUCCESS);
    outBufBusy = FALSE;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *pData) {

    AddressMsg* addressMsgOut = (AddressMsg*) &outBuf[0];

    if (call GroupManager.isForwarder(addressMsgOut->dest)) {
      dbg(DBG_USR1, "DripSendM: Forwarding a message for group %d\n", 
	  addressMsgOut->dest);

      call Leds.greenToggle();
      
      memcpy(pData, &outBuf[0], outLength);

      forwardedMsgs++;

      call Drip.rebroadcast(msg, pData, outLength);
      return SUCCESS;
      
    } else {
      return FAIL;
    }
  }

  event TOS_MsgPtr DripReceive.receive(TOS_MsgPtr msg, void* payload, 
				       uint16_t payloadLen) {

    AddressMsg* addressMsgIn = (AddressMsg*) payload;
    TOS_MsgPtr pMsg = msg;
    
//    dbg(DBG_USR1, "DripSendM: Storing a message for group %d\n", addressMsgIn->dest);
    memcpy(&outBuf[0], payload, payloadLen);
    outLength = payloadLen;

    if (call GroupManager.isMember(addressMsgIn->dest)) {
      dbg(DBG_USR1, "DripSendM: Receiving a message dest=%d source=%d\n", 
	  addressMsgIn->dest, addressMsgIn->source);

      call Leds.yellowToggle();

      receivedMsgs++;
    
      pMsg = signal Receive.receive(msg, &addressMsgIn->data[0], 
				    payloadLen - offsetof(AddressMsg, data));
    } else {
//      dbg(DBG_USR1, "DripSendM: NOT receiving a message for group %d\n", addressMsgIn->dest);
    }

    return pMsg;
  }
}


