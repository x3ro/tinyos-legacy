/*									tab:2
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Phil Levis
 *
 *
 */

/*
 *   FILE: RMTP.c
 * AUTHOR: pal
 *  DESCR: Reliable Mote Transport Protocol
 *
 */

/* Always use the rmtp_msg structure when messing with messages. */

#include "tos.h"
#include "RMTP.h"
#include "rmtp_msg.h"
#include "dbg.h"

extern short TOS_LOCAL_ADDRESS;

// IDLE: No current transmission/ACK completed
// START: Transmission scheduled
// TRANS: Have transmitted to parent
// ACK_WAIT: Parent has received, waiting for ACK
// ACK_TRANKS: ACK transmitted
typedef enum {RMTP_IDLE, RMTP_START, RMTP_TRANS} State;

#define NUM_PARENTS     4
static const char CONTROL_TIMER_NUM         = 0x09;
static const char TRANSPORT_TIMER_NUM       = 0x0a;
static const char LINK_TIMER_NUM            = 0x0b;
static const char ACK_TIMER_NUM             = 0x0c;


static const UINT32 LINK_TIMER_TICKS        =  50;// 50 ms ~= 3 packet times
static const UINT32 TRANSPORT_TIMER_TICKS   = 500;// 50 ms ~= 32 packet times
static const char MAX_LINK_TRANSMITS        =    8;
static const char MAX_TRANSPORT_TRANSMITS   =    3;
static const char NO_PARENT                 =   -1;
static const char MAX_HOPS                  =    5;

#define PARENT (VAR(parentCache)[(int)VAR(currentParent)])

typedef struct {
  unsigned short id;
  unsigned char hopCount;
  unsigned char lastHeard;
  unsigned short total;
  unsigned short heard;
} ParentEntry;

#define TOS_FRAME_TYPE RMTP_obj_frame
TOS_FRAME_BEGIN(RMTP_obj_frame) {
  State sendState;
  State ackState;
  char isSink;
  char waitingForAck;
  
  unsigned char commBusy;

  unsigned char dataSeq;
  unsigned char sendLinkCounter;
  unsigned char sendTransportCounter;
  unsigned char ackLinkCounter;

  ParentEntry parentCache[4];
  char currentParent;
  char isEndpoint;

  TOS_Msg dataPacket;
  TOS_Msg ackPacket;
  TOS_Msg controlPacket;

  TOS_MsgPtr dataBuffer;
  TOS_MsgPtr ackBuffer;
  TOS_MsgPtr controlBuffer;
  
  TOS_MsgPtr packetPending;
}
TOS_FRAME_END(RMTP_obj_frame);

char TOS_COMMAND(RMTP_INIT)(void) {
  char rval = TOS_CALL_COMMAND(RMTP_SUB_TIMER_INIT)();
  rval &= TOS_CALL_COMMAND(RMTP_SUB_COMM_INIT)();
  return rval;
}

char TOS_COMMAND(RMTP_START)(void) {
  VAR(currentParent) = NO_PARENT;
  VAR(parentCache)[0].id = TOS_BCAST_ADDR;
  VAR(parentCache)[1].id = TOS_BCAST_ADDR;
  VAR(parentCache)[2].id = TOS_BCAST_ADDR;
  VAR(parentCache)[3].id = TOS_BCAST_ADDR;

  VAR(commBusy) = 0;
  VAR(isEndpoint) = 0;
  
  VAR(sendState) = RMTP_IDLE;
  VAR(sendLinkCounter) = 0;
  VAR(sendTransportCounter) = 0;
  VAR(dataBuffer) = (TOS_MsgPtr)&VAR(dataPacket);
  VAR(dataSeq) = 0;
  
  VAR(ackState) = RMTP_IDLE;
  VAR(ackLinkCounter) = 0;
  VAR(ackBuffer) = (TOS_MsgPtr)&VAR(ackPacket);

  VAR(controlBuffer) = (TOS_MsgPtr)&VAR(controlPacket);
  
  VAR(sendTransportCounter) = 0;
  VAR(isSink) = 0;
  return 1;
}

