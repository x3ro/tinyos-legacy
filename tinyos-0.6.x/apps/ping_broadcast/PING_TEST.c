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
 *
 *
 */

/*
 *   FILE: PING.c
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
 */

/* Always use the ping_msg structure when messing with messages. */

#include "tos.h"
#include "PING_TEST.h"
#include "ping_msg.h"
#include "dbg.h"

extern short TOS_LOCAL_ADDRESS;

#define TOS_FRAME_TYPE PING_TEST_obj_frame
TOS_FRAME_BEGIN(PING_TEST_obj_frame) {
}

TOS_FRAME_END(PING_TEST_obj_frame);

char TOS_COMMAND(PING_TEST_INIT)() {
  TOS_CALL_COMMAND(PING_TEST_SUB_CLOCK_INIT)(32, 0x7);
  return TOS_CALL_COMMAND(PING_TEST_SUB_INIT)();
}

char TOS_COMMAND(PING_TEST_START)() {
  return TOS_CALL_COMMAND(PING_TEST_SUB_START)();
}

char TOS_EVENT(PING_TEST_RECEIVE)(short moteID, char sequence) {
  return TOS_CALL_COMMAND(PING_TEST_RED_TOGGLE)();
}

void TOS_EVENT(PING_TEST_CLOCK)() {
  TOS_CALL_COMMAND(PING_TEST_GREEN_TOGGLE)();
  TOS_CALL_COMMAND(PING_TEST_SUB_SEND)(0xffff, 0);
}
