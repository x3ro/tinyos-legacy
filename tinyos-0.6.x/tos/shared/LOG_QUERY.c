/*									tab:4
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
 * Authors:		Solomon Bien
 * 					(based, in part, on LOG_DUMP.c
 *					 by Deepak Ganesan)
 *
 * This component manages a log and allows for its querying over the air.
 * Call LOG_QUERY_RECORD() to write to the end of the log.  Query the log
 * over the air.  This component uses AM handlers 96 and 97.  When querying,
 * the user can specify the node to which the log data should be sent, the 
 * line in the log at which reading should start, the number of lines to 
 * read, and whether or not to read to the end of the log.
 */

#include "tos.h"
#include "LOG_QUERY.h"

extern short TOS_LOCAL_ADDRESS;

/* Constants to avoid screwing up
   Network Reprogramming
   If NOT used with reprogramming
   set MAX_LINES to 2048
   and BASELINE to 0
*/
#define START_OF_LOG 1
#define MAX_LINES 1024
#define BASELINE 1024 

#define INACTIVE 1
#define ACTIVE 2

#define TOS_FRAME_TYPE LOG_QUERY_obj_frame
TOS_FRAME_BEGIN(LOG_QUERY_obj_frame) {
  TOS_Msg data;

  /* Use if used on motes with mote-id programmed into the First 16 byte
     block in the EEPROM. This would be the case with all Nework
     Reprogrammable motes
  */

  char send_pending;
  char state;
  short src;
  unsigned int numLinesWritten;
  unsigned int log_line;
  unsigned int numLines;
}
TOS_FRAME_END(LOG_QUERY_obj_frame);

typedef struct {
  short src;            // the node to which the response should be sent
  int startLineNumber;  // the line at which to start reading the log
  char readingToEnd;    /* 1 if the remainder of the log should be read, 
			   0 if not */
  int numLines;         // the number of lines that should be read
} log_query_msg;

char TOS_COMMAND(LOG_QUERY_INIT)(){
  
  VAR(send_pending) = 0;
  VAR(state) = INACTIVE;
  VAR(numLinesWritten) = 0;
  
  TOS_CALL_COMMAND(LOG_QUERY_SUB_INIT)();

  return 1;
}

char TOS_COMMAND(LOG_QUERY_START)(){
  return 1;
}


// handles requests to read the log
TOS_MsgPtr TOS_EVENT(LOG_QUERY_MSG)(TOS_MsgPtr msg){
  log_query_msg * lqm;


  if (VAR(state) == INACTIVE) {
  CLR_GREEN_LED_PIN();
    lqm = (log_query_msg *) msg->data;
    VAR(state) = ACTIVE;
    VAR(src) = lqm->src;
    VAR(log_line) = lqm->startLineNumber;
    if(lqm->readingToEnd == 1) {
      VAR(numLines) = MAX_LINES;
    } else {
      VAR(numLines) = lqm->numLines;
    }
    CLR_YELLOW_LED_PIN();
    TOS_CALL_COMMAND(LOG_QUERY_SUB_READ_LOG)((short)VAR(log_line) + BASELINE, (char *)&(VAR(data).data[2]));
  }
  return msg;
}

TOS_MsgPtr TOS_EVENT(LOG_QUERY_RESPONSE_MSG)(TOS_MsgPtr msg){
  return msg;
}

char TOS_EVENT(LOG_QUERY_SEND_DONE)(TOS_MsgPtr data){
  if (VAR(state)==ACTIVE && data==&VAR(data)) {
    VAR(send_pending) = 0;
    VAR(numLines)--;
    TOS_CALL_COMMAND(LOG_QUERY_SUB_READ_LOG)((short)++VAR(log_line) + BASELINE, (char *)&(VAR(data).data[2]));
    CLR_YELLOW_LED_PIN();
  }
  return 1;
}

char TOS_EVENT(LOG_QUERY_READ_LOG_DONE)(char * record, char success){
  SET_YELLOW_LED_PIN();

  if (VAR(state) == ACTIVE && (VAR(log_line) <= VAR(numLinesWritten)) && VAR(send_pending)==0 && VAR(numLines) > 0) {
    VAR(data).data[0] = (char)(TOS_LOCAL_ADDRESS >> 8);
    VAR(data).data[1] = (char)(TOS_LOCAL_ADDRESS);
    TOS_CALL_COMMAND(LOG_QUERY_SUB_SEND_MSG)(VAR(src), AM_MSG(LOG_QUERY_RESPONSE_MSG), &VAR(data));
    VAR(send_pending) = 1;
  } else {
    SET_YELLOW_LED_PIN();
    VAR(state) = INACTIVE;
  }
  return 1;
}

char TOS_EVENT(LOG_QUERY_APPEND_LOG_DONE)(char success) {
  // signals a LOG_QUERY_RECORD_DONE event which is handled by the 
  // component that called LOG_QUERY_RECORD
  TOS_SIGNAL_EVENT(LOG_QUERY_RECORD_DONE)(success);
  return 1;
}

// called by other components to write to the log.  LOG_QUERY keeps track of
// the last line written to the log
char TOS_COMMAND(LOG_QUERY_RECORD)(char* data) {
  if(VAR(numLinesWritten) < MAX_LINES) {
    VAR(numLinesWritten)++;
    return TOS_CALL_COMMAND(LOG_QUERY_SUB_WRITE_LOG)((short)(VAR(numLinesWritten) + BASELINE),data);
  }
  return 0;
}


