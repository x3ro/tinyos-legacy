// $Id: packet_sim.c,v 1.9 2004/10/07 22:05:13 scipio Exp $

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

#include "packet_sim.h"
#include "adjacency_list.h"

#define BIT_TIME 104
#define BYTE_TIME (8 * BIT_TIME)

int byteTransmitTime = BYTE_TIME * 2;
int initBackoffLow = 1 * BYTE_TIME;
int initBackoffHigh = 32 * BYTE_TIME;
int backoffLow = 1 * BYTE_TIME;
int backoffHigh = 16 * BYTE_TIME;
int txChangeLatency = 1000;
int preambleLength = 6; // In bytes
int headerLength = 7;    // In bytes

struct IncomingMsg;

typedef struct IncomingMsg {
  TOS_Msg msg;
  int fromID;
  struct IncomingMsg* next;
} IncomingMsg;

typedef enum {
  RADIO_TX_IDLE,
  RADIO_TX_BACK,
  RADIO_TX_TRANS,
  RADIO_RX_IDLE,
  RADIO_RX_RECV,
} PacketRadioState;

TOS_MsgPtr packet_transmitting[TOSNODES];

IncomingMsg* incoming[TOSNODES];
IncomingMsg* lastIncoming[TOSNODES];

TOS_Msg packet_sim_bufs[TOSNODES];
TOS_MsgPtr current_ptr[TOSNODES];

uint8_t rxState[TOSNODES];
uint8_t txState[TOSNODES];

link_t* packet_connectivity[TOSNODES];

void connectivity_init(char* cFile);
void initialBackoff();
void event_backoff_create(event_t* event, int node, long long eventTime);
void event_backoff_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));

void event_start_transmit_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));
void event_start_transmit_create(event_t* event, int node, long long eventTime);

void event_receive_packet_create(event_t* event, int node, long long eventTime, IncomingMsg* msg, bool noise) __attribute__ ((C, spontaneous));
void event_receive_packet_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));
void event_receive_packet_noise_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));

void event_send_packet_done_create(event_t* event, int node, long long eventTime) __attribute__ ((C, spontaneous));
void event_send_packet_done_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous));

bool removeIncomingEntry(int moteID, IncomingMsg* entry) {
  dbg(DBG_PACKET, "SIM_PACKET: Removing incoming packet from %i to %i\n", (int)entry->fromID, (int)moteID);
  if (incoming[moteID] == NULL) {
    dbg(DBG_ERROR, "SIM_PACKET: Could not find IncomingMsg entry 0x%x for mote %i.\n", entry, moteID);
    return FALSE;
  }
  else {
    if (incoming[moteID] == entry) {
      dbg(DBG_PACKET, "SIM_PACKET: Incoming: 0x%x\n", incoming[moteID]);
      if (lastIncoming[moteID] == entry) {
	lastIncoming[moteID] = NULL;
	incoming[moteID] = NULL;
      }
      else {
	incoming[moteID] = incoming[moteID]->next;
      }
      return TRUE;
    }
    else {
      IncomingMsg* prevMsg = incoming[moteID];
      IncomingMsg* currentMsg = incoming[moteID]->next;
      IncomingMsg* nextMsg;
      if (currentMsg == NULL) {
	dbg(DBG_ERROR, "SIM_PACKET: Could not find IncomingMsg entry 0x%x for mote %i.\n", entry, moteID);
	return FALSE;
      }
      nextMsg = currentMsg->next;

      while (currentMsg != entry && nextMsg != NULL) {
	prevMsg = currentMsg;
	currentMsg = nextMsg;
	nextMsg = currentMsg->next;
      }
      if (currentMsg != entry) {
	dbg(DBG_ERROR, "SIM_PACKET: Could not find IncomingMsg entry 0x%x for mote %i.\n", entry, moteID);
	return FALSE;
      }
      prevMsg->next = nextMsg;

      if (lastIncoming[moteID] == entry) {
	lastIncoming[moteID] = prevMsg;
      }
      
      dbg(DBG_PACKET, "SIM_PACKET: Incoming: 0x%x\n", incoming[moteID]);
      return TRUE;  
    }
  }
}

void addIncomingEntry(int moteID, IncomingMsg* entry) {
  dbg(DBG_PACKET, "SIM_PACKET: Adding incoming packet from %i to %i (incoming=0x%x)\n", (int)entry->fromID, (int)moteID, incoming[moteID]);
  entry->next = NULL;
  if (lastIncoming[moteID] == NULL) {
    incoming[moteID] = entry;
    lastIncoming[moteID] = entry;
  }
  else {
    lastIncoming[moteID]->next = entry;
    lastIncoming[moteID] = entry;
  }
}


void packet_sim_init(char* cFile) {
  int i;
  for (i = 0; i < TOSNODES; i++) {
    packet_transmitting[i] = NULL;
    incoming[i] = NULL;
    lastIncoming[i] = NULL;
    packet_connectivity[i] = NULL;
    rxState[i] = RADIO_RX_IDLE;
    txState[i] = RADIO_TX_IDLE;
    current_ptr[i] = &packet_sim_bufs[i];
  }
  connectivity_init(cFile);
}