void parentCheck(TOS_MsgPtr dataPacket) {}
void selectParent() {
  if (VAR(parentCache)[0].id != TOS_BCAST_ADDR) {
    VAR(currentParent) = 0;
    dbg(DBG_ROUTE, ("RMTP: Selected entry %hhi as current parent.\n", VAR(currentParent)));
  }
}

static inline void startTransmitTimer() {
  // We add some salt to try to reduce occurance of hidden node problem
  short salt = TOS_CALL_COMMAND(RMTP_SUB_RANDOM)() & 0xf;
  TOS_CALL_COMMAND(RMTP_SUB_TIMER_START)(LINK_TIMER_NUM, 0, LINK_TIMER_TICKS + salt);
}

static inline void stopTransmitTimer() {
  TOS_CALL_COMMAND(RMTP_SUB_TIMER_STOP)(LINK_TIMER_NUM);
}

static inline void startTransportTimer() {
  TOS_CALL_COMMAND(RMTP_SUB_TIMER_START)(TRANSPORT_TIMER_NUM, 0, TRANSPORT_TIMER_TICKS);
}
static inline void stopTransportTimer() {
  TOS_CALL_COMMAND(RMTP_SUB_TIMER_STOP)(TRANSPORT_TIMER_NUM);
}

static inline void startAckTimer() {
  TOS_CALL_COMMAND(RMTP_SUB_TIMER_START)(TRANSPORT_TIMER_NUM, 0, LINK_TIMER_TICKS);
}
static inline void stopAckTimer() {
  TOS_CALL_COMMAND(RMTP_SUB_TIMER_STOP)(TRANSPORT_TIMER_NUM);
}


static inline char isSource(RMTPMsg* msg) {
  int i;
  for (i = 5; i >= 0; i--) {
    if (msg->path[i] == TOS_LOCAL_ADDRESS) {return 1;}
    else if (msg->path[i] != TOS_BCAST_ADDR) {return 0;}
  }
  return 0;
}

static inline short source(RMTPMsg* msg) {
  int i;
  for (i = 5; i >= 0; i--) {
    if (msg->path[i] != TOS_BCAST_ADDR) {return msg->path[i];}
  }
  return TOS_BCAST_ADDR;
}
static inline char isEndpoint() {
  return VAR(isEndpoint);
}

int selectParentIndex(short address, char hopcount) {
  if (VAR(currentParent) == NO_PARENT || hopcount < PARENT.hopCount) {
    return 0;
  }
  else {
    return 1;
  }
}

static inline int packetAddressedToMe(TOS_MsgPtr packet) {
  RMTPMsg* msg = (RMTPMsg*)packet->data;
  return (msg->dest == TOS_LOCAL_ADDRESS);
}

static inline void formatForwardPacket(TOS_MsgPtr packet) {
  int i;
  RMTPMsg* msg = (RMTPMsg*)packet->data;
  msg->dest = PARENT.id;
  msg->src_hop_distance = PARENT.hopCount + 1;
  
  for (i = 4; i >= 0; i--) {
    msg->path[i+1] = msg->path[i];
  }
  msg->path[0] = TOS_LOCAL_ADDRESS;
  
  msg->seq = VAR(dataSeq);
  VAR(dataSeq)++;
}

void enqueueSend(TOS_MsgPtr msg) {}

// DATA SEND TASK
TOS_TASK(dataSendTask) {
  unsigned short addr = TOS_BCAST_ADDR;
  RMTPMsg* msg = (RMTPMsg*)VAR(dataBuffer)->data;
  TOS_CALL_COMMAND(RED_LED_TOGGLE)();
  if (VAR(commBusy)) {return;}
  if (VAR(isSink)) {
    msg->dest = TOS_LOCAL_ADDRESS;
    stopTransmitTimer();
    dbg(DBG_ROUTE, ("RMTP: SINK -> ACK %04hhx\n", source(msg)));
    VAR(sendState) = RMTP_IDLE;
    memcpy(VAR(ackBuffer), VAR(dataBuffer), sizeof(TOS_Msg));
    VAR(commBusy) = 1;
    VAR(packetPending) = VAR(ackBuffer);
    TOS_CALL_COMMAND(RMTP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(DATA_MSG), VAR(ackBuffer));
  }
  else if (VAR(sendLinkCounter) > MAX_LINK_TRANSMITS) {
    dbg(DBG_ROUTE, ("RMTP: Gave up on packet send after %i attempts.\n", (int)VAR(sendLinkCounter)));
    stopTransmitTimer();
    VAR(sendLinkCounter) = 0;
    VAR(sendState) = RMTP_IDLE;
    if (isSource(msg)) {
      TOS_SIGNAL_EVENT(RMTP_SEND_FAILED)(msg->data);
    }
  }
  else if (TOS_CALL_COMMAND(RMTP_SUB_SEND_MSG)(addr, AM_MSG(DATA_MSG), VAR(dataBuffer))) { 
    VAR(packetPending) = VAR(dataBuffer);
    VAR(commBusy) = 1;
    dbg(DBG_ROUTE, ("RMTP: %04hx -> %04hx\n", TOS_LOCAL_ADDRESS, PARENT.id));
    VAR(sendState) = RMTP_TRANS;
    VAR(sendLinkCounter)++;
  }
  else {
    enqueueSend(VAR(dataBuffer));
    dbg(DBG_ROUTE, ("RMTP: Packet send request failed: enqueue to send.\n"));
  }
}

