//$Id: DripM.nc,v 1.1.1.1 2007/11/05 19:09:11 jpolastre Exp $

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

includes Drip;

/**
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

module DripM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Drip[uint8_t id];
  }
  uses {
    interface StdControl as SubControl;

    interface DripState[uint8_t id];
    interface DripStateMgr;

    interface ReceiveMsg;
    interface SendMsg;

    interface Timer as SendTimer;
    interface Random;
    interface Leds;
  }
}

implementation {

  TOS_Msg msgBuf;
  bool msgBufBusy;

  command result_t StdControl.init() {
    msgBufBusy = FALSE;
    return call SubControl.init();
  }
  
  command result_t StdControl.start() {
    call SendTimer.start(TIMER_ONE_SHOT, 
			 call Random.rand() % DRIP_TIMER_PERIOD);
    return call SubControl.start();
  }
  
  command result_t StdControl.stop() {
    call SendTimer.stop();
    return SUCCESS;
  }

  command result_t Drip.init[uint8_t id]() {
    call DripState.init[id](id);
    return SUCCESS;
  }

  command result_t Drip.change[uint8_t id]() {
    return call DripState.incrementSeqno[id]();    
  }
  
  command result_t Drip.setSeqno[uint8_t id](uint16_t seqno) {
    return call DripState.setSeqno[id](seqno);
  }

  event result_t SendTimer.fired() {

    TOS_MsgPtr pMsgBuf = &msgBuf;
    DripMsg *dripMsg = (DripMsg*) pMsgBuf->data;
    uint8_t readyKey;

    call DripStateMgr.updateCounters();

    readyKey = call DripStateMgr.findReadyEntry(); 

    if (readyKey != DRIP_INVALID_KEY) {

      if (!msgBufBusy) {

	msgBufBusy = TRUE;

	if (!signal Drip.rebroadcastRequest[readyKey](pMsgBuf, dripMsg->data)) {
	  msgBufBusy = FALSE;
	  call DripState.entrySent[readyKey]();
	} else {
	  dbg(DBG_USR1, "Sending id: %d\n", readyKey);
	}
      }
    }
    
    call SendTimer.start(TIMER_ONE_SHOT, DRIP_TIMER_PERIOD);
    
    return SUCCESS;
  }

  command result_t Drip.rebroadcast[uint8_t id](TOS_MsgPtr msg,
						void *pData,
						uint8_t len) {
    
    /* msg does not matter right now, because there's only one buf
       they might have been filling. It will matter if we 
       acquire the buf from a lower layer, or if we have a pool. */

    TOS_MsgPtr pMsgBuf = &msgBuf;
    DripMsg *dripMsg = (DripMsg*) pMsgBuf->data;
    result_t result;
    
    if (!msgBufBusy)
      return FAIL;

    call DripState.fillMetadata[id](&dripMsg->metadata);

    result = call SendMsg.send(TOS_BCAST_ADDR, 
			       offsetof(DripMsg,data) + len,
			       pMsgBuf);

    if (result == SUCCESS) {
      call DripState.entrySent[id]();
    } else {
      dbg(DBG_USR1, "DripM: radio busy\n");
      msgBufBusy = FALSE;
    }
    
    return result;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, 
				  result_t success) {

    if (msgBufBusy == TRUE) {
      msgBufBusy = FALSE;      
    }

    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) {
    
    TOS_MsgPtr retMsg = pMsg;
    DripMsg *dripMsg = (DripMsg*) pMsg->data;

    dbg(DBG_USR1, "Received msg(id=%d, seqno=%d)\n",
	dripMsg->metadata.id, dripMsg->metadata.seqno);

    if (call DripState.newMsg[dripMsg->metadata.id](dripMsg->metadata)) {

      dripMsg->metadata.seqno = 
	call DripState.getSeqno[dripMsg->metadata.id]();

      retMsg = signal Receive.receive[dripMsg->metadata.id]
	(pMsg, dripMsg->data, pMsg->length - offsetof(DripMsg,data));
    }
    
    return retMsg;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, 
						       void* payload, 
						       uint16_t payloadLen) {
    return msg;
  }

  default event result_t Drip.rebroadcastRequest[uint8_t id](TOS_MsgPtr msg, 
							     void *payload) {
    return FAIL;
  }
  
  default command result_t DripState.init[uint8_t localKey](uint8_t globalKey) {
    return FAIL;
  }

  default command uint16_t DripState.getSeqno[uint8_t localKey]() {
    return DRIP_SEQNO_OLDEST;
  }

  default command result_t DripState.incrementSeqno[uint8_t localKey]() {
    return FAIL;
  }

  default command result_t DripState.entrySent[uint8_t localKey]() {
    return FAIL;
  }

  default command bool DripState.newMsg[uint8_t localKey](DripMetadata incomingMetadata) {
    return FALSE;
  }

  default command result_t DripState.fillMetadata[uint8_t localKey](DripMetadata *metadata) {
    return FAIL;
  }

}









