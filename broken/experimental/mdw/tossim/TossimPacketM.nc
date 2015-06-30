/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2003 Intel Corporation 
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

/**
 * This is a drop-in replacement for TOSSIM's radio stack that operates at
 * the packet, rather than the bit, level. In preliminary testing it
 * performs about 100 times faster than the default bit-level radio stack.
 * Obviously it does not capture the subtleties and behavior of the
 * bit-level simulation, but, it is useful for testing and simulating large
 * networks. 
 *
 * To use this code, all you need to do is add the line
 *   PFLAGS = -I/path/to/tinyos/broken/experimental/mdw/tossim
 * to your application Makefile, then rebuild your application with 'make pc'.
 *
 * This packet-level simulation is compatible with TOSSIM's lossy radio
 * models, so if you are using "-r lossy" or setting link-level loss
 * probabilities with TinyViz, it will work.
 * 
 * Matt Welsh - mdw@eecs.harvard.edu
 */

module TossimPacketM { 
  provides interface StdControl as Control;
  provides interface BareSendMsg as Send;
  provides interface ReceiveMsg as Receive;
}
implementation {

  typedef struct {
    TOS_MsgPtr msg;
    int srcaddr;
  } tossim_msg_event;

  typedef struct {
    TOS_MsgPtr msg;
  } tossim_senddone_event;

  command result_t Control.init() {
    dbg(DBG_AM, "TossimPacketM: Control.init() called\n");
    return SUCCESS;
  }

  command result_t Control.start() {
    dbg(DBG_AM, "TossimPacketM: Control.start() called\n");
    return SUCCESS;
  }
  command result_t Control.stop() {
    dbg(DBG_AM, "TossimPacketM: Control.stop() called\n");
    return SUCCESS;
  }

  bool should_deliver(int sender, int receiver) {
    link_t *curlink;
    curlink = radio_connectivity[sender];
    while (curlink != NULL) {
      if (curlink->mote == receiver) {
	//dbg(DBG_AM, "TossimPacketM: Bit loss rate is %f\n", curlink->data);
	if (curlink->data == 0.0) {
	  return TRUE;
	} else if (curlink->data == 1.0) {
	  return FALSE;
	} else {
	  double rval = (rand()*1.0) / (RAND_MAX*1.0);
	  double prob = pow(1.0 - curlink->data, MSG_DATA_SIZE*8);
	  if (rval <= prob) {
	    return TRUE;
	  } else {
	    //dbg(DBG_AM, "TossimPacketM: Packet is corrupted\n");
	    return FALSE;
	  }
	}
      }
      curlink = curlink->next_link;
    }
    return FALSE; // Never found the link
  }

  void event_tossim_msg_handle(event_t *fevent, struct TOS_state *fstate) __attribute__ ((C, spontaneous)) {
    tossim_msg_event *msgev = (tossim_msg_event *)fevent->data;
    dbg(DBG_AM, "TossimPacketM: Handling event_tossim_msg at mote %d\n", NODE_NUM);
    signal Receive.receive(msgev->msg);
  }

  void event_tossim_msg_cleanup(event_t *fevent) {
    tossim_msg_event *msgev = (tossim_msg_event *)fevent->data;
    free(msgev->msg);
    event_total_cleanup(fevent);
  }

  void event_tossim_msg_create(event_t *fevent, TOS_MsgPtr msg, int dest) {
    tossim_msg_event *msgev = (tossim_msg_event *)malloc(sizeof(tossim_msg_event));
    msgev->msg = (TOS_MsgPtr)malloc(sizeof(TOS_Msg));
    memcpy(msgev->msg, msg, sizeof(TOS_Msg));
    // Required to pass CRC checks by latest AMStandard
    msgev->msg->crc = 1;
    msgev->srcaddr = NODE_NUM;
    fevent->mote = dest;
    fevent->data = msgev;
    fevent->time = tos_state.tos_time + 1;
    fevent->handle = event_tossim_msg_handle;
    fevent->cleanup = event_tossim_msg_cleanup;
    fevent->pause = 0;
    dbg(DBG_AM, "TossimPacketM: Created msg event for msg dst %d\n", msg->addr);
  }

  void event_tossim_senddone_handle(event_t *fevent, struct TOS_state *fstate) __attribute__ ((C, spontaneous)) {
    RadioMsgSentEvent sendev;
    tossim_senddone_event *sdev = (tossim_senddone_event *)fevent->data;
    dbg(DBG_AM, "TossimPacketM: Handling event_tossim_senddone at mote %d\n", NODE_NUM);
    memcpy(&sendev.message, sdev->msg, sizeof(sendev.message));
    sendTossimEvent(NODE_NUM, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &sendev);
    signal Send.sendDone(sdev->msg, SUCCESS);
  }

  void event_tossim_senddone_create(event_t *fevent, TOS_MsgPtr msg, int mote) {
    tossim_senddone_event *sdev = (tossim_senddone_event *)malloc(sizeof(tossim_senddone_event));
    sdev->msg = msg;
    fevent->mote = mote;
    fevent->data = sdev;
    fevent->time = tos_state.tos_time + 2;
    fevent->handle = event_tossim_senddone_handle;
    fevent->cleanup = event_total_cleanup;
    fevent->pause = 0;
    dbg(DBG_AM, "TossimPacketM: Created senddone event for mote %d\n", mote);
  }

  command result_t Send.send(TOS_MsgPtr msg) {
    event_t *ev;
    dbg(DBG_AM,"TossimPacketM: Send.send() called\n");

    msg->ack = 0;
    if (msg->addr != TOS_BCAST_ADDR) {
      if (should_deliver(NODE_NUM, msg->addr)) {
	ev = (event_t*)malloc(sizeof(event_t));
	event_tossim_msg_create(ev, msg, msg->addr);
	TOS_queue_insert_event(ev);
	msg->ack = 1;
      }
    } else {
      int i;
      for (i = 0; i < tos_state.num_nodes; i++) {
	if (should_deliver(NODE_NUM, i)) {
	  ev = (event_t*)malloc(sizeof(event_t));
	  event_tossim_msg_create(ev, msg, i);
	  TOS_queue_insert_event(ev);
	}
      }
      msg->ack = 1;
    }
    ev = (event_t*)malloc(sizeof(event_t));
    event_tossim_senddone_create(ev, msg, NODE_NUM);
    TOS_queue_insert_event(ev);

    return SUCCESS;
  }

}

