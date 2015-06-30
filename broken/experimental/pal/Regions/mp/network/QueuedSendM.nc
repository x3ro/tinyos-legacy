/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

includes Tuning;
includes TuningKeys;

/**
 * This is a wrapper to the SendMsg interface that internally queues
 * messages for transmission, so that SendMsg.send() always succeeds
 * (unless another command is concurrently attempting an enqueue).
 */
module QueuedSendM {
  provides interface StdControl;
  provides interface SendMsg[uint8_t id];
  uses interface SendMsg as RealSendMsg[uint8_t id];
  uses interface Leds;
  uses interface Tuning;
  uses interface Timer;
  uses event void sendFail(uint16_t destaddr);
  uses event void sendSucceed(uint16_t destaddr);
}
implementation {

  enum {
    MESSAGE_QUEUE_SIZE = 32,
    DEFAULT_MAX_RETRANSMIT_COUNT = 5,
    DEFAULT_TIMER_RATE = 1000,
  };

  tuning_value_t max_retransmit_count, timer_rate;

  struct _msgq_entry {
    uint8_t id;
    uint16_t address;
    uint8_t length;
    uint8_t xmit_count;
    struct TOS_Msg msg;
  } msgqueue[MESSAGE_QUEUE_SIZE];

  bool enqueue_busy;
  int enqueue_next;
  int dequeue_next;
  bool retransmit;
  int pendingCount;

  // For enqueue task
  uint8_t tmp_id;
  uint16_t tmp_address;
  uint8_t tmp_length;
  TOS_MsgPtr tmp_msg;

  command result_t StdControl.init() {
    int i;
    for (i = 0; i < MESSAGE_QUEUE_SIZE; i++) {
      msgqueue[i].length = 0;
    }
    retransmit = TRUE;  // Set to FALSE to disable retransmission
    enqueue_busy = FALSE;
    enqueue_next = dequeue_next = 0;
    pendingCount = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (!call Tuning.getDefault(KEY_QUEUEDSEND_MAX_RETRANSMIT_COUNT,
	  &max_retransmit_count, DEFAULT_MAX_RETRANSMIT_COUNT)) {
      return FAIL;
    }
    if (max_retransmit_count == 0) retransmit = FALSE; else retransmit = TRUE;
    if (!call Tuning.getDefault(KEY_QUEUEDSEND_TIMER_RATE,
	  &timer_rate, DEFAULT_TIMER_RATE)) {
      return FAIL;
    }
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  result_t enqueue(uint8_t id, uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    if (enqueue_busy) return FAIL;
    enqueue_busy = TRUE;
    if (((enqueue_next + 1) % MESSAGE_QUEUE_SIZE) == dequeue_next) {
      // Fail if queue is full
      dbg(DBG_USR3, "QueuedSend: enqueue() queue full\n");
      signal SendMsg.sendDone[id](msg, FAIL);
      enqueue_busy = FALSE;
      return FAIL;
    }
    msgqueue[enqueue_next].id = id;
    msgqueue[enqueue_next].address = address;
    msgqueue[enqueue_next].length = length;
    msgqueue[enqueue_next].xmit_count = 0;
    // Copy message
    memcpy(&msgqueue[enqueue_next].msg, msg, sizeof(struct TOS_Msg));
    msgqueue[enqueue_next].msg.ack = 0;
    enqueue_next++; enqueue_next %= MESSAGE_QUEUE_SIZE;
    if (++pendingCount == 1) call Timer.start(TIMER_REPEAT, (int)timer_rate);

    // Try to send next message (ignore xmit_count)
    if (msgqueue[dequeue_next].length != 0) {
      dbg(DBG_USR3, "QueuedSend: enqueue() trying to send (id=%d, dqnext %d @ 0x%lx dst %d)\n", msgqueue[dequeue_next].id, dequeue_next, (unsigned long)&msgqueue[dequeue_next].msg, msgqueue[dequeue_next].address);
      call Leds.greenToggle();
      if (call RealSendMsg.send[msgqueue[dequeue_next].id](msgqueue[dequeue_next].address, msgqueue[dequeue_next].length, &msgqueue[dequeue_next].msg)) {
        if (--pendingCount == 0) call Timer.stop();
	dbg(DBG_USR3, "QueuedSend: enqueue() sent message, pendingCount %d\n", pendingCount);
      } else {
	dbg(DBG_USR3, "QueuedSend: enqueue() unable to send, pendingCount %d\n", pendingCount);
      }
    }
    dbg(DBG_USR3, "QueuedSend: enqueueTask() finished\n");
    // This just means that it was properly enqueued!
    signal SendMsg.sendDone[id](msg, SUCCESS);
    enqueue_busy = FALSE;
    return SUCCESS;
  }

  // XXX MDW: Arguably should always do the enqueue within a task, but
  // this precludes several enqueues in a row. For now we assume that
  // most enqueue is done in a task context already (would be nice to check)
  task void enqueueTask() { 
    enqueue(tmp_id, tmp_address, tmp_length, tmp_msg);
  }

  command result_t SendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    call Tuning.getDefault(KEY_QUEUEDSEND_MAX_RETRANSMIT_COUNT, 
	&max_retransmit_count, DEFAULT_MAX_RETRANSMIT_COUNT);
    if (max_retransmit_count == 0) retransmit = FALSE; else retransmit = TRUE;
    return enqueue(id, address, length, msg);
  }

  default event void sendFail(uint16_t destaddr) { }
  default event void sendSucceed(uint16_t destaddr) { }

  default command result_t RealSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    return FAIL;
  }
  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return FAIL;
  }

  event result_t RealSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    // Note - we might be signaled here for someone else's outgoing 
    // message. This is no big deal - just try to send ours now.
    bool forus = (msg == &msgqueue[dequeue_next].msg);

    dbg(DBG_USR3, "QueuedSend: RealSendMsg.sendDone(id=%d) called (msg @ 0x%lx, forus %d)\n", id, (unsigned long)msg, forus);

    // Don't try to retransmit broadcast messages - won't get an ack
    if (forus && retransmit && msg->ack == 0 && 
	!(msgqueue[dequeue_next].address == TOS_BCAST_ADDR)) {
      call Leds.redToggle();
      // Didn't get an ACK on the message transmit; need to retransmit
      dbg(DBG_USR3, "QueuedSend: sendDone: retransmitting (xmit_count %d, maxrt %d)\n", msgqueue[dequeue_next].xmit_count, max_retransmit_count);
      signal sendFail(msgqueue[dequeue_next].address);
      if (++(msgqueue[dequeue_next].xmit_count) > max_retransmit_count) {
	// Tried to send too many times, just drop
        dbg(DBG_USR3, "QueuedSend: too many retransmits - dropping\n");
	msgqueue[dequeue_next].length = 0;
	dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
      } 
    } else if (forus) {
      // Our message was sent ok - bump pointer
      dbg(DBG_USR3, "QueuedSend: sendDone: %s send\n", 
	  (msg->ack || msgqueue[dequeue_next].address == TOS_BCAST_ADDR)?"successful":"failed");
      if (retransmit && msg->ack == 1) call Leds.yellowToggle();
      signal sendSucceed(msgqueue[dequeue_next].address);
      msgqueue[dequeue_next].length = 0;
      dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
    }

    // Try to send next
    if (msgqueue[dequeue_next].length != 0) {
      dbg(DBG_USR3, "QueuedSend: sendDone(id=%d): trying to send next (0x%lx dst %d)\n", id, &msgqueue[dequeue_next].msg, msgqueue[dequeue_next].address);
      call Leds.greenToggle();

      if (call RealSendMsg.send[msgqueue[dequeue_next].id](msgqueue[dequeue_next].address, msgqueue[dequeue_next].length, &msgqueue[dequeue_next].msg)) {
	dbg(DBG_USR3, "QueuedSend: sendDone() sent message, pendingCount %d\n", pendingCount);
	if (--pendingCount == 0) call Timer.stop();
      } else {
	dbg(DBG_USR3, "QueuedSend: sendDone() unable to send, pendingCount %d\n", pendingCount);
      }
    }
    return SUCCESS;
  }

  event result_t Timer.fired() {
    dbg(DBG_USR3, "QueuedSend: Retransmit timer fired, pendingCount %d dequeue_next %d enqueue_next %d length %d\n", pendingCount, dequeue_next, enqueue_next, msgqueue[dequeue_next].length);
    if (pendingCount == 0) return SUCCESS;

    // Try to send next
    if (msgqueue[dequeue_next].length != 0) {
      if (++(msgqueue[dequeue_next].xmit_count) > max_retransmit_count) {
	// Tried to send too many times, just drop
        dbg(DBG_USR3, "QueuedSend: Timer.fired: too many transmit attempts - dropping\n");
	msgqueue[dequeue_next].length = 0;
	dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
	if (--pendingCount == 0) call Timer.stop();
	dbg(DBG_USR3, "QueuedSend: Timer.fired: pendingCount now %d\n", pendingCount);
      } else {
	dbg(DBG_USR3, "QueuedSend: Timer.fired: trying to send next (0x%lx dst %d)\n", &msgqueue[dequeue_next].msg, msgqueue[dequeue_next].address);
	call Leds.greenToggle();
	if (call RealSendMsg.send[msgqueue[dequeue_next].id](msgqueue[dequeue_next].address, msgqueue[dequeue_next].length, &msgqueue[dequeue_next].msg)) {
	  if (--pendingCount == 0) call Timer.stop();
	  dbg(DBG_USR3, "QueuedSend: Timer.fired: managed to send, pendingCount %d\n", pendingCount);
	} else {
	  dbg(DBG_USR3, "QueuedSend: Timer.fired: could not send, pendingCount %d\n", pendingCount);
	}
      }
    }
    return SUCCESS;
  }

}
