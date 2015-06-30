// $Id: TossimPacketM.nc,v 1.7 2005/01/07 19:14:07 mdwelsh Exp $

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
 * Philip Levis - pal@cs.berkeley.edu
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

  bool should_deliver(int sender, int receiver, int len) {
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
	  double bitError = curlink->data; // Bit error rate
	  double recvProb = 0.0;
	  double startSymRecv = pow((1 - bitError), 9);
	  double byteRecv = pow((1 - bitError), 8) +
	    (8.0 * bitError * pow(1 - bitError, 12));
	  double dataRecv = pow(byteRecv, len); // does any byte fail
	  double rval = (rand()*1.0) / (RAND_MAX*1.0);
	  recvProb = startSymRecv * dataRecv;
	  if (rval <= recvProb) {
	    return TRUE;
	  } else {
	    dbg(DBG_AM, "TossimPacketM: Packet is corrupted\n");
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
    msgev->msg->crc = 1;
    //dbg(DBG_AM, "TossimPacketM: Handling event_tossim_msg at mote %d\n", NODE_NUM);
    signal Receive.receive(msgev->msg);
    event_cleanup(fevent);
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
    fevent->time = tos_state.tos_time + 100000; // Delay packet a bit
    fevent->handle = event_tossim_msg_handle;
    fevent->cleanup = event_tossim_msg_cleanup;
    fevent->pause = 0;
    //dbg(DBG_AM, "TossimPacketM: Created msg event for msg dst %d\n", msg->addr);
  }

  void event_tossim_senddone_handle(event_t *fevent, struct TOS_state *fstate) __attribute__ ((C, spontaneous)) {
    RadioMsgSentEvent sendev;
    tossim_senddone_event *sdev = (tossim_senddone_event *)fevent->data;
    dbg(DBG_AM, "TossimPacketM: Handling event_tossim_senddone at mote %d\n", NODE_NUM);
    memcpy(&sendev.message, sdev->msg, sizeof(sendev.message));
    sendTossimEvent(NODE_NUM, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &sendev);
    signal Send.sendDone(sdev->msg, SUCCESS);
    event_cleanup(fevent);
  }

  void event_tossim_senddone_create(event_t *fevent, TOS_MsgPtr msg, int mote) {
    tossim_senddone_event *sdev = (tossim_senddone_event *)malloc(sizeof(tossim_senddone_event));
    sdev->msg = msg;
    fevent->mote = mote;
    fevent->data = sdev;
    // A tiny bit shorter, so people who blast packets will see loss
    // (as they would on a real radio)
    fevent->time = tos_state.tos_time + 100002;     
    fevent->handle = event_tossim_senddone_handle;
    fevent->cleanup = event_total_cleanup;
    fevent->pause = 0;
    //dbg(DBG_AM, "TossimPacketM: Created senddone event for mote %d\n", mote);
  }

  command result_t Send.send(TOS_MsgPtr msg) {
    event_t *ev;
    dbg(DBG_AM,"TossimPacketM: Send.send() called\n");
    if (msg->addr != TOS_BCAST_ADDR) {
      if (should_deliver(NODE_NUM, msg->addr, msg->length + 7)) {
	ev = (event_t*)malloc(sizeof(event_t));
	event_tossim_msg_create(ev, msg, msg->addr);
	TOS_queue_insert_event(ev);
      }
    } else {
      int i;
      for (i = 0; i < tos_state.num_nodes; i++) {
	if (should_deliver(NODE_NUM, i, msg->length + 7)) {
	  ev = (event_t*)malloc(sizeof(event_t));
	  event_tossim_msg_create(ev, msg, i);
	  TOS_queue_insert_event(ev);
	}
      }
    }
    ev = (event_t*)malloc(sizeof(event_t));
    event_tossim_senddone_create(ev, msg, NODE_NUM);
    TOS_queue_insert_event(ev);
    msg->ack = 1;
    return SUCCESS;
  }

}

