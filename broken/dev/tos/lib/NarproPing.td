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
 * 
 */
/*
 * Authors:		Phil Levis
 *                      Nelson Lee (revised) 
 *
 */

/*
 *   FILE: NarproPing.td
 * AUTHOR: pal
 *  DESCR: Local ping protocol. - BETA
 *
 * NarproPing is a network call-response component. It resembles the ICMP ping
 * utility except that it works at Layer 2 instead of 3; no routing is
 * involved.
 *
 * When a mote receives a NarproPing message, it tries to immediately respond.
 * Sequence numbers are used to differentiate multiple NarproPing requests. The
 * application is reponsible for keeping track of sequence numbers; they're
 * only meaningful in a network whose traffic makes the time required for
 * two backoffs greater than the interval between NarproPing requests.
 *
 * Differences between NarproPing and PING is NarproPing does not contain a network stack.
 * It is assumed that the application using NarproPing will initialize and connect it
 * to a network stack like GENERIC_COMM
 */

/* Always use the ping_msg structure when messing with messages. */

includes NarproPingMsg;

module NarproPing {
  provides {
    interface StdControl;
    interface Ping;
  }
  uses {
    interface SendMsg;
    interface ReceiveMsg;    
  }
}

implementation {
  enum {
    NARPRO_PING_TYPE = 1
  };

  TOS_Msg buffer;	          // A packet buffer we hand around
  uint8_t sendPending;


  command result_t StdControl.init() {
    int i;
    uint8_t* ptr;

    dbg(DBG_BOOT, "PING initialized.\n");
  
    ptr = (uint8_t*)&buffer;
    for (i = 0; i < sizeof(TOS_Msg); i++) {
      ptr[i] = 0;
    }

    sendPending = 0;
    return SUCCESS;
  }

  command result_t Ping.send(uint16_t moteID, uint8_t sequence) {
    ping_msg* msg = (ping_msg*)&(buffer.data);

    if (sendPending) {
      return FAIL;
    }
    else {
      sendPending = 1;
    }
    
    msg->source_addr = TOS_LOCAL_ADDRESS;
    msg->dest_addr = moteID;
    msg->sequence = sequence;
    msg->response = 0;
    
    return call SendMsg.send(moteID, sizeof(ping_msg), &buffer);
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr data) {
    ping_msg* msg = (ping_msg*)(data->data);

    dbg(DBG_ROUTE, "PING: received  message from %i\n", (int)msg->source_addr);
    
    if (msg->dest_addr != TOS_LOCAL_ADDRESS &&
	msg->dest_addr != (uint16_t) 0xffff) {
      dbg(DBG_ROUTE, "PING: received  message from %i\n", (int)msg->source_addr);
      
    
      // Do nothing
    }
    else if (msg->response == 1) {
      signal Ping.pingResponse(msg->source_addr, msg->sequence);
    }
    else if (sendPending == 0) {
      ping_msg* replyMsg = (ping_msg*)&(buffer.data);
    
      replyMsg->dest_addr = msg->source_addr;
      replyMsg->source_addr = TOS_LOCAL_ADDRESS;
      replyMsg->response = 1;
      if (signal Ping.pingReceive(msg->source_addr, msg->sequence)) {
	sendPending = 1;
	call SendMsg.send(replyMsg->dest_addr, sizeof(ping_msg),
				  &buffer);
      }
    }
    
    return data;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr data, result_t success) {
    ping_msg* msg = (ping_msg*)(data->data);
    msg->response = -1;
    sendPending = 0;
    return success;
  }

}











