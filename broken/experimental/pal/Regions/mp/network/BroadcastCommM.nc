/*
 * Copyright (c) 2003
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


module BroadcastCommM
{
  provides { 
    interface StdControl;
    interface SendMsg;
    interface ReceiveMsg;
  } 
  uses {
    interface SendMsg as RealSendMsg;
    interface ReceiveMsg as RealReceiveMsg;
  }

} implementation {

  uint16_t cur_seqno;
  TOS_Msg resend_packet;
  bool realsend_busy;

  static void initialize() {
    cur_seqno = 0;
    realsend_busy = FALSE;
  }

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t SendMsg.send(uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    uint16_t seqno;
    dbg(DBG_USR2,"BroadcastCommM: send: addr %d len %d\n", address, length);

    if (realsend_busy) return FAIL;
    if (address != TOS_BCAST_ADDR) return FAIL;
    // Need 2 bytes at end for seqno
    if (length > TOSH_DATA_LENGTH-2) return FAIL;

    seqno = ++cur_seqno;

    msg->data[length] = (seqno & 0xff00) >> 8;
    msg->data[length+1] = (seqno & 0xff);

    dbg(DBG_USR2,"BroadcastCommM: trying to send: length %d\n", length+2);
    realsend_busy = TRUE;
    if (!call RealSendMsg.send(address, length+2, msg)) {
      realsend_busy = FALSE;
      return FAIL;
    } else {
      return SUCCESS;
    }
  }

  default event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event result_t RealSendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    dbg(DBG_USR2,"BroadcastCommM: RealSendMsg.sendDone\n");
    realsend_busy = FALSE;
    return signal SendMsg.sendDone(msg, success);
  }

  default event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    return msg;
  }

  event TOS_MsgPtr RealReceiveMsg.receive(TOS_MsgPtr msg) {
    uint16_t seqno = (msg->data[msg->length-1] | (msg->data[msg->length-2] << 8));
    dbg(DBG_USR2,"BroadcastCommM: RealReceiveMsg.receive len %d seqno %d cur_seqno %d\n", msg->length, seqno, cur_seqno);

    // Drop if we have seen this sequence number already
    if (cur_seqno >= seqno) return msg;
    cur_seqno = seqno;

    if (realsend_busy) {
      signal ReceiveMsg.receive(msg);
      return msg;
    }

    // Rebroadcast
    realsend_busy = TRUE;
    if (!call RealSendMsg.send(TOS_BCAST_ADDR, msg->length, msg)) {
      realsend_busy = FALSE;
      signal ReceiveMsg.receive(msg);
      return msg;
    } else {
      signal ReceiveMsg.receive(msg);
      return &resend_packet;
    }
  }

}
