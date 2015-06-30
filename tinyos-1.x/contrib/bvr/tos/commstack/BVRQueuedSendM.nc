// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRQueuedSendM.nc,v 1.2 2005/06/22 02:33:40 rfonseca76 Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Authors: Phil Buonadonna, David Culler, Matt Welsh
 * Authors: Rodrigo Fonseca (some changes for BVR)
 * 
 * $Revision: 1.2 $
 *
 * This MODULE implements queued send with optional retransmit.  
 * NOTE: This module only queues POINTERS to the application messages.
 * IT DOES NOT COPY THE MESSAGE DATA ITSELF! Applications must maintain 
 * their own data queues if more than one outstanding message is required.
 * 
 */

/* This is an altered version of QueuedSendM.nc, not to be used normally.
 * It assumes that all unicast packets sent are from CBRouter, and 
 * logs them as such. This is a cross-layer interaction for the sole purpose
 * of performing a test of the link-level retransmission.
 * It is QueuedSend that knows about retransmissions, and what we are doing here
 * is just a way of associating the packets with a particular multihop message,
 * so that we can make the analysis easier.
 * Rodrigo, 05/08/04
 */
 
/**
 * @author Phil Buonadonna
 * @author David Culler
 * @author Matt Welsh
 */


/* To use this without dependencies and interactions with BVR application
 * code, define NO_BVR_INTROSPECT */

includes AM;
#ifndef NO_BVR_INTROSPECT
includes BVR;
includes Logging;
#endif


#ifndef SEND_QUEUE_SIZE
#define SEND_QUEUE_SIZE	32
//#define SEND_QUEUE_SIZE	18
#endif

#ifndef MAX_QUEUE_RETRANSMITS
#define MAX_QUEUE_RETRANSMITS 5
#endif

module BVRQueuedSendM {
  provides {
    interface StdControl;
    interface SendMsg as QueueSendMsg[uint8_t id];
    interface QueueControl;
    interface QueueCommand;
  }

  uses {
    interface SendMsg as SerialSendMsg[uint8_t id];
    interface Leds;
#ifndef NO_BVR_INTROSPECT
    interface Logger;
#endif
    //event void sendFail(uint16_t destaddr);
    //event void sendSucceed(uint16_t destaddr);
  }
}

