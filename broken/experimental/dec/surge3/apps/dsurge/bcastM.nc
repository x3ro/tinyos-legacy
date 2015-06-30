/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
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
 * Author: Matt Welsh, David Culler
 * Created: 24 Dec 2002
 * 
 */

includes AM;
includes Surge;
includes bcast;

/**
 * 
 **/
module bcastM {
  provides {
    interface StdControl;
    interface Bcast;
  }
  uses {
    interface Leds;
    interface ReceiveMsg;
    interface SendMsg;
  }
}

implementation {

  uint8_t bcast_seqno;
  bool    send_busy;
  struct TOS_Msg bcast_packet;

  /***********************************************************************
   * Initialization 
   ***********************************************************************/

  static void initialize() {
    send_busy = FALSE;
    bcast_seqno = 255;
  }

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  static bool newBcast(uint8_t proposed) {
    return ((proposed > bcast_seqno) || ((proposed < 64) && (bcast_seqno > 196)));
  }

/* Each unique broadcast wave is signaled to application and
   rebroadcast once.
*/

  task void handle_broadcast() {
    bcastMsg *bcast_msg = (bcastMsg *)bcast_packet.data;
    dbg(DBG_USR2, "Bcast: handle broadcast 0x%x (seqno 0x%x)\n", bcast_msg->seqno, bcast_seqno);

    if ((!send_busy) && (newBcast(bcast_msg->seqno))) {
      bcast_seqno = bcast_msg->seqno;
      signal Bcast.cmd(bcast_msg);
      bcast_msg->sourceaddr = TOS_LOCAL_ADDRESS;
      send_busy = TRUE;
      if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(bcastMsg), &bcast_packet) != SUCCESS) {
	      send_busy = FALSE;
         }
      }
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    send_busy = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    bcastMsg *recv_msg = (bcastMsg *)recv_packet->data;
    bcastMsg *bcast_msg = (bcastMsg *)bcast_packet.data;
    call Leds.yellowToggle();

    dbg(DBG_USR2, "bcast: Message received, source 0x%02x, origin 0x%02x, type 0x%02x, seq 0x%02x\n", 
	recv_msg->sourceaddr, recv_msg->originaddr, recv_msg->type, recv_msg->seqno);
    if ((!send_busy) && (newBcast(recv_msg->seqno))) {
       memcpy(bcast_msg, recv_msg, sizeof(bcastMsg)); 
       post handle_broadcast();
    }
    return recv_packet;
  }

}



