/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 *                      Nelson Lee (revised) 
 *
 */

/*
 *   FILE: NARPRO_PING.c
 * AUTHOR: pal
 *  DESCR: Local ping protocol. - BETA
 *
 * PING is a network call-response component. It resembles the ICMP ping
 * utility except that it works at Layer 2 instead of 3; no routing is
 * involved.
 *
 * When a mote receives a PING message, it tries to immediately respond.
 * Sequence numbers are used to differentiate multiple PING requests. The
 * application is reponsible for keeping track of sequence numbers; they're
 * only meaningful in a network whose traffic makes the time required for
 * two backoffs greater than the interval between PING requests.
 *
 * Differences between NARPRO_PING and PING is NARPRO_PING does not contain a network stack.
 * It is assumed that the application using NARPRO_PING will initialize and connect PING
 * to a network stack like GENERIC_COMM
 */

/* Always use the ping_msg structure when messing with messages. */

#include "tos.h"
#include "NARPRO_PING.h"
#include "ping_msg.h"
#include "dbg.h"

extern short TOS_LOCAL_ADDRESS;

#define NARPRO_PING_TYPE 1

#ifndef NULL
#define NULL 0
#endif

#define TOS_FRAME_TYPE NARPRO_PING_obj_frame
TOS_FRAME_BEGIN(NARPRO_PING_obj_frame) {
  TOS_Msg buffer;	          // A packet buffer we hand around
  char send_pending;
}

TOS_FRAME_END(NARPRO_PING_obj_frame);

char TOS_COMMAND(NARPRO_PING_INIT)() {
  int i;
  char* ptr;

  dbg(DBG_BOOT, ("PING initialized.\n"));
  
  ptr = (char*)&VAR(buffer);
  for (i = 0; i < sizeof(TOS_Msg); i++) {
    ptr[i] = 0;
  }

  VAR(send_pending) = 0;
  return 1;
}

char TOS_COMMAND(NARPRO_PING_START)() {
  return 1;
}

char TOS_COMMAND(NARPRO_PING_SEND)(short moteID, char sequence) {
  ping_msg* msg = (ping_msg*)&(VAR(buffer).data);

  if (VAR(send_pending)) {
    return 0;
  }
  else {
    VAR(send_pending) = 1;
  }
  
  msg->source_addr = TOS_LOCAL_ADDRESS;
  msg->dest_addr = moteID;
  msg->sequence = sequence;
  msg->response = 0;
  
  return TOS_CALL_COMMAND(NARPRO_PING_SUB_SEND_MSG)(moteID, NARPRO_PING_TYPE, &VAR(buffer));
}

char TOS_COMMAND(NARPRO_PING_POWER)(char mode) {
  // Do nothing
  return 1;
}

TOS_MsgPtr TOS_EVENT(NARPRO_PING_MSG)(TOS_MsgPtr data) {
  ping_msg* msg = (ping_msg*)(data->data);

  dbg(DBG_ROUTE, ("PING: received  message from %i\n", (int)msg->source_addr));

  if (msg->dest_addr != TOS_LOCAL_ADDRESS &&
      msg->dest_addr != (short) 0xffff) {
    dbg(DBG_ROUTE, ("PING: received  message from %i\n", (int)msg->source_addr));

    
    // Do nothing
  }
  else if (msg->response == 1) {
    TOS_SIGNAL_EVENT(NARPRO_PING_RESPONSE)(msg->source_addr, msg->sequence);
  }
  else if (VAR(send_pending) == 0) {
    ping_msg* replyMsg = (ping_msg*)&(VAR(buffer).data);
    
    replyMsg->dest_addr = msg->source_addr;
    replyMsg->source_addr = TOS_LOCAL_ADDRESS;
    replyMsg->response = 1;
    if (TOS_SIGNAL_EVENT(NARPRO_PING_RECEIVE)(msg->source_addr, msg->sequence)) {
      VAR(send_pending) = 1;
      TOS_CALL_COMMAND(NARPRO_PING_SUB_SEND_MSG)(replyMsg->dest_addr,
					  NARPRO_PING_TYPE,
					  &VAR(buffer));
    }
  }
  
  return data;
}

char TOS_EVENT(NARPRO_PING_SEND_DONE)(TOS_MsgPtr data) {
  ping_msg* msg = (ping_msg*)(data->data);
  msg->response = -1;
  VAR(send_pending) = 0;
  return 1;
}












