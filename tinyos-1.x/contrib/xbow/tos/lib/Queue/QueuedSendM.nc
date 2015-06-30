// $Id: QueuedSendM.nc,v 1.2 2005/02/15 01:34:28 jdprabhu Exp $

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
 * 
 * $Revision: 1.2 $
 *
 * This MODULE implements queued send with optional retransmit.  
 * NOTE: This module only queues POINTERS to the application messages.
 * IT DOES NOT COPY THE MESSAGE DATA ITSELF! Applications must maintain 
 * their own data queues if more than one outstanding message is required.
 * 
 */

/**
 * @author Phil Buonadonna
 * @author David Culler
 * @author Matt Welsh
 */


includes AM;

#ifndef SEND_QUEUE_SIZE
#define SEND_QUEUE_SIZE 32
#endif

module QueuedSendM {
  provides {
    interface StdControl;
    interface SendMsg as QueueSendMsg[uint8_t id];
    interface QueueControl;
  }

  uses {
    interface SendMsg as SerialSendMsg[uint8_t id];
    interface Leds;
    //event void sendFail(uint16_t destaddr);
    //event void sendSucceed(uint16_t destaddr);
  }
}

implementation {

  enum {
    MESSAGE_QUEUE_SIZE = SEND_QUEUE_SIZE,
    MAX_RETRANSMIT_COUNT = 5
  };

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
    for (i = 0; i < MESSAGE_QUEUE_SIZE; i++) {
      msgqueue[i].length = 0;
      msgqueue[i].pMsg = NULL;
    }

    retransmit = FALSE;  // Set to TRUE to enable retransmission

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
    if (msgqueue[dequeue_next].pMsg != NULL) {
      call Leds.greenToggle();
      dbg(DBG_USR2, "QueuedSend: sending msg (0x%x)\n", dequeue_next);
      id = msgqueue[dequeue_next].id;

      if (!(call SerialSendMsg.send[id](msgqueue[dequeue_next].address, 
					msgqueue[dequeue_next].length, 
					msgqueue[dequeue_next].pMsg))) {
#ifndef PLATFORM_PC
	post QueueServiceTask();
#endif
	dbg(DBG_USR2, "QueuedSend: send request failed. stuck in queue\n");
      }
    }
    else {
      fQueueIdle = TRUE;
    }
  }

  command result_t QueueSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    uint8_t ret_val = SUCCESS;
    dbg(DBG_USR2, "QueuedSend: queue msg enq %d deq %d\n", enqueue_next, dequeue_next);

    if (length > TOSH_DATA_LENGTH) {
      dbg(DBG_USR2, "QueuedSend: message too long to send!\n");
      return FAIL;
    }

    if (msg == NULL) {
      dbg(DBG_USR2, "QueuedSend: No storage allocated!\n");
      return FAIL;
    }

    atomic{
	
    if (((enqueue_next + 1) % MESSAGE_QUEUE_SIZE) == dequeue_next) {
      dbg(DBG_USR2, "QueuedSend: queue is full!\n");
      ret_val  = FAIL;
    }else{
    	msgqueue[enqueue_next].address = address;
    	msgqueue[enqueue_next].length = length;
    	msgqueue[enqueue_next].id = id;
    	msgqueue[enqueue_next].pMsg = msg;
    	msgqueue[enqueue_next].xmit_count = 0;
    	msgqueue[enqueue_next].pMsg->ack = 0;

    	enqueue_next++; enqueue_next %= MESSAGE_QUEUE_SIZE;

    	if (fQueueIdle) {
      		fQueueIdle = FALSE;
      		post QueueServiceTask();
    	}
        dbg(DBG_USR2, "QueuedSend: Successfully queued msg to 0x%x, enq %d, deq %d\n", address, enqueue_next, dequeue_next);
    }

    }
    return ret_val;

  }

	

  event result_t SerialSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    if (msg != msgqueue[dequeue_next].pMsg) {
      return FAIL;		// This would be internal error
    }
    // filter out non-queuesend msgs
    
    if ((!retransmit) || (msg->ack != 0) || (msgqueue[dequeue_next].address == TOS_UART_ADDR)) {
      //signal sendSucceed(msgqueue[dequeue_next].address);
      signal QueueSendMsg.sendDone[id](msg,success);
      msgqueue[dequeue_next].pMsg = NULL; 
      dbg(DBG_USR2, "qent %d dequeued.\n", dequeue_next);
      dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
    }
    else {
      call Leds.redToggle();
      if ((++(msgqueue[dequeue_next].xmit_count) > MAX_RETRANSMIT_COUNT)) {
	// Tried to send too many times, just drop
	//signal sendFail(msgqueue[dequeue_next].address);
	signal QueueSendMsg.sendDone[id](msg,FAIL);
	msgqueue[dequeue_next].pMsg = NULL; 
	dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
      } 
    }
    
    // Send next
    post QueueServiceTask();

    return SUCCESS;
  }
  
  command uint16_t QueueControl.getOccupancy() {
    uint16_t uiOutstanding = enqueue_next - dequeue_next;
    uiOutstanding %= MESSAGE_QUEUE_SIZE;

    return uiOutstanding;
  }
  
  command uint8_t QueueControl.getXmitCount() {
    if (msgqueue[dequeue_next].pMsg != NULL)
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

