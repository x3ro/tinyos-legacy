/* "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */

/*
 * Authors: Phil Buonadonna, David Culler, Matt Welsh
 * 
 * $Revision: 1.1 $
 *
 * This MODULE implements queued send with optional retransmit.  
 * NOTE: This module only queues POINTERS to the application messages.
 * IT DOES NOT COPY THE MESSAGE DATA ITSELF! Applications must maintain 
 * their own data queues if more than one outstanding message is required.
 * 
 */

includes AM;

#ifndef SEND_QUEUE_SIZE
#define SEND_QUEUE_SIZE	32
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
  bool posted;

  command result_t StdControl.init() {
    int i;
    for (i = 0; i < MESSAGE_QUEUE_SIZE; i++) {
      msgqueue[i].length = 0;
    }


    retransmit = FALSE;  // Set to TRUE to enable retransmission

    enqueue_next = 0;
    dequeue_next = 0;
    posted = FALSE;

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
    posted = FALSE;
    // Try to send next message (ignore xmit_count)
    if (msgqueue[dequeue_next].length != 0) {
      call Leds.greenToggle();
      dbg(DBG_USR1, "QueuedSend: sending msg (0x%x)\n", dequeue_next);
      id = msgqueue[dequeue_next].id;
      if (!(call SerialSendMsg.send[id](msgqueue[dequeue_next].address, 
				      msgqueue[dequeue_next].length, 
				      msgqueue[dequeue_next].pMsg))) {
	dbg(DBG_USR1, "QueuedSend: send request failed. stuck in queue\n");
	posted = post QueueServiceTask();
      }
    }
  }

  command result_t QueueSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    dbg(DBG_USR1, "QueuedSend: queue msg enq %d deq %d\n", enqueue_next, dequeue_next);

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

    // Andrew fixup -- The code did not accept for the possibility
    //  that the task posting might fail.  As such, we would return
    //  SUCCESS regardless of the result.  Now, the upside was that
    //  if a subsequent send request managed to post, then that
    //  would jumpstart our sending, which would eventually get
    //  this message sent.  However, this is not desirable because
    //  we have no guarantee that someone would ever try and send
    //  another message if this message was not sent.  Furthermore,
    //  that behavior would also permit the pathological case where
    //  we completely fill up our send buffer (task queueing failing
    //  every time).  That is clearly not desirable.  As such,
    //  we return success/failure based on the most accurate data
    //  we have at the time.

    // ACS hack for post guard
    if(posted || (posted = post QueueServiceTask())) {
      enqueue_next++; enqueue_next %= MESSAGE_QUEUE_SIZE;
    } else {
      // make sure to not inadvertently screw up the invariant
      msgqueue[enqueue_next].length = 0;
      return FAIL;
    }

    /*
    dbg(DBG_USR1, "QueuedSend: Successfully queued msg to 0x%x, enq %d, deq %d\n", address, enqueue_next, dequeue_next);
    {
      uint16_t i;
      for (i = dequeue_next; i != enqueue_next; i = (i + 1) % MESSAGE_QUEUE_SIZE)
	dbg(DBG_USR1, "qent %d: addr 0x%x, len %d, amid %d, xmit_cnt %d\n", i, msgqueue[i].address, msgqueue[i].length, msgqueue[i].id, msgqueue[i].xmit_count);
    }
    */

    return SUCCESS;

  }

  event result_t SerialSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    if (msg != msgqueue[dequeue_next].pMsg) {
      return FAIL;		// This would be internal error
    }
    // filter out non-queuesend msgs
    
    if ((msg->ack != 0) || (msgqueue[dequeue_next].address == TOS_UART_ADDR)) {
      //signal sendSucceed(msgqueue[dequeue_next].address);
      signal QueueSendMsg.sendDone[id](msg,SUCCESS);
      msgqueue[dequeue_next].length = 0;
	dbg(DBG_USR1, "qent %d dequeued.\n", dequeue_next);
      dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
      {
	uint16_t i;
	for (i = dequeue_next; i != enqueue_next; i = (i + 1) % MESSAGE_QUEUE_SIZE)
	  dbg(DBG_USR1, "qent %d: addr 0x%x, len %d, amid %d, xmit_cnt %d\n", i, msgqueue[i].address, msgqueue[i].length, msgqueue[i].id, msgqueue[i].xmit_count);
      }
    }
    else {
      call Leds.redToggle();
      if ((!retransmit) ||
	  (++(msgqueue[dequeue_next].xmit_count) > MAX_RETRANSMIT_COUNT)) {
	// Tried to send too many times, just drop
	//signal sendFail(msgqueue[dequeue_next].address);
	signal QueueSendMsg.sendDone[id](msg,FAIL);
	msgqueue[dequeue_next].length = 0;
	dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
      } 
    }
    
    // Send next
    if(!posted) // ACS hack for post guard
      posted = post QueueServiceTask();

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
