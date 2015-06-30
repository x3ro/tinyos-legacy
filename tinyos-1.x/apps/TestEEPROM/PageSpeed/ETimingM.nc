// $Id: ETimingM.nc,v 1.2 2003/10/07 21:45:17 idgay Exp $

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

    interface PageEEPROM;
  }
}
implementation {
  uint32_t time;
  TOS_Msg msg;

  eeprompage_t page;
  uint32_t count;

  enum { PAGE_SIZE = 256,
	 START_PAGE = 0 };

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Clock.setRate(TOS_I100PS, TOS_S100PS);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
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
    memcpy(msg.data + sizeof time + 1, &count, sizeof count);
    msg.length = sizeof time + 1 + sizeof count;
    msg.addr = TOS_UART_ADDR;
    call BareSendMsg.send(&msg);
  }

  async event result_t Clock.fire() {
    atomic time++;
    return SUCCESS;
  }

  struct orders {
    uint8_t cmd;
    uint32_t size;
  } o;

  uint8_t buffer[PAGE_SIZE];

#if 1
  bool realErasePhase;

  void continueWrite() {
    call PageEEPROM.erase(page, TOS_EEPROM_PREVIOUSLY_ERASED);
  }

  void falseErase() {
    eeprompageoffset_t n;

    if (count == 0)
      {
	sendTime(0x41);
	return;
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.write(page, 0, buffer, n);
  }

  event result_t PageEEPROM.writeDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else 
#if 1
      call PageEEPROM.flush(page++);
#else
    {
      page++;
      continueWrite();
    }
#endif
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else 
      continueWrite();
    return SUCCESS;
  }

  void startWrite() {
    realErasePhase = FALSE;
    page = START_PAGE;
    count = o.size;
    continueWrite();
  }

  void realErase() {
    eeprompageoffset_t n;

    if (count == 0)
      {
	sendTime(0x42);
	startWrite();
	return;
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.erase(page++, TOS_EEPROM_ERASE);
  }

  event result_t PageEEPROM.eraseDone(result_t result) {
    if (result == FAIL)
      {
	sendTime(0);
	return SUCCESS;
      }

    if (realErasePhase)
      realErase();
    else
      falseErase();
    return SUCCESS;
  }

  void directWrite() {
    realErasePhase = TRUE;
    page = START_PAGE;
    count = o.size;
    realErase();
  }
#else
  void continueWrite() {
    call PageEEPROM.erase(page, TOS_EEPROM_DONT_ERASE);
  }

  event result_t PageEEPROM.eraseDone(result_t result) {
    eeprompageoffset_t n;

    if (result == FAIL)
      {
	sendTime(0x43);
	return SUCCESS;
      }

    if (count == 0)
      {
	sendTime(0x44);
	return SUCCESS;
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.write(page, 0, buffer, n);
    return SUCCESS;
  }

  event result_t PageEEPROM.writeDone(result_t result) {
    if (result == FAIL)
      sendTime(0x45);
    else 
#if 1
      call PageEEPROM.flush(page++);
#else
    {
      page++;
      continueWrite();
    }
#endif
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    if (result == FAIL)
      sendTime(0x46);
    else 
      continueWrite();
    return SUCCESS;
  }

  void directWrite() {
    page = START_PAGE;
    count = o.size;
    continueWrite();
  }
#endif

  void continueRead() {
    eeprompageoffset_t n;

    if (count == 0)
      {
	sendTime(0x47);
	directWrite();
      }

    if (count > PAGE_SIZE)
      n = PAGE_SIZE;
    else
      n = count;

    count -= n;
    call PageEEPROM.read(page, 0, buffer, n);
    page++;
  }

  event result_t PageEEPROM.readDone(result_t result) {
    if (result == FAIL)
      sendTime(0);
    else
      continueRead();
    return SUCCESS;
  }

  void directRead() {
    page = START_PAGE;
    count = o.size;
    continueRead();
  }

  task void bm() {
    atomic time = 0;
    directRead();
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    o = *(struct orders *)m->data;
    post bm();
    return m;
  }

  event result_t PageEEPROM.syncDone(result_t result) {
    return SUCCESS;
  }
  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
    return SUCCESS;
  }
}