result_t packet_sim_transmit(TOS_MsgPtr msg) {
  if (packet_transmitting[NODE_NUM] != NULL) {
    return FAIL;
  }
  packet_transmitting[NODE_NUM] = msg;
  txState[NODE_NUM] = RADIO_TX_BACK;
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
  dbg(DBG_PACKET, "SIM_PACKET: Handling backoff event @%s.\n", currentTime());
  if (txState[NODE_NUM] != RADIO_TX_BACK) {
    dbg(DBG_ERROR, "SIM_PACKET: Backing off in non-backoff state.\n");
  }
  
  if (incoming[NODE_NUM] != NULL) {
    int backoffAmount = backoffLow;
    backoffAmount += rand() % (backoffHigh - backoffLow);
    event_backoff_create(event, NODE_NUM, tos_state.tos_time + backoffAmount);
    dbg(DBG_PACKET, "SIM_PACKET: Backoff more: %i.\n", backoffAmount);
    TOS_queue_insert_event(event);
  }
  else {
    dbg(DBG_PACKET, "SIM_PACKET: No incoming packet, transmit OK.\n");
    txState[NODE_NUM] = RADIO_TX_TRANS;
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
  msg->msg.crc = 0;
}

void event_start_transmit_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
  link_t* connectLink;
  TOS_MsgPtr msg = packet_transmitting[NODE_NUM];
  int transmitTime = (preambleLength + msg->length + headerLength);
  bool ack = FALSE;
  transmitTime *= byteTransmitTime;
  connectLink = packet_connectivity[NODE_NUM];
  msg->crc = 1;
  
  dbg(DBG_PACKET, "SIM_PACKET: Transmitting, transmit time is %i.\n", transmitTime);
  
  while (connectLink != NULL) {
    int mote = connectLink->mote;
    // Can only receive a packet if you're not in transmit mode
    
    event_t* recvEvent = (event_t*)malloc(sizeof(event_t));
    IncomingMsg* msgEvent = (IncomingMsg*)malloc(sizeof(IncomingMsg));
    msgEvent->fromID = NODE_NUM;
    msgEvent->next = NULL;
    nmemcpy(&msgEvent->msg, msg, sizeof(TOS_Msg));

    dbg(DBG_PACKET, "SIM_PACKET: Considering reception at %i\n", (int)mote);
    
    if (incoming[mote] == NULL &&
        txState[mote] != RADIO_TX_TRANS &&
        tos_state.moteOn[mote]) {
      int r;
      double prob;
      
      r = rand() % 100000;
      prob = ((double)r) / 100000.0;
      if (prob < connectLink->data) {
	corruptPacket(msgEvent, NODE_NUM, mote);
	rxState[mote] = RADIO_RX_RECV;
      }
      else {
	if (msg->addr == TOS_BCAST_ADDR ||
	    msg->addr == mote) {
	  ack = TRUE;
	}
	rxState[mote] = RADIO_RX_RECV;
	current_ptr[mote]->crc  = 1;
      }
      dbg(DBG_PACKET, "SIM_PACKET: Enqueueing receive for %i.\n", mote);
      event_receive_packet_create(recvEvent, mote, tos_state.tos_time + transmitTime, msgEvent, TRUE);
      addIncomingEntry(mote, msgEvent);
      TOS_queue_insert_event(recvEvent);
    }
    else {
      IncomingMsg* alreadyIncoming = incoming[mote];
      dbg(DBG_PACKET, "SIM_PACKET: %i already receiving or transmitting: enqueue event for non-receive (noise), corrupt all already incoming\n", mote);
      while (alreadyIncoming != NULL) {
	corruptPacket(alreadyIncoming, NODE_NUM, mote);
	// This packet can be null due to the rate limiting mechanism
	// A sender gets a sendDone before a receiver gets a receive
	// So, it's possible the sender pointer is NULL before
	// the receiver handles the packet
	if (packet_transmitting[alreadyIncoming->fromID] != NULL &&
            packet_transmitting[alreadyIncoming->fromID]->addr == mote) {
	  packet_transmitting[alreadyIncoming->fromID]->ack = 0;
	}
	alreadyIncoming = alreadyIncoming->next;
      }
      event_receive_packet_create(recvEvent, mote, tos_state.tos_time + transmitTime, msgEvent, FALSE);
      addIncomingEntry(mote, msgEvent);
      TOS_queue_insert_event(recvEvent);
    }
    connectLink = connectLink->next_link;
  }
  
  packet_transmitting[NODE_NUM] = msg;
  msg->ack = ack;
  dbg(DBG_PACKET, "SIM_PACKET: Enqueueing send done.\n");
  event_send_packet_done_create(event, NODE_NUM, (tos_state.tos_time + transmitTime) - 1);
  TOS_queue_insert_event(event);  
}


