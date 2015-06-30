  // $Id: TinyDBLoggerM.nc,v 1.8 2004/07/27 21:57:57 idgay Exp $

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
includes TinyDBLogger;
module TinyDBLoggerM
{
  provides interface StdControl;
  provides command result_t queryResultHook(uint8_t bufferId, QueryResultPtr r,
					    ParsedQuery *pq);
  uses {
    interface AllocationReq;
    interface LogData;
    interface ReadData;
    interface ReceiveMsg;
    interface SendMsg;
    interface Leds;
    interface Time;
    interface WDT;

    interface CommandRegister as ClearCmd;
    interface CommandRegister as OffsetCmd;
  }
}
implementation {
  enum {
    S_ALLOCATING,
    S_READY,
    S_APPENDING,
    S_SENDING,
    S_CLEARING
  };

  enum {
    SAMPLE_SIZE = sizeof ((QueryResult *)0)->d
  };

  typedef struct {
    uint8_t time[3]; // in seconds, little endian
    uint8_t tuple[SAMPLE_SIZE];
  } sample_t;

  uint8_t state;
  union {
    sample_t lastSample;
    struct {
      uint32_t offset, remain;
      TOS_Msg msg;
    } download;
    char *rbuf;
  } u;

  
  command result_t StdControl.init() {
    ParamList paramList;

    paramList.numParams = 0;
    call ClearCmd.registerCommand("LogClr", VOID, 0, &paramList);
    call OffsetCmd.registerCommand("LogOff", VOID, 0, &paramList);

    state = S_ALLOCATING;
    call AllocationReq.request(512 * 1024L); // get all of it!
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t AllocationReq.requestProcessed(result_t success) {
    // Allocation must succeed
    if (success)
      state = S_READY;
    return SUCCESS;
  }

  // Return time in seconds
  uint32_t now() {
    tos_time_t ms = call Time.get();

    return (ms.low32 >> 10) + (ms.high32 << 22); // binary ms in tos_time_t
  }

  // We spy on the results...
  command result_t queryResultHook(uint8_t bufferId, QueryResultPtr msg,
				   ParsedQuery *pq) {
    if (bufferId == kRADIO_BUFFER && msg->qrType == kNOT_AGG &&
	state == S_READY)
      {
	uint32_t t = now();

	memcpy(u.lastSample.tuple, &msg->d, sizeof msg->d);
	u.lastSample.time[0] = t;
	u.lastSample.time[1] = t >> 8;
	u.lastSample.time[2] = t >> 16;
	if (call LogData.append((uint8_t *)&u.lastSample, sizeof u.lastSample))
	  state = S_APPENDING;
      }
    return err_NoError;
  }

  event result_t LogData.appendDone(uint8_t* data, uint32_t n, result_t ok) {
    state = S_READY;
    return SUCCESS;
  }

  event result_t LogData.syncDone(result_t success) {
    return SUCCESS;
  }

  enum {
    BYTES_PER_MSG = sizeof u.download.msg.data - offsetof(struct LReadDataMsg, data)
  };

  void fail(uint8_t error) {
    struct LReadDataMsg *m = (struct LReadDataMsg *)u.download.msg.data;

    m->status = DATAMSG_FAIL + error;
    m->offset = u.download.offset;
    state = S_READY;
    call SendMsg.send(TOS_UART_ADDR, sizeof(struct LReadDataMsg), &u.download.msg);
  }

  task void sendData() {
    uint8_t n;
    struct LReadDataMsg *m = (struct LReadDataMsg *)u.download.msg.data;

    call WDT.reset();
    if (u.download.remain < BYTES_PER_MSG)
      {
	n = u.download.remain;
	m->status = DATAMSG_LAST;
      }
    else
      {
	n = BYTES_PER_MSG;
	m->status = DATAMSG_MORE;
      }
    m->offset = u.download.offset;

    if (!call ReadData.read(u.download.offset, m->data, n))
      fail(0);
  }

  event result_t ReadData.readDone(uint8_t *buffer, uint32_t n, result_t ok) {
    if (ok && call SendMsg.send(TOS_UART_ADDR, sizeof(struct LReadDataMsg) + n, &u.download.msg))
      {
	u.download.offset += n;
	u.download.remain -= n;
      }
    else
      fail(1 + ok);

    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr m, result_t ok) {
    if (state == S_SENDING)
      {
	if (ok)
	  if (u.download.remain == 0)
	    state = S_READY;
	  else
	    post sendData();
	else
	  fail(3);
      }

    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    struct LReadRequestMsg *in = (struct LReadRequestMsg *)m->data;
    struct LReadDataMsg *out = (struct LReadDataMsg *)u.download.msg.data;

    if (state != S_READY)
      {
	uint8_t ostate = state;

	fail(4);
	state = ostate; // fail sets state to S_READY
	return m;
      }
    state = S_SENDING;
    if (in->count == 0)
      u.download.remain = call LogData.currentOffset();
    else
      u.download.remain = in->count;

    u.download.offset = in->start;
    if (in->start < u.download.remain)
      u.download.remain -= in->start;
    else
      u.download.remain = (uint32_t)-1;

    if (u.download.remain == (uint32_t)-1)
      {
	fail(5);
	return m;
      }

    out->status = DATAMSG_SIZE;
    out->offset = call LogData.currentOffset();
    if (!call SendMsg.send(TOS_UART_ADDR, sizeof(struct LReadDataMsg), &u.download.msg))
      fail(6);

    return m;
  }

  event result_t OffsetCmd.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params) {
    struct OffsetReplyMsg *r = (struct OffsetReplyMsg *)resultBuf;

    *errorNo = SCHEMA_RESULT_READY;
    r->count = call LogData.currentOffset();
    return SUCCESS;
  }

  event result_t ClearCmd.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params) {
    if (state != S_READY)
      return FAIL;
    if (!call LogData.erase())
      {
	*errorNo = SCHEMA_RESULT_READY;
	resultBuf[0] = 0;
      }
    else
      {
	state = S_CLEARING;
	*errorNo = SCHEMA_RESULT_PENDING;
	u.rbuf = resultBuf; // hack, but don't want to waste ram
      }
    return SUCCESS;
  }

  event result_t LogData.eraseDone(result_t success) {
    if (state == S_CLEARING)
      {
	state = S_READY;
	u.rbuf[0] = success;
	call ClearCmd.commandDone("LogClr", u.rbuf, SCHEMA_RESULT_READY);
      }
    return SUCCESS;
  }
}