TOS_TASK(ackTask) {
  if (VAR(commBusy)) {return;}

  if (TOS_CALL_COMMAND(RMTP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(ACK_MSG), VAR(ackBuffer))) {
    VAR(commBusy) = 1;
    VAR(packetPending) = VAR(ackBuffer);
  }
}

char TOS_COMMAND(RMTP_SEND)(char* data, char len) {
  dbg(DBG_ROUTE, ("RMTP: Send request of %hhi bytes from application.\n", len));
  if (!VAR(commBusy)) {
    RMTPMsg* msg = (RMTPMsg*)VAR(dataBuffer)->data;
    len = (len < RMTP_DATA_LEN)? len : RMTP_DATA_LEN;
    memcpy(msg->data, data, len);
    msg->seq = VAR(dataSeq);
    VAR(dataSeq)++;
    msg->dest = PARENT.id;
    msg->src_hop_distance = PARENT.hopCount + 1;
    msg->path[0] = TOS_LOCAL_ADDRESS;
    msg->path[1] = TOS_BCAST_ADDR;
    msg->path[2] = TOS_BCAST_ADDR;
    msg->path[3] = TOS_BCAST_ADDR;
    msg->path[4] = TOS_BCAST_ADDR;
    msg->path[5] = TOS_BCAST_ADDR;
    VAR(sendLinkCounter) = 0;
    startTransmitTimer();
    TOS_POST_TASK(dataSendTask);
  }
  else {
    dbg(DBG_ROUTE, ("RMTP: Send request when in midst of send. Refuse.\n"));
    return 0;
  }
  return 1;
}

char TOS_COMMAND(RMTP_SEND_CANCEL)(void) {
  VAR(sendState) = RMTP_IDLE;
  VAR(sendLinkCounter) = 0;
  VAR(sendTransportCounter) = 0;
  return 1;
}

TOS_TASK(controlRecvTask) {
  // Herein we put parents into a routing table, yo
  RMTPMsg* msg = (RMTPMsg*)VAR(controlBuffer)->data;
  short sender = msg->path[0];
  unsigned char hopCount = msg->src_hop_distance;
  int index;
  if (VAR(currentParent) != NO_PARENT &&
      msg->src_hop_distance > PARENT.hopCount) {
    dbg(DBG_ROUTE, ("RMTP: Discarding control packet -- %hhi is further away than my parent (%hhi).\n", msg->src_hop_distance, PARENT.hopCount));
  }
  else {
    dbg(DBG_ROUTE, ("RMTP: Processing control packet. Source: %hx, hopcount: %hhu\n", sender, hopCount));\
    index = (int)selectParentIndex(sender, hopCount);
    if (index >= 0) {
      VAR(parentCache)[index].id = sender;
      VAR(parentCache)[index].hopCount = hopCount;
      VAR(parentCache)[index].lastHeard = msg->seq;
      VAR(parentCache)[index].total = 1;
      VAR(parentCache)[index].heard = 1;
    }
    
    selectParent();
    
    msg->path[0] = TOS_LOCAL_ADDRESS;
    msg->src_hop_distance = PARENT.hopCount + 1;
    msg->seq = VAR(dataSeq);
    VAR(dataSeq)++;
    if (index == 0 && !VAR(commBusy)) {
      short randomWait = (TOS_CALL_COMMAND(RMTP_SUB_RANDOM)() & 0x7) << 5;
      VAR(commBusy) = 1;
      VAR(packetPending) = VAR(controlBuffer);
      dbg(DBG_ROUTE, ("RMTP: Schedule control packet timer for %i ms.\n", (int)randomWait));
      TOS_CALL_COMMAND(RMTP_SUB_TIMER_START)(CONTROL_TIMER_NUM, 1, 500 + randomWait);
    }
  }
}

