// $Id: HFSRead.nc,v 1.3 2003/10/07 21:44:50 idgay Exp $

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
/**
 * Report sampling results over UART.
 * Because the mote may have been reset since the sampling, the read
 * request contains the number of samples to send (a real application
 * would presumably not require that the mote be connected to the UART
 * for data download).
 * This module does not even try to provide reliable communication
 */
module HFSRead {
  uses {
    interface SendMsg;
    interface ReceiveMsg;
    interface ReadData;
  }
}
implementation {
  uint32_t offset, remain;
  TOS_Msg msg;

  enum {
    BYTES_PER_MSG = sizeof msg.data - 1
  };

  void fail() {
    msg.data[0] = DATAMSG_FAIL;
    call SendMsg.send(TOS_UART_ADDR, 1, &msg);
  }

  task void sendData() {
    uint8_t n;

    if (remain < BYTES_PER_MSG)
      {
	n = remain;
	msg.data[0] = DATAMSG_LAST;
      }
    else
      {
	n = BYTES_PER_MSG;
	msg.data[0] = DATAMSG_MORE;
      }

    if (!call ReadData.read(offset, msg.data + 1, n))
      fail();
  }

  event result_t ReadData.readDone(uint8_t *buffer, uint32_t bytes, result_t ok) {
    uint8_t n = remain < BYTES_PER_MSG ? remain : BYTES_PER_MSG;

    if (ok && call SendMsg.send(TOS_UART_ADDR, n + 1, &msg))
      {
	offset += n;
	remain -= n;
      }
    else
      fail();

    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr m, result_t ok) {
    if (ok)
      {
	if (remain)
	  post sendData();
      }
    else
      fail();

    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    struct ReadRequestMsg *orders = (struct ReadRequestMsg *)m->data;
    offset = 0;
    remain = orders->count * sizeof(sample_t);
    post sendData();
    return m;
  }
}
