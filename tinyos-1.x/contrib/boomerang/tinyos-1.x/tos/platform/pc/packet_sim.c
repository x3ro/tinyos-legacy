// $Id: packet_sim.c,v 1.1.1.1 2007/11/05 19:10:34 jpolastre Exp $

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
 */

#include <packet_sim.h>

#define BIT_TIME 104
#define BYTE_TIME (8 * BIT_TIME)

int byteTransmitTime = BYTE_TIME * 2;
int initBackoffLow = 10 * BYTE_TIME;
int initBackoffHigh = 20 * BYTE_TIME;
int backoffLow = 10 * BYTE_TIME;
int backoffHigh = 20 * BYTE_TIME;
int txChangeLatency = 30 * BYTE_TIME;
int preambleLength = 20; // In bytes
int headerLength = 7;    // In bytes


struct IncomingMsg;

typedef struct IncomingMsg {
  TOS_Msg msg;
  struct IncomingMsg* next;
} IncomingMsg;

TOS_MsgPtr packet_transmitting[TOSNODES];
IncomingMsg* incoming[TOSNODES];
link_t* cc1000_connectivity[TOSNODES];

void initialBackoff();
void event_backoff_create(event_t* event, int node, long long eventTime);
void event_backoff_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));

void event_start_transmit_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));
void event_start_transmit_create(event_t* event, int node, long long eventTime);

void event_receive_packet_create(event_t* event, int node, long long eventTime, IncomingMsg* msg) __attribute__ ((C, spontaneous));
void event_receive_packet_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));

void event_send_packet_done_create(event_t* event, int node, long long eventTime) __attribute__ ((C, spontaneous));
void event_send_packet_done_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));

void packet_sim_init() {
  int i;
  for (i = 0; i < TOSNODES; i++) {
    packet_transmitting[i] = NULL;
    incoming[i] = NULL;
    cc1000_connectivity[i] = NULL;
  }
  cc1000_connectivity[0] = (link_t*)malloc(sizeof(link_t));
  cc1000_connectivity[0]->mote = 1;
  cc1000_connectivity[0]->next_link = NULL;
  cc1000_connectivity[2] = (link_t*)malloc(sizeof(link_t));
  cc1000_connectivity[2]->mote = 1;
  cc1000_connectivity[2]->next_link = NULL;
}

result_t packet_sim_transmit(TOS_MsgPtr msg) {
  if (packet_transmitting[NODE_NUM] != NULL) {
    return FAIL;
  }
  packet_transmitting[NODE_NUM] = msg;
  initialBackoff();
  return SUCCESS;
}

void initialBackoff() {
  event_t* event = (event_t*)malloc(sizeof(event_t));
  int backoffAmount = initBackoffLow;
  backoffAmount += rand() % (initBackoffHigh - initBackoffLow);
  event_backoff_create(event, NODE_NUM, tos_state.tos_time + backoffAmount);
  if (dbg_active(DBG_PACKET)) {
    char timeBuf[128];
    printTime(timeBuf, 128);
    dbg(DBG_PACKET, "SIM_PACKET: Initial backoff @%s is %i.\n", timeBuf, backoffAmount);
  }
  dbg(DBG_MEM, "SIM_PACKET: Allocated event 0x%x\n", (unsigned int)event);
  TOS_queue_insert_event(event);
}


void event_backoff_create(event_t* event, int node, long long eventTime) {
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->data = NULL;
  event->time = eventTime;
  event->handle = event_backoff_handle;
  event->cleanup = event_total_cleanup;
}


void event_backoff_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous))  {
  if (incoming[NODE_NUM] != NULL) {
    int backoffAmount = backoffLow;
    backoffAmount += rand() % (backoffHigh - backoffLow);
    event_backoff_create(event, NODE_NUM, tos_state.tos_time + backoffAmount);
    dbg(DBG_PACKET, "SIM_PACKET: Backoff more: %i.\n", backoffAmount);
    TOS_queue_insert_event(event);
  }
  else {
    event_start_transmit_create(event, NODE_NUM, tos_state.tos_time + txChangeLatency);
    TOS_queue_insert_event(event);
  }
}

void event_start_transmit_create(event_t* event, int node, long long eventTime) {
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->data = NULL;
  event->time = eventTime;
  event->handle = event_start_transmit_handle;
  event->cleanup = event_total_cleanup;
}

