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
#include "TEST_RMTP.h"
#include "rmtp_msg.h"
#include "dbg.h"

#define TEST_TIMER 0x0d

#define TOS_FRAME_TYPE TEST_RMTP_obj_frame
TOS_FRAME_BEGIN(TEST_RMTP_obj_frame) {
  char buffer[4];
  char counter;
}
TOS_FRAME_END(TEST_RMTP_obj_frame);

char TOS_COMMAND(TEST_INIT)(void) {
  VAR(counter) = 0;
  return TOS_CALL_COMMAND(TEST_SUB_INIT)();
}

char TOS_COMMAND(TEST_START)(void) {
  char rval;
  dbg(DBG_BOOT, ("TEST_RMTP: Started.\n"));
  VAR(buffer)[0] = 0xde;
  VAR(buffer)[1] = 0xad;
  VAR(buffer)[2] = 0xbe;
  VAR(buffer)[3] = 0xef;
  if (TOS_LOCAL_ADDRESS == 0) {return;}
  if (TOS_LOCAL_ADDRESS == 1) {
    rval = TOS_CALL_COMMAND(TEST_SUB_TIMER_START)(TEST_TIMER, 1, (UINT32)1000);
  }
  else {
    rval = TOS_CALL_COMMAND(TEST_SUB_TIMER_START)(TEST_TIMER, 1, (UINT32)4000);
  }
  if (rval) {
    dbg(DBG_BOOT|DBG_ERROR, ("TEST_RMTP: Timer registration returned %hhi\n", rval));
  }
  return TOS_CALL_COMMAND(TEST_SUB_START)();
}

void TOS_EVENT(TEST_TIMER)(void) {
  short randval = TOS_CALL_COMMAND(TEST_SUB_RANDOM)();
  if (TOS_LOCAL_ADDRESS == 1 && (VAR(counter) <= 3)) { 
    dbg(DBG_USR1, ("TEST_RMTP: Timer triggered: discover network.\n"));
    TOS_CALL_COMMAND(TEST_SUB_DISCOVER)();
    TOS_CALL_COMMAND(TEST_SUB_TIMER_START)(TEST_TIMER, 1, (UINT32)12000);
    VAR(counter)++;
  }
  else {
    dbg(DBG_USR1, ("TEST_RMTP: Timer triggered. Reset timer.\n"));
    TOS_CALL_COMMAND(TEST_SUB_TIMER_START)(TEST_TIMER, 1, (UINT32)2000);
    if ((randval & 0xf) == TOS_LOCAL_ADDRESS) {
      if (TOS_CALL_COMMAND(TEST_SUB_HAS_PARENT)()) {
	dbg(DBG_USR1, ("TEST_RMTP: Send data packet.\n"));
	TOS_CALL_COMMAND(TEST_SUB_SEND)(VAR(buffer), 4);
      }
      else {
	dbg(DBG_USR1, ("TEST_RMTP: No parent. Don't send.\n"));
      }
    }
  }
}

char TOS_EVENT(TEST_SEND_ACKED)(char* data) {
  dbg(DBG_USR2, ("TEST_RMTP: Send acknowledged.\n"));
  return 1;
}

char TOS_EVENT(TEST_SEND_FAILED)(char* data) {
  dbg(DBG_USR2, ("TEST_RMTP: Send failed.\n"));
  return 1;
}

char TOS_EVENT(TEST_FORWARD_PACKET)(TOS_MsgPtr msg) {
  return 1;
}