void event_receive_packet_create(event_t* event, int node, long long eventTime, IncomingMsg* msg, bool deliver) __attribute__ ((C, spontaneous)) {
  event->mote = node;
  event->force = 1;
  event->pause = 0;
  event->time = eventTime;
  if (deliver) {
    event->handle = event_receive_packet_handle;
  }
  else {
    event->handle = event_receive_packet_noise_handle;
  }
  event->cleanup = event_total_cleanup;
  event->data = msg;
  msg->next = NULL;
}

void event_receive_packet_noise_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
  IncomingMsg* receivedPacket;
  
  receivedPacket = (IncomingMsg*)event->data;
  // Pull the message off the queue
  removeIncomingEntry(NODE_NUM, receivedPacket);

  rxState[NODE_NUM] = RADIO_RX_IDLE;

  dbg(DBG_PACKET, "SIM_PACKET: Noise packet (no proper detection), don't deliver\n");
  event_cleanup(event);
}

void event_receive_packet_handle(event_t* event, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
  IncomingMsg* receivedPacket;
  
  receivedPacket = (IncomingMsg*)event->data;
  // Pull the message off the queue
  removeIncomingEntry(NODE_NUM, receivedPacket);

  rxState[NODE_NUM] = RADIO_RX_IDLE;

  if (NODE_NUM < tos_state.num_nodes &&
      tos_state.moteOn[NODE_NUM]) {
    dbg(DBG_PACKET, "SIM_PACKET: Receiving\n");
    memcpy(current_ptr[NODE_NUM], &receivedPacket->msg, sizeof(TOS_Msg));
    current_ptr[NODE_NUM] = packet_sim_receive_msg(current_ptr[NODE_NUM]);
  }
  
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
  RadioMsgSentEvent ev;
  TOS_MsgPtr bufferPtr = packet_transmitting[NODE_NUM];
  if (dbg_active(DBG_PACKET)) {
    char timeBuf[128];
    printTime(timeBuf, 128);
    dbg(DBG_PACKET, "SIM_PACKET: Send done @%s\n", timeBuf);
  }
  
  memcpy(&ev.message, bufferPtr, sizeof(ev.message));
  ev.message.crc = 1; // Tools expect crc={0,1}, not actual CRC value -pal
  sendTossimEvent(NODE_NUM, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &ev);
  
  packet_transmitting[NODE_NUM] = NULL;
  packet_sim_transmit_done(bufferPtr);
  txState[NODE_NUM] = RADIO_TX_IDLE;
  event_cleanup(event);
}


int read_int(FILE* file) {
  char buf[128];
  int findex = 0;
  int ch;
  while(1) {
    ch = getc(file);
    if (ch == EOF) {return -1;}
    else if (ch >= '0' && ch <= '9') {
      buf[findex] = (char)ch;
      findex++;
    }
    else if (ch == '\n' || ch == ' ' || ch == '\t') {
      if (findex == 0) {
	continue;
      }
      else {
	buf[findex] = 0;
	break;
      }
    }
    else {
      return -1;
    }
    if (findex >= 127) {
      return -1;
    }
  }
  return atoi(buf);
}

double read_double(FILE* file) {
  char buf[128];
  int findex = 0;
  int ch;
  while(1) {
    ch = getc(file);
    if (ch == EOF) {return -1;}
    else if ((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == 'E'
             || ch == 'e') {
      buf[findex] = (char)ch;
      findex++;
    }
    else if (ch == '\n' || ch == ' ' || ch == '\t') {
      if (findex == 0) {
	continue;
      }
      else {
	buf[findex] = 0;
	break;
      }
    }
    else {
      return -1;
    }
    if (findex >= 127) {
      return -1;
    }
  }
  return atof(buf);
}

int read_packet_entry(FILE* file, int* mote_one, int* mote_two, double* packet_loss, double* falsePos, double* falseNeg) {
  bool okFormat = TRUE;
  if ((*mote_one = read_int(file)) < 0) {okFormat = FALSE;}
  else if ((*mote_two = read_int(file)) < 0) {okFormat = FALSE;}
  else if ((*packet_loss = read_double(file)) < 0) {okFormat = FALSE;}
  else if ((*falsePos = read_double(file)) < 0) {okFormat = FALSE;}
  else if ((*falseNeg = read_double(file)) < 0) {okFormat = FALSE;}
  else {
    dbg_clear(DBG_SIM, "SIM: Read in packet entry %i->%i, packet loss: %lf, ack false pos: %lf, neg: %lf\n", *mote_one, *mote_two, *packet_loss, *falsePos, *falseNeg);
  }
  return (okFormat == TRUE);
}

void connectivity_init(char* cFile) {
  int mote_one, mote_two;
  double packet, positive, negative;
  FILE* f = fopen(cFile, "r");
  if (f == NULL) {
    fprintf(stderr, "SIM: Could not load packet configuration file %s\n", cFile);
    return;
  }
  while (read_packet_entry(f, &mote_one, &mote_two, &packet, &positive, &negative)) {
    link_t* new_link;
    new_link = allocate_link(mote_two);
    new_link->data = packet;
    new_link->neg = negative;
    new_link->pos = positive;
    new_link->next_link = packet_connectivity[mote_one];
    packet_connectivity[mote_one] = new_link;
  }
}