TOS_TASK(controlSendTask) {
  if (TOS_CALL_COMMAND(RMTP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(CONTROL_MSG), VAR(controlBuffer))) {
    dbg(DBG_ROUTE, ("RMTP: Sending control packet.\n"));
    return;
  }
  else {
    short randomWait = TOS_CALL_COMMAND(RMTP_SUB_RANDOM)();
    dbg(DBG_ROUTE, ("RMTP: Control packet send refused: reset timer.\n"));    
    TOS_CALL_COMMAND(RMTP_SUB_TIMER_START)(CONTROL_TIMER_NUM, 1, randomWait & 0x7f);
  }
}

void TOS_EVENT(RMTP_CONTROL_TIMER)(void) {
  dbg(DBG_ROUTE, ("RMTP: Control timer triggered.\n"));
  TOS_POST_TASK(controlSendTask);
}


char TOS_COMMAND(RMTP_DISCOVER)() {
  RMTPMsg* msg = (RMTPMsg*)VAR(controlBuffer)->data;
  dbg(DBG_ROUTE, ("RMTP: Initiating discover beacon.\n"));

  msg->path[0] = TOS_LOCAL_ADDRESS;
  msg->src_hop_distance = 0;
  msg->seq = 0;
  VAR(isSink) = 1;
  if (TOS_CALL_COMMAND(RMTP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(CONTROL_MSG), VAR(controlBuffer))) { 
    VAR(commBusy) = 1;
    VAR(packetPending) = VAR(controlBuffer);
  }
  return 1;
}

void TOS_EVENT(RMTP_SEND_RETRANSMIT_TIMER)(void) {
  TOS_POST_TASK(dataSendTask);
}

void TOS_EVENT(RMTP_ACK_RETRANSMIT_TIMER)(void) {
  dbg(DBG_ROUTE, ("RMTP: ACK timer triggered\n"));
}

void TOS_EVENT(RMTP_SEND_FAIL_TIMER)(void) {
  VAR(sendState) = RMTP_IDLE;
  dbg(DBG_ROUTE, ("RMTP: Transport timer triggered\n"));
}

char RMTP_SEND_DONE(TOS_MsgPtr data) {
  return 1;
}

TOS_MsgPtr TOS_EVENT(CONTROL_MSG)(TOS_MsgPtr packet) {
  TOS_MsgPtr tmp = VAR(controlBuffer);
  dbg(DBG_ROUTE, ("RMTP: Received control packet.\n"));
  VAR(controlBuffer) = packet;
  if (!VAR(isSink)) {
    TOS_POST_TASK(controlRecvTask);
  }
  else {
    dbg(DBG_ROUTE, ("RMTP: Discarding control packet -- I'm a sink.\n"));
  }
  return tmp;
}

