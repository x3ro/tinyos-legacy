/*									tab:4
 * DB_QUERY.c
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
 
 Authors:  Sam Madden
 Date: 6/8/01
*/

#include "tos.h"
#include "DB_QUERY.h"
#include "MoteInfoStructs.h"


/* Utility functions */

#define TOS_FRAME_TYPE DB_QUERY_frame

TOS_FRAME_BEGIN(DB_QUERY_frame) {
  char pending_info;
  int cnt;
  TOS_Msg pending_msg;
}
TOS_FRAME_END(DB_QUERY_frame);

char TOS_COMMAND(QUERY_INIT)(){
  /*  TOS_CALL_COMMAND(DB_QUERY_SUB_INIT)(); */
  TOS_CALL_COMMAND(DB_QUERY_SUB_INIT_CLOCK)(tick2ps);
  VAR(cnt) = 0;
  printf("DB_QUERY initialized\n");
  return 1;
}

void TOS_EVENT(QUERY_EVENT)(){
  

  info_request_msg* message = (info_request_msg*)VAR(pending_msg).data;
  printf ("in query event");
  if (!VAR(pending_info)) {
    VAR(cnt)++;
    if (VAR(cnt) <= 1) {
      return 1;
    } else {
      VAR(cnt) = 0;
    }
    //ick -- make an active message without including AM...
    message->type = kSCHEMA_REQUEST;
    VAR(pending_msg).addr = TOS_BCAST_ADDR;
    VAR(pending_msg).type = 252;
    VAR(pending_msg).group = LOCAL_GROUP & 0xff;
    
    printf("sending query request!");
    if (TOS_COMMAND(DB_QUERY_SUB_SEND_MSG)(&VAR(pending_msg))) {
      VAR(pending_info) = 1;
    }
  }
}

TOS_MsgPtr TOS_EVENT(RX_PACKET)(TOS_MsgPtr data) {
    info_request_msg* message = (info_request_msg*)VAR(pending_msg).data;
    info_request_msg* input = (info_request_msg*)data->data;
    if (!VAR(pending_info)) {
      message->type = input->type;
      VAR(pending_msg).addr = data->addr;
      VAR(pending_msg).type = data->type;
      VAR(pending_msg).group = data->group;
      if (TOS_COMMAND(DB_QUERY_SUB_SEND_MSG)(&VAR(pending_msg))) {
	VAR(pending_info) = 1;
      }
    }
    return data;
}


/* Send completion event
   Determine if this event was ours.
   If so, process it by freeing output buffer and signalling event.

*/
char TOS_EVENT(DB_QUERY_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer){
  printf ("in msg send done");
  if (VAR(pending_info) && sentBuffer == &VAR(pending_msg)) {
    VAR(pending_info) = 0;
    /*  TOS_SIGNAL_EVENT(QUERY_COMPLETE)(); */
    return 1;
  }
  return 0;
}

/* Active Message handler
 */

TOS_MsgPtr TOS_MSG_EVENT(INFO_REQUEST_READING)(TOS_MsgPtr val){
  return val;
}
