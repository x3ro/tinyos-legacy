// $Id: Field.nc,v 1.3 2004/12/31 20:08:22 yarvis Exp $

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
includes Field;
module Field
{
  provides {
    interface StdControl;
  }

  uses {
    interface ReceiveMsg as WakeupMsg;
    interface ReceiveMsg as FieldMsg;
    interface ReceiveMsg as SpyReplyMsg;
    interface SendMsg as FieldReplyMsg;
    interface Timer as SleepTimer;
    interface Timer as MsgTimer;
    //interface Debug;
    interface Leds;
    interface CommandUse;
    interface Random;

    interface StdControl as SchedulerClt;
    interface ServiceScheduler;
    interface StdControl as WakeTinyDB;
  }
}
implementation
{
  bool awake, busy, sleepPending, commandPending;
  uint16_t lastCmdId, lastCmdSender, destination;
  uint8_t timeout;
  TOS_Msg reply;

  enum {
    FIELD_TIMEOUT = 20,
    MAX_REPLIES = 5
  };

  void sendReply(uint16_t to, uint16_t cmdId);

  command result_t StdControl.init() {
    awake = busy = commandPending = FALSE;
    call Random.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    timeout = 0;
    call SleepTimer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void sleep() {
    call Leds.yellowOff();
    awake = FALSE;

    // Restart regular time-based scheduling
    //call ServiceScheduler.automaticOperation();
    call WakeTinyDB.stop();
  }

  void wakeup() {
    if (!awake)
      {
	awake = TRUE;
	call Leds.yellowOn();
	//call ServiceScheduler.manualOperation();
	call WakeTinyDB.start();
      }
  }

  void startTimeout() {
    // Cancel any pending sleep request
    sleepPending = FALSE;
    timeout = FIELD_TIMEOUT;
  }

  task void gotoSleep() {
    if (sleepPending)
      sleep();
  }

  event result_t SleepTimer.fired() {
    if (timeout > 0)
      {
	timeout--;
	if (timeout == 0)
	  {
	    sleepPending = TRUE;
	    if (!post gotoSleep())
	      timeout = FIELD_TIMEOUT >> 3;
	  }
      }
    return SUCCESS;
  }

  event TOS_MsgPtr WakeupMsg.receive(TOS_MsgPtr msg) {
    if (!busy)
      {
	struct WakeupMsg *m = (struct WakeupMsg *)msg->data;

	/* We ignore wakeups in the first 1/4 of our timeout
	   period to reduce radio congestion (and give other motes
	   a chance to answer too) */
	if (!awake || timeout < 3 * FIELD_TIMEOUT / 4)
	  {
	    startTimeout();

	    busy = TRUE;
	    wakeup();
	    sendReply(m->sender, WAKEUP_CMDID);
	  }
      }
    return msg;
  }

  bool duplicate(struct FieldMsg *m) {
    if (m->cmdId == lastCmdId)
      return TRUE;
    lastCmdId = m->cmdId;
    lastCmdSender = m->sender;
    return FALSE;
  }

  void sendCmdReply() {
    commandPending = FALSE;
    sendReply(lastCmdSender, lastCmdId);
  }

  event TOS_MsgPtr FieldMsg.receive(TOS_MsgPtr msg) {
    struct FieldMsg *m = (struct FieldMsg *)msg->data;

    // AM may be in promiscuous mode...
    if ((msg->addr == TOS_BCAST_ADDR || msg->addr == TOS_LOCAL_ADDRESS) &&
	awake && !busy && !duplicate(m))
      {
	struct FieldReplyMsg *rep = (struct FieldReplyMsg *)reply.data;

	busy = TRUE;
	startTimeout();

	commandPending = TRUE;
	if (call CommandUse.invokeBuffer(m->cmd, rep->result, &rep->errorNo) == FAIL) 
	  rep->errorNo = SCHEMA_ERROR;
	if (rep->errorNo != SCHEMA_RESULT_PENDING)
	  sendCmdReply();
      }
    return msg;
  }

  /* We spy on field reply messages and don't send our reply if more 
     than MAX_REPLIES are heard before reaching our time to send. This
     avoids congesting the radio with field messages */
  uint8_t spiedReplies;

  void sendReply(uint16_t to, uint16_t cmdId) {
    struct FieldReplyMsg *m = (struct FieldReplyMsg *)reply.data;
    uint16_t delay;

    m->sender = TOS_LOCAL_ADDRESS;
    m->cmdId = cmdId;
    destination = to;
    spiedReplies = 0;
    delay = 128 + ((call Random.rand() & 63) << 3);
    call MsgTimer.start(TIMER_ONE_SHOT, delay);
  }

  event TOS_MsgPtr SpyReplyMsg.receive(TOS_MsgPtr spied) {
    spiedReplies++;
    return spied;
  }

  event result_t MsgTimer.fired() {
    if (spiedReplies >= MAX_REPLIES ||
	!call FieldReplyMsg.send(destination,
				 sizeof(struct FieldReplyMsg) + 12, &reply))
      busy = FALSE;
    return SUCCESS;
  }

  event result_t FieldReplyMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    busy = FALSE;
    return SUCCESS;
  }

  event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo errorNo) {
    if (commandPending)
      {
	struct FieldReplyMsg *rep = (struct FieldReplyMsg *)reply.data;

	rep->errorNo = errorNo;
	sendCmdReply();
      }
    return SUCCESS;
  }
}
