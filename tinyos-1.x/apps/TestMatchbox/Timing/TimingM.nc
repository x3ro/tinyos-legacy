// $Id: TimingM.nc,v 1.3 2004/04/26 20:59:02 idgay Exp $

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
module TimingM {
  provides {
    interface StdControl;
    event result_t matchboxReady();
  }
  uses {
    interface Clock;
    interface BareSendMsg;
    interface ReceiveMsg;
    interface FileRead;
    interface FileWrite;
  }
}
implementation {
  uint32_t time;
  TOS_Msg msg;

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
    memcpy(msg.data, &time, sizeof time);
    msg.data[sizeof time] = status;
    msg.length = 5;
    msg.addr = TOS_UART_ADDR;
    call BareSendMsg.send(&msg);
  }

  async event result_t Clock.fire() {
    atomic time++;
    return SUCCESS;
  }

  event result_t matchboxReady() {
    sendTime(0);
    return SUCCESS;
  }

  struct orders {
    uint8_t cmd;
    uint32_t size;
  } o;

  uint8_t buffer[256];

  void readAgain() {
    call FileRead.read(buffer, o.size);
  }

  event result_t FileRead.readDone(void *buf, filesize_t nRead,
				   fileresult_t result) {
    if (result != FS_OK || nRead < o.size)
      {
	call FileRead.close();
	sendTime(result);
      }
    else
      readAgain();
    return SUCCESS;
  }

  event result_t FileRead.opened(fileresult_t result) {
    if (o.size > sizeof buffer)
      o.size = sizeof buffer;
    readAgain();
    return SUCCESS;
  }

  task void bm() {
    atomic time = 0;
    switch (o.cmd)
      {
      case 0: case 2:
	call FileWrite.open("foo", FS_FTRUNCATE | FS_FCREATE); break;
      case 1: call FileRead.open("foo"); break;
      }
  }

  void writeAgain(fileresult_t result) {
    if (result == FS_OK)
      if (o.size == 0)
	call FileWrite.close();
      else
	{
	  filesize_t size = o.size > sizeof buffer ? sizeof buffer : o.size;
	  o.size -= size;
	  call FileWrite.append(buffer, size);
	}
    else
      sendTime(result);
  }

  event result_t FileWrite.opened(filesize_t fileSize, fileresult_t result) {
    if (o.cmd == 2)
      call FileWrite.reserve(o.size);
    else
      writeAgain(result);
    return SUCCESS;
  }

  event result_t FileWrite.reserved(filesize_t fileSize, fileresult_t result) {
    sendTime(22);
    writeAgain(result);
    return SUCCESS;
  }

  event result_t FileWrite.closed(fileresult_t result) {
    sendTime(result);
    return SUCCESS;
  }

  event result_t FileWrite.appended(void *buf, filesize_t nWritten,
				    fileresult_t result) {
    writeAgain(result);
    return SUCCESS;
  }

  event result_t FileWrite.synced(fileresult_t result) {
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    o = *(struct orders *)m->data;
    post bm();
    return m;
  }

  event result_t FileRead.remaining(filesize_t n, fileresult_t result) {
    return SUCCESS;
  }
}