void corruptPacket(IncomingMsg* msg, int src, int dest) {
  int i;
  uint8_t* buf = (uint8_t*)&msg->msg;
  dbg(DBG_PACKET, "SIM_PACKET: Corrupting message from %i to %i\n", src, dest);
  for (i = 0; i < (TOSH_DATA_LENGTH + 7); i++) {
    buf[i] = (uint8_t)(rand() & 0xff);
  }
}

void event_start_transmit_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
  link_t* connectLink;
  TOS_MsgPtr msg = packet_transmitting[NODE_NUM];
  int transmitTime = (preambleLength + msg->length + headerLength);
  transmitTime *= byteTransmitTime;
  connectLink = cc1000_connectivity[NODE_NUM];
  
  dbg(DBG_PACKET, "SIM_PACKET: Transmitting, transmit time is %i.\n", transmitTime);
  
  while (connectLink != NULL) {
    int mote = connectLink->mote;
    if (mote >= tos_state.num_nodes ||
	!tos_state.moteOn[mote]) {
      connectLink = connectLink->next_link;
      continue;
    }
    // Can only receive a packet if you're not in transmit mode
    if (packet_transmitting[mote] == NULL) {
      event_t* recvEvent = (event_t*)malloc(sizeof(event_t));
      // Allocate a msg event and fill in the msg
      IncomingMsg* msgEvent = (IncomingMsg*)malloc(sizeof(IncomingMsg));
      memcpy(&msgEvent->msg, msg, sizeof(TOS_Msg));
      dbg(DBG_PACKET, "SIM_PACKET: Mote %i sending to mote %i\n", (int)NODE_NUM, (int)mote);
      // There's a collision. Corrupt this packet,
      // and corrupt all other incoming packets
      if (incoming[mote] != NULL) { 
	IncomingMsg* incomingMsg = incoming[mote];
	corruptPacket(msgEvent, NODE_NUM, mote);
	while (incomingMsg != NULL) {
	  corruptPacket(incomingMsg, NODE_NUM, mote);
	  incomingMsg = incomingMsg->next;
	}
      }

      msgEvent->next = incoming[mote];
      incoming[mote] = msgEvent;

      
      event_receive_packet_create(recvEvent, mote, tos_state.tos_time + transmitTime, msgEvent);
      TOS_queue_insert_event(recvEvent);
    }
    else {
      dbg(DBG_PACKET, "SIM_PACKET: Mote %i would send to mote %i, but it is transmitting.\n", (int)NODE_NUM, (int)mote);
    }
    connectLink = connectLink->next_link;
  }

  dbg(DBG_PACKET, "SIM_PACKET: Enqueueing send done.\n");
  event_send_packet_done_create(event, NODE_NUM, tos_state.tos_time + transmitTime);
  TOS_queue_insert_event(event);
  
}


void event_receive_packet_create(event_t* event, int node, long long eventTime, IncomingMsg* msg) __attribute__ ((C, spontaneous)) {
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->time = eventTime;
  event->handle = event_receive_packet_handle;
  event->cleanup = event_total_cleanup;
  event->data = msg;
}


void event_receive_packet_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
  IncomingMsg* receivedPacket;
  IncomingMsg* prevPacket = NULL;
  IncomingMsg* nextPacket = NULL;

  receivedPacket = (IncomingMsg*)event->data;
  // Pull the message off the queue
  prevPacket = incoming[NODE_NUM]; // If prev is NULL we have a bug
  if (prevPacket == receivedPacket) {
    incoming[NODE_NUM] = prevPacket->next;
  }
  else {
    while (prevPacket->next != NULL) {
      nextPacket = prevPacket->next;
      if (nextPacket == receivedPacket) {
	prevPacket->next = nextPacket->next;
	break;
      }
      prevPacket = nextPacket;
    }
  }
  
  dbg(DBG_PACKET, "SIM_PACKET: Receiving\n");
  packet_sim_receive_msg(&receivedPacket->msg);
  event_cleanup(event);
}

void event_send_packet_done_create(event_t* event, int node, long long eventTime) __attribute__ ((C, spontaneous)) {
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->time = eventTime;
  event->handle = event_send_packet_done_handle;
  event->cleanup = event_total_cleanup;
  event->data = NULL;
}


void event_send_packet_done_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
  TOS_MsgPtr bufferPtr = packet_transmitting[NODE_NUM];
  if (dbg_active(DBG_PACKET)) {
    char timeBuf[128];
    printTime(timeBuf, 128);
    dbg(DBG_PACKET, "SIM_PACKET: Send done @%s\n", timeBuf);
  }
  packet_transmitting[NODE_NUM] = NULL;
  packet_sim_transmit_done(bufferPtr);
  event_cleanup(event);
}