implementation {

  enum {
    MESSAGE_QUEUE_SIZE = SEND_QUEUE_SIZE,
    MAX_RETRANSMIT_COUNT = MAX_QUEUE_RETRANSMITS,
  };

  uint8_t max_retransmit_count;

  struct _msgq_entry {
    uint16_t address;
    uint8_t length;
    uint8_t id;
    uint8_t xmit_count;
    TOS_MsgPtr pMsg;
  } msgqueue[MESSAGE_QUEUE_SIZE];

  uint16_t enqueue_next, dequeue_next;
  bool retransmit;
  bool fQueueIdle;

  command result_t StdControl.init() {
    int i;
    max_retransmit_count = MAX_RETRANSMIT_COUNT;
    for (i = 0; i < MESSAGE_QUEUE_SIZE; i++) {
      msgqueue[i].length = 0;
    }
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
    retransmit = TRUE;  // Set to TRUE to enable retransmission
#else
    retransmit = TRUE;  // Set to FALSE to disable retransmission
#endif
    enqueue_next = 0;
    dequeue_next = 0;
    fQueueIdle = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t QueueCommand.setRetransmitCount(uint8_t r) {
    max_retransmit_count = r;
    return SUCCESS;
  }

  command uint8_t QueueCommand.getRetransmitCount() {
    return max_retransmit_count;
  }

  /* Queue data structure
     Circular Buffer
     enqueue_next indexes first empty entry
     buffer full if incrementing enqueue_next would wrap to dequeue
     empty if dequeue_next == enqueue_next
     or msgqueue[dequeue_next].length == 0
  */

  task void QueueServiceTask() {
    uint8_t id;
    // Try to send next message (ignore xmit_count)
    if (msgqueue[dequeue_next].length != 0) {
      call Leds.greenToggle();
      dbg(DBG_USR2, "QueuedSend: sending msg (0x%x)\n", dequeue_next);
      id = msgqueue[dequeue_next].id;
      //XXX: help to the mac layer: setting the ack bit to 0, just in case
      msgqueue[dequeue_next].pMsg->ack = 0;

      if (!(call SerialSendMsg.send[id](msgqueue[dequeue_next].address, 
					msgqueue[dequeue_next].length, 
					msgqueue[dequeue_next].pMsg))) {
#if 0 
defined(PLATFORM_PC)
        if (msgqueue[dequeue_next].address == TOS_UART_ADDR) {
          //dequeue message
	  signal QueueSendMsg.sendDone[id](msgqueue[dequeue_next].pMsg,SUCCESS);
          msgqueue[dequeue_next].length = 0;
          dbg(DBG_USR2, "qent %d dequeued (UART message).\n",dequeue_next);
          dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
        }
#endif
	dbg(DBG_USR2, "QueuedSend: send request failed. stuck in queue\n");
      }
    }
    else {
      fQueueIdle = TRUE;
    }
  }

  command result_t QueueSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    dbg(DBG_USR2, "QueuedSend: queue msg enq %d deq %d\n", enqueue_next, dequeue_next);

#if defined(PLATFORM_PC)
    //don't enqueue UART messages
    if (address == TOS_UART_ADDR) {
      return call SerialSendMsg.send[id](address,length,msg); 
    }
#endif

    if (((enqueue_next + 1) % MESSAGE_QUEUE_SIZE) == dequeue_next) {
      // Fail if queue is full
      return FAIL;
    }
    msgqueue[enqueue_next].address = address;
    msgqueue[enqueue_next].length = length;
    msgqueue[enqueue_next].id = id;
    msgqueue[enqueue_next].pMsg = msg;
    msgqueue[enqueue_next].xmit_count = 0;
    msgqueue[enqueue_next].pMsg->ack = 0;

    enqueue_next++; enqueue_next %= MESSAGE_QUEUE_SIZE;

    dbg(DBG_USR2, "QueuedSend: Successfully queued msg to 0x%x, enq %d, deq %d\n", address, enqueue_next, dequeue_next);
#if 0
    {
      uint16_t i;
      for (i = dequeue_next; i != enqueue_next; i = (i + 1) % MESSAGE_QUEUE_SIZE)
	dbg(DBG_USR2, "qent %d: addr 0x%x, len %d, amid %d, xmit_cnt %d\n", 
	    i, msgqueue[i].address, msgqueue[i].length, msgqueue[i].id, msgqueue[i].xmit_count);
    }
#endif    
    if (fQueueIdle) {
      fQueueIdle = FALSE;
      if (post QueueServiceTask() == FAIL)
        dbg(DBG_ERROR,"QueueSendM: post QueueServiceTask returned error!!\n");
    }
    dbg(DBG_USR2, "QueuedSend: X fQueueIdle: %d\n",fQueueIdle);
    return SUCCESS;

  }

  /* Warning: this is the place that interacts with BVR code, but is not
   * essential for the functionality of the module. The purpose of this is
   * to log retransmissions in a way that is easy to correlate with the
   * application messages. A layering violation for the progress (or
   * debugging) of science... */
  event result_t SerialSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {

#ifndef NO_BVR_INTROSPECT
    BVRAppMsg* pBVRMsg;
    uint16_t app_msg_id;
    pBVRMsg = (BVRAppMsg*)msg->data;
    app_msg_id = *(uint16_t*)(&pBVRMsg->type_data.data);
#endif

    dbg(DBG_USR2,"QueueSendM$SerialSendMsg$sendDone: result:%d ack:%d to_UART:%d is_BCAST:%d\n",success,msg->ack,
            (msgqueue[dequeue_next].address == TOS_UART_ADDR),
            (msgqueue[dequeue_next].address == TOS_BCAST_ADDR));

    if (msg != msgqueue[dequeue_next].pMsg) {
      dbg(DBG_USR2,"QueuedSendM$SerialSendMsg$sendDone: Internal Error: buffer mismatch!\n");
      return FAIL;		// This would be internal error
    }

#ifndef NO_BVR_INTROSPECT
    //Logging of retransmissions
    if (id == AM_BVR_APP_MSG && 
        (retransmit) && 
        (msg->ack != 0) && 
        (msgqueue[dequeue_next].address != TOS_UART_ADDR) && 
        (msgqueue[dequeue_next].address != TOS_BCAST_ADDR)) {
      /* Rodrigo: logging for retransmission test */
      call Logger.LogRetransmitReport(LOG_ROUTE_RETRANSMIT_SUCCESS,app_msg_id,pBVRMsg->type_data.origin,
        pBVRMsg->type_data.dest_id,pBVRMsg->type_data.hopcount-1,msgqueue[dequeue_next].address,msgqueue[dequeue_next].xmit_count);
    }
#endif
     
    // filter out non-queuesend msgs
    if ((!retransmit) || (msg->ack != 0) || (msgqueue[dequeue_next].address == TOS_UART_ADDR) || msgqueue[dequeue_next].address == TOS_BCAST_ADDR) {
      //signal sendSucceed(msgqueue[dequeue_next].address);
      signal QueueSendMsg.sendDone[id](msg,success);
      msgqueue[dequeue_next].length = 0;
      dbg(DBG_USR2, "qent %d dequeued.\n", dequeue_next);
      dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
#if 0
      {
	uint16_t i;
	for (i = dequeue_next; i != enqueue_next; i = (i + 1) % MESSAGE_QUEUE_SIZE)
	  dbg(DBG_USR2, "qent %d: addr 0x%x, len %d, amid %d, xmit_cnt %d\n", 
	      i, msgqueue[i].address, msgqueue[i].length, msgqueue[i].id, msgqueue[i].xmit_count);
      }
#endif
    }
    else {
      //will retransmit if not max
      call Leds.redToggle();
      if ((++(msgqueue[dequeue_next].xmit_count) > max_retransmit_count)) {
        // Tried to send too many times, just drop
        //signal sendFail(msgqueue[dequeue_next].address);
#ifndef NO_BVR_INTROSPECT
        call Logger.LogRetransmitReport(LOG_ROUTE_RETRANSMIT_FAIL,app_msg_id,pBVRMsg->type_data.origin,
          pBVRMsg->type_data.dest_id,pBVRMsg->type_data.hopcount-1,msgqueue[dequeue_next].address,msgqueue[dequeue_next].xmit_count);
#endif
        signal QueueSendMsg.sendDone[id](msg,FAIL);
        msgqueue[dequeue_next].length = 0;
        dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
      }
    }
    
    // Send next
      if (post QueueServiceTask() == FAIL)
        dbg(DBG_ERROR,"QueueSendM: post QueueServiceTask returned error!!\n");

    return SUCCESS;
  }
  
  command uint16_t QueueControl.getOccupancy() {
    uint16_t uiOutstanding = enqueue_next - dequeue_next;
    uiOutstanding %= MESSAGE_QUEUE_SIZE;

    return uiOutstanding;
  }
  
  command uint8_t QueueControl.getXmitCount() {
    if (msgqueue[dequeue_next].length != 0)
      return msgqueue[dequeue_next].xmit_count;
    return 0;
  }
  
  default event result_t QueueSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  default command result_t SerialSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg)
    {
      return SUCCESS;
    }
}

