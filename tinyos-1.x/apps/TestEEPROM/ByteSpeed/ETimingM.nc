// $Id: ETimingM.nc,v 1.2 2003/10/07 21:45:16 idgay Exp $

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
module ETimingM {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
    interface BareSendMsg;
    interface ReceiveMsg;

    interface AllocationReq;
    interface LogData;
    interface ReadData;

    interface Leds;
  }
}
implementation {
  uint32_t time;
  TOS_Msg msg;

  enum {
    BUFSIZE = 256
  };

  uint32_t offset;

  command result_t StdControl.init() {
    call AllocationReq.request(128L * 1024);
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Clock.setRate(TOS_I100PS, TOS_S100PS);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t AllocationReq.requestProcessed(result_t success) {
    if (success)
      call Leds.greenOn();
    return SUCCESS;
  }

  event result_t BareSendMsg.sendDone(TOS_MsgPtr m, result_t success) {
    return SUCCESS;
  }

  void sendTime(uint8_t status) {
    atomic
      {
	memcpy(msg.data, &time, sizeof time);
	time = 0;
      }
    msg.data[sizeof time] = status;
    msg.length = sizeof time + 1;
    msg.addr = TOS_UART_ADDR;
    call BareSendMsg.send(&msg);
  }

  async event result_t Clock.fire() {
    atomic time++;
    return SUCCESS;
  }

  void check(result_t success) {
    if (!success)
      call Leds.yellowOn();
  }

  struct orders {
    uint8_t unit;
    uint32_t size;
  } o;
  uint16_t ounit;

  uint8_t buffer[BUFSIZE];

  void continueLog();
  void continueRead();
  void readDone();

  task void bm() {
    uint16_t i;

    call Leds.redOff();
    call Leds.yellowOff();

    for (i = 0; i < ounit; i++)
      buffer[i] = 42 + i;

    atomic time = 0;

    call LogData.erase();
  }

  event result_t LogData.eraseDone(result_t success) {
    if (!success)
      check(success);
    else
      {
	sendTime(0x41);
	offset = 0;
	continueLog();
      }
    return SUCCESS;
  }

  void continueLog() {
    for (;;)
      {
	result_t logged;

	if (offset + ounit > o.size)
	  {
	    check(call LogData.sync());
	    return;
	  }

	logged = call LogData.append(buffer, ounit);
	if (logged == FAIL)
	  {
	    check(FAIL);
	    return;
	  }
	offset += ounit;
	if (logged == SUCCESS)
	  return;
	call Leds.greenOff();
      }
  }

  event result_t LogData.appendDone(uint8_t* data, uint32_t numBytes, result_t success) {
    if (!success)
      check(success);
    else
      continueLog();
    return SUCCESS;
  }

  event result_t LogData.syncDone(result_t success) {
    if (!success)
      check(success);
    else
      {
	sendTime(0x42);
	offset = 0;
	continueRead();
      }
    return SUCCESS;
  }

  void continueRead() {
    if (offset + ounit > o.size)
      readDone();
    else
      {
	check(call ReadData.read(offset, buffer, ounit));
	offset += ounit;
      }
  }

  event result_t ReadData.readDone(uint8_t* data, uint32_t numBytes, result_t success) {
    if (!success)
      check(success);
    else
      continueRead();
    return SUCCESS;
  }

  void readDone() {
    sendTime(0x43);
    call Leds.redOn();
  }
    

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    o = *(struct orders *)m->data;
    ounit = o.unit ? (int)o.unit : BUFSIZE;
    post bm();
    return m;
  }
}
