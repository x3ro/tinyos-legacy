//$Id: DrainM.nc,v 1.1.1.1 2007/11/05 19:09:10 jpolastre Exp $

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

module DrainM {
  provides {
    interface StdControl;

    interface SendMsg[uint8_t id];
    interface Send[uint8_t id];

    interface Receive[uint8_t id];

    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
  }
  uses {
    interface StdControl as SubControl;
      
    interface Leds;

    interface ReceiveMsg as LinkReceiveMsg;
    interface SendMsg as LinkSendMsg;

    interface DrainLinkEst;
    interface DrainGroup;

    interface Timer;

    interface Timer as PostFailTimer;

#if defined(_CC2420CONST_H) || defined(_CC1KCONST_H)
    interface MacControl;
#endif
  }
}

implementation {

  /** 
   * Drain includes its own queueing, for both sent and forwarded messages. 
   */
  TOS_MsgPtr sendQueue[DRAIN_SEND_QUEUE_SIZE];
  uint8_t sendQueueIn, sendQueueOut, sendQueueCount;

  TOS_Msg fwdBuffers[DRAIN_FWD_QUEUE_SIZE];
  uint8_t fwdQueueIn, fwdQueueOut, fwdQueueCount;

  uint8_t queueChoice;

  bool queuesBusy;
  bool radioBusy;

  bool baseAcks = TRUE;

  uint8_t backoff;

  /** 
   * Drain keeps track of some statistics -- if you're tight on RAM,
   * you can take these out.
   */

  uint16_t sendPackets;
  uint16_t sendDrops;

  uint16_t forwardPackets;
  uint16_t forwardDrops;

  uint16_t linkSendPackets;
  uint16_t linkAckedPackets;
  uint16_t linkBackoffExpires;

  task void QueueServiceTask();

  void initializeBufs();

  bool tooBig(TOS_MsgPtr pMsg, uint8_t payloadLen);
  bool cantSend(TOS_MsgPtr pMsg, uint8_t payloadLen);
  result_t enqueueSend(TOS_MsgPtr pMsg);
  TOS_MsgPtr enqueueForward(TOS_MsgPtr pMsg);

  void inc(uint16_t *val);
  void clear(uint16_t *val);
  task void errorBlink();

  task void enableAck();

  void postService();
  void postServiceCheck();

  command result_t StdControl.init() {
    initializeBufs();
    backoff = 0;
    return call SubControl.init();
  }
  
  void initializeBufs() {
/*
    int n;

    for (n=0; n < DRAIN_FWD_QUEUE_SIZE; n++) {
      fwdQueue[n] = &fwdBuffers[n];
    }
*/

    fwdQueueIn = fwdQueueOut = fwdQueueCount = 0;
    sendQueueIn = sendQueueOut = fwdQueueCount = 0;

    queuesBusy = FALSE;
  }

  command result_t StdControl.start() {
#if defined(_CC2420CONST_H) || defined(_CC1KCONST_H)
#define DRAIN_ACKS_AVAILABLE
    call MacControl.enableAck();
#endif
    return call SubControl.start();
  }
 
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void* Send.getBuffer[uint8_t id](TOS_MsgPtr pMsg, uint16_t* length) {
    
    DrainMsg *pMHMsg = (DrainMsg *)pMsg->data;
    
    *length = TOSH_DATA_LENGTH - offsetof(DrainMsg,data);

#if DRAIN_DEBUG_DETAILED
    dbg(DBG_ROUTE, "Drain: getBuffer(pMsg=0x%x,id=%d,len=%d)\n",
	pMsg, id, *length);
#endif

    return (&pMHMsg->data[0]);
  }

  command result_t Send.send[uint8_t id](TOS_MsgPtr pMsg, uint16_t payloadLen) {
    // Please send with a destination address, or TOS_DEFAULT_ADDR
    // if you don't care. 
    // This may be temporary...

    return FAIL;
  } 
  
  command result_t SendMsg.send[uint8_t id](uint16_t dest, uint8_t length, 
					    TOS_MsgPtr pMsg) {

    dbg(DBG_ROUTE, "Drain: netSend(pMsg=0x%x,dest=%d,id=%d,len=%d)\n",
	pMsg, dest, id, length);
    
    if (tooBig(pMsg, length) || cantSend(pMsg, length)) {
      return FAIL;
    }
    
    call DrainLinkEst.initializeFields(pMsg, id, dest, length);

    return enqueueSend(pMsg);
  }

  bool tooBig(TOS_MsgPtr pMsg, uint8_t payloadLen) {
    uint16_t usMHLength = offsetof(DrainMsg,data) + payloadLen;
    
    if (usMHLength > TOSH_DATA_LENGTH) {
      return TRUE;
    }
    return FALSE;
  }

  bool cantSend(TOS_MsgPtr pMsg, uint8_t payloadLen) {

    if (sendQueueCount >= DRAIN_SEND_QUEUE_SIZE) {
      sendDrops++;
      dbg(DBG_ROUTE, "Drain: sendQueueFull(pMsg=0x%x,len=%d)\n",
	  pMsg, payloadLen);
      return TRUE;
    }
    
    return FALSE;
  }

  result_t enqueueSend(TOS_MsgPtr pMsg) {

    postServiceCheck();

#if DRAIN_DEBUG_DETAILED
    dbg(DBG_ROUTE, "Drain: sendEnterQueue(pMsg=0x%x)\n",
	pMsg);
#endif

    sendQueue[sendQueueIn] = pMsg;
    sendQueueCount++;
    if (++sendQueueIn >= DRAIN_SEND_QUEUE_SIZE) 
      sendQueueIn = 0;
    return SUCCESS;
  }

  void postServiceCheck() {
    if (!queuesBusy) { // && !radioBusy) {
      postService();
      queuesBusy = TRUE;
    }
  }

  void postService() {
    if (post QueueServiceTask() == FAIL) {
      call PostFailTimer.start(TIMER_ONE_SHOT, 10);
    }
  }

  event result_t PostFailTimer.fired() {
    postService();
    return SUCCESS;
  }

  event TOS_MsgPtr LinkReceiveMsg.receive(TOS_MsgPtr pMsg) {
    
    DrainMsg *drainMsg = (DrainMsg *)pMsg->data;
    uint16_t payloadLen = pMsg->length - offsetof(DrainMsg,data);
    uint8_t id = drainMsg->type;
    
    dbg(DBG_ROUTE, "Drain: linkReceive(pMsg=0x%x,src=0x%02x,dst=0x%02x)\n", 
        pMsg, drainMsg->source, drainMsg->dest);

#ifdef DRAIN_ENDPOINT_ONLY
    return pMsg;
#endif

    // See if it's for this node.
    if (pMsg->addr != TOS_LOCAL_ADDRESS) { 
      signal Snoop.intercept[id](pMsg, &drainMsg->data[0], payloadLen);
      return pMsg;
    }

    // Give Intercept a chance
    if ((signal Intercept.intercept[id](pMsg, &drainMsg->data[0], 
					payloadLen)) == FAIL) {
      // It's not OK to forward.
      return pMsg;
    }

    // Pass it up if necessary.
    if (drainMsg->dest == TOS_LOCAL_ADDRESS ||
	call DrainLinkEst.isRoot()) {

      dbg(DBG_ROUTE, "Drain: netReceive(pMsg=0x%x,src=0x%02x,dst=0x%02x)\n", 
	  pMsg, drainMsg->source, drainMsg->dest);

      pMsg = signal Receive.receive[id](pMsg, &drainMsg->data[0], payloadLen);

    } else { 

      if (call DrainLinkEst.forwardFields(pMsg)) {
	
	// Enqueue it for forwarding if necessary.
	if (fwdQueueCount < DRAIN_FWD_QUEUE_SIZE) {
	  dbg(DBG_ROUTE, "Drain: netForward(pMsg=0x%x,src=0x%02x,dst=0x%02x)\n", 
	      pMsg, drainMsg->source, drainMsg->dest);
	  pMsg = enqueueForward(pMsg);
	} else {
	  dbg(DBG_ROUTE, "Drain: forwardQueueFull(pMsg=0x%x)\n", pMsg);
	  forwardDrops++;
	}
      }
    }

    return pMsg;
  }

  TOS_MsgPtr enqueueForward(TOS_MsgPtr pMsg) {

    TOS_MsgPtr pNewBuf = pMsg;

    postServiceCheck();

#if DRAIN_DEBUG_DETAILED
    dbg(DBG_ROUTE, "Drain: forwardEnterQueue(pMsg=0x%x)\n", pMsg);
#endif

    memcpy(&fwdBuffers[fwdQueueIn], pMsg, sizeof(TOS_Msg));
    fwdQueueCount++;
    if (++fwdQueueIn >= DRAIN_FWD_QUEUE_SIZE) 
      fwdQueueIn = 0;
    
    return pNewBuf;
  }

  task void QueueServiceTask() {

    TOS_MsgPtr pMsg;

#if DRAIN_DEBUG_DETAILED
    dbg(DBG_ROUTE, "Drain: queueServiceTask\n");
#endif

    // First check send queue. 
    if (sendQueueCount > 0) {

#if DRAIN_DEBUG_DETAILED
      dbg(DBG_ROUTE, "Drain: queueServiceTask(servicing=sendQueue)\n");
#endif

      // We've got a message in the send queue.
      pMsg = sendQueue[sendQueueOut];
      if (queueChoice != DRAIN_QUEUE_SEND) {
	backoff = 0;
      }
      queueChoice = DRAIN_QUEUE_SEND;

    } else if (fwdQueueCount > 0) {

#if DRAIN_DEBUG_DETAILED
      dbg(DBG_ROUTE, "Drain: queueServiceTask(servicing=forwardQueue)\n");
#endif

      // We've got a message in the forward queue.
      pMsg = &fwdBuffers[fwdQueueOut];
      if (queueChoice != DRAIN_QUEUE_FWD) {
	backoff = 0;
      }
      queueChoice = DRAIN_QUEUE_FWD;

    } else {

      queuesBusy = FALSE;

#if DRAIN_DEBUG_DETAILED
      dbg(DBG_ROUTE, "Drain: queueServiceTask(queuesAllEmpty)\n");
#endif

      return;
    }
    
    call DrainLinkEst.selectRoute(pMsg);

    dbg(DBG_ROUTE, "Drain: linkSend(pMsg=0x%x,linkDest=%d,len=%d)\n",
	pMsg, pMsg->addr, pMsg->length);
    
    if (pMsg->length == 1) {
//      call Leds.greenOn();
      dbg(DBG_USR1, "DrainM: LENGTH == 1!!!\n");
    }

    if (call LinkSendMsg.send(pMsg->addr, pMsg->length, pMsg) == SUCCESS) {
#if DRAIN_DEBUG_DETAILED
      dbg(DBG_ROUTE, "Drain: LinkSendMsg succeeded\n");
#endif
      // Wait for the sendDone.
      radioBusy = TRUE;
    } else {
      // The radio didn't accept our message.
#if DRAIN_DEBUG_DETAILED
      dbg(DBG_ROUTE, "Drain: LinkSendMsg failed\n");
#endif
      call Timer.start(TIMER_ONE_SHOT, 10);
    }      
  }

  event result_t Timer.fired() {
    postService();
    return SUCCESS;
  }

  event result_t LinkSendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {

    result_t forwardResultVal = SUCCESS;
    DrainMsg* mhMsg = (DrainMsg*) pMsg->data;

#if DRAIN_DEBUG_DETAILED
    dbg(DBG_ROUTE, "Drain: sendDone(pMsg=0x%x,success=%d)\n", 
	pMsg, success);  
#endif

    radioBusy = FALSE;

    if (queueChoice == DRAIN_QUEUE_SEND &&
	pMsg != sendQueue[sendQueueOut]) {
      //     call Leds.greenOn();
      postService();
      return SUCCESS;
    }

    if (queueChoice == DRAIN_QUEUE_FWD &&
	pMsg != &fwdBuffers[fwdQueueOut]) {
      postService();
      return SUCCESS;
    }

    if (!success) {
      postService();
      return SUCCESS;
    }

    linkSendPackets++;

#ifdef DRAIN_ACKS_AVAILABLE
    if (pMsg->ack == 1) {
      linkAckedPackets++;
    }
#endif

    if (pMsg->addr == TOS_BCAST_ADDR || pMsg->addr == TOS_UART_ADDR) {

      // It didn't have a destination.

    } else if (mhMsg->dest == pMsg->addr && !baseAcks) {
      
      // It's for the destination. This might be a TOSBase that
      // doesn't know how to ACK packets.

    } else {

      // It did have a destination. Consider retransmitting.

#ifdef DRAIN_ACKS_AVAILABLE
      if (pMsg->ack == 0) {
	
	// It wasn't acked. Try again, up to DRAIN_MAX_BACKOFF
	call DrainLinkEst.messageSent(pMsg, FAIL);

	if (backoff < DRAIN_MAX_BACKOFF) {
	  backoff++;
	  call Timer.start(TIMER_ONE_SHOT, 1 << backoff);
	  return SUCCESS;
	} else {
	  // We seem to have hit max backoff.
	  linkBackoffExpires++;
	  forwardResultVal = FAIL;
	}
      } 
      else 
#endif
      {
	// It was acked.
	call DrainLinkEst.messageSent(pMsg, SUCCESS);
      }
    }

    backoff = 0;
    
    dbg(DBG_ROUTE, "Drain: sendComplete(pMsg=0x%x,result=%d)\n", 
	pMsg, forwardResultVal);
    
    if (queueChoice == DRAIN_QUEUE_SEND) {

      pMsg = sendQueue[sendQueueOut];

      if (forwardResultVal == SUCCESS) {
	sendPackets++;
      }

      signal SendMsg.sendDone[mhMsg->type](pMsg, forwardResultVal);

      sendQueueCount--;
      sendQueue[sendQueueOut] = 0;
      if (++sendQueueOut >= DRAIN_SEND_QUEUE_SIZE)
	sendQueueOut = 0;

    } else if (queueChoice == DRAIN_QUEUE_FWD) {

      pMsg = &fwdBuffers[fwdQueueOut];

      if (forwardResultVal == SUCCESS) {
	forwardPackets++;
      }

      fwdQueueCount--;
      if (++fwdQueueOut >= DRAIN_FWD_QUEUE_SIZE)
	fwdQueueOut = 0;

    } else {

      dbg(DBG_ROUTE, "Drain: ERROR! RECEIVED SEND DONE FOR MESSAGE NOT IN QUEUE (pMsg=0x%x)\n", pMsg);
    }

    postService();
      
    return SUCCESS;
  }

  default event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, 
						   result_t success) {
    return SUCCESS;
  }

  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr pMsg, 
						      result_t success) {
    return SUCCESS;
  }

  default event result_t Intercept.intercept[uint8_t id](TOS_MsgPtr pMsg, 
							 void* payload, 
							 uint16_t payloadLen) {
    return SUCCESS;
  }

  default event result_t Snoop.intercept[uint8_t id](TOS_MsgPtr pMsg, 
						     void* payload, 
                                                     uint16_t payloadLen) {
    return SUCCESS;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr pMsg, 
						       void* payload, 
						       uint16_t payloadLen) {
    return pMsg;
  }
}