TOS_MsgPtr TOS_EVENT(DATA_MSG)(TOS_MsgPtr packet) {
  TOS_MsgPtr tmp;
  //dbg(DBG_ROUTE, ("RMTP: Received data packet.\n"));
  if (packetAddressedToMe(packet)) { // Asked to forward a data packet
    // Should we forward this packet, or are we going to aggregate?
    if (!TOS_SIGNAL_EVENT(RMTP_FORWARD_PACKET)(packet)) {
      return packet;
    }
    if (VAR(sendState) == RMTP_IDLE &&
	VAR(ackState) == RMTP_IDLE) { // I'm idle -- forward packet
      //dbg(DBG_ROUTE, ("RMTP: Asked to forward a packet when idle: forward it.\n"));
      tmp = VAR(dataBuffer);           
      VAR(sendState) = RMTP_START;
      VAR(dataBuffer) = packet;
      VAR(sendLinkCounter) = 0;
      startTransmitTimer();
      formatForwardPacket(packet);
      TOS_POST_TASK(dataSendTask);
      return tmp;
    }
    else if (VAR(sendState) == RMTP_START ||
	     VAR(sendState) == RMTP_TRANS) { // Not idle
      RMTPMsg* recv = (RMTPMsg*)packet->data;
      RMTPMsg* held = (RMTPMsg*)VAR(dataBuffer)->data;
      if (recv->path[0] == held->path[0] &&
	  (recv->seq - held->seq >= 0)) { // Newer packet -- send it instead.
	tmp = VAR(dataBuffer);
	VAR(dataBuffer) = packet;
	formatForwardPacket(packet);
	//dbg(DBG_ROUTE, ("RMTP: Asked to forward a newer packet: replace.\n"));
	return tmp;
      }
      else { // Different packet or present packet retransmitted
	dbg(DBG_ROUTE, ("RMTP: Asked to forward a redundant or another packet. Ignore.\n"));
      }
    }
  }
  else { // Not for me -- maybe it was mine?
    RMTPMsg* msg = (RMTPMsg*)packet->data;
    if (msg->path[1] == TOS_LOCAL_ADDRESS &&
	VAR(sendState) == RMTP_TRANS) {
      VAR(sendState) = RMTP_IDLE;
      //dbg(DBG_ROUTE, ("RMTP: %04hx -|\n", TOS_LOCAL_ADDRESS));
      stopTransmitTimer();
      if (isSource(msg)) {
	TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
	TOS_SIGNAL_EVENT(RMTP_SEND_ACKED)(msg->data);
      }
    }
    parentCheck(packet);
  }
  return packet;
}

void formatAck(TOS_MsgPtr packet) {
  int i;
  unsigned short dest = TOS_UART_ADDR;
  RMTPMsg* msg = (RMTPMsg*)packet->data;
  for (i = 1; i < 5; i++) {
    if (msg->path[i] == TOS_LOCAL_ADDRESS) {
      dest = msg->path[i+1];
      break;
    }
  }
  msg->dest = dest;
  msg->src_hop_distance = PARENT.hopCount + 1;
}

TOS_MsgPtr TOS_EVENT(ACK_MSG)(TOS_MsgPtr packet) {
  RMTPMsg* msg = (RMTPMsg*)packet->data;
    
  dbg(DBG_ERROR, ("RMTP: ACK received.\n"));
  if (msg->dest == TOS_LOCAL_ADDRESS) {
    if (isSource(msg)) {
      dbg(DBG_ROUTE, ("RMTP: Received ACK for packet I started. Reliability! Go back to idle.\n"));
      VAR(ackState) = RMTP_IDLE;
      VAR(sendState) = RMTP_IDLE;
      stopAckTimer();
      stopTransmitTimer();
    }
    else if (VAR(ackState) == RMTP_IDLE) {
      TOS_MsgPtr tmp;
      startAckTimer();
      VAR(ackState) = RMTP_START;
      tmp = VAR(ackBuffer);
      VAR(ackBuffer) = packet;
      formatAck(packet);
      dbg(DBG_ROUTE, ("RMTP: Forward ACK.\n"));
      TOS_POST_TASK(ackTask);
      return VAR(ackBuffer);
    }
    else {
      dbg(DBG_ROUTE, ("RMTP: Received ACK when already busy ACKing.\n"));
    }
  }
  else {
    dbg(DBG_ROUTE, ("RMTP: ACK not for me. For: %hx\n", msg->dest));
  }
  return packet;
}

char TOS_EVENT(RMTP_SEND_DONE)(TOS_MsgPtr packet) {
  if (!VAR(commBusy)) {
    dbg(DBG_ERROR, ("RMTP: Send completion notification when no send in progress!\n"));
    return 0;
  }
  else if (VAR(packetPending) != packet) {
    dbg(DBG_ERROR, ("RMTP: Completed sending a different packet than we sent!\n"));
    VAR(commBusy) = 0;
    return 0;
  }
  VAR(commBusy) = 0;
  VAR(packetPending) = 0;
  return 1;
}

char TOS_COMMAND(RMTP_HAS_PARENT)() {
  return (VAR(currentParent) != NO_PARENT);
}
