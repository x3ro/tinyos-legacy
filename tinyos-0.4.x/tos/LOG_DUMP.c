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
 * Authors:		Deepak Ganesan
 *
 *
 */

#include "tos.h"
#include "LOG_DUMP.h"

extern short TOS_LOCAL_ADDRESS;

/* Constants to avoid screwing up
   Network Reprogramming
   If NOT used with reprogramming
   set MAX_LINES to 2048
   and BASELINE to 0
*/
#define START_OF_LOG  1
#define MAX_LINES 1024
#define BASELINE 1024 

#define INIT 0
#define INACTIVE 1
#define ACTIVE 2

#define TOS_FRAME_TYPE LOG_DUMP_obj_frame
TOS_FRAME_BEGIN(LOG_DUMP_obj_frame) {
  TOS_Msg data;

  /* Use if used on motes with mote-id programmed into the First 16 byte
     block in the EEPROM. This would be the case with all Nework
     Reprogrammable motes
  */
  char frag_map[16];

  char send_pending;
  char state;
  unsigned int log_line;
}
TOS_FRAME_END(LOG_DUMP_obj_frame);

char TOS_COMMAND(LOG_DUMP_INIT)(){
  
  VAR(log_line) = 0;
  VAR(send_pending) = 0;
  
  TOS_CALL_COMMAND(LOG_DUMP_SUB_LOGGER_INIT)();

  /* Assumes that nodeId has been written into the first
     line of the EEPROM
     This would be true with PROG_COMM but if not true
     set VAR(state)=INACTIVE
     and comment the line after that
  */
  VAR(state) = INIT;
  TOS_CALL_COMMAND(LOG_DUMP_SUB_READ_LOG)(0, VAR(frag_map));
}
 
TOS_MsgPtr TOS_EVENT(LOG_DUMP_REPORTBACK)(TOS_MsgPtr msg){
  CLR_GREEN_LED_PIN();
  if (VAR(state) == INACTIVE) {
    VAR(state) = ACTIVE;
    VAR(log_line) = 0;
    CLR_YELLOW_LED_PIN();
    TOS_CALL_COMMAND(LOG_DUMP_SUB_READ_LOG)(VAR(log_line) + BASELINE, (char *)&(VAR(data).data[2]));
  }
  return msg;
}

char TOS_EVENT(LOG_DUMP_SEND_DONE)(TOS_MsgPtr data){
  if (VAR(state)==ACTIVE && data==&VAR(data)) {
    VAR(send_pending) = 0;
    TOS_CALL_COMMAND(LOG_DUMP_SUB_READ_LOG)(++VAR(log_line) + BASELINE, (char *)&(VAR(data).data[2]));
    CLR_YELLOW_LED_PIN();
  }
  return 1;
}

char TOS_EVENT(LOG_DUMP_READ_LOG_DONE)(char * record, char success){
  SET_YELLOW_LED_PIN();

  // Used only when first EEPROM line has the TOS_LOCAL_ADDRESS
  if (VAR(state) == INIT) {
    TOS_LOCAL_ADDRESS = VAR(frag_map)[0] & 0xff;
    TOS_LOCAL_ADDRESS |= VAR(frag_map) [1]<< 8;
    VAR(state) = INACTIVE;
    return 1;
  }

  if (VAR(state) == ACTIVE && VAR(log_line) < MAX_LINES && VAR(send_pending)==0) {
    VAR(data).data[0] = (char)(TOS_LOCAL_ADDRESS >> 8);
    VAR(data).data[1] = (char)(TOS_LOCAL_ADDRESS);
    TOS_CALL_COMMAND(LOG_DUMP_SUB_SEND_MSG)(0x7e, 12, &VAR(data));
    VAR(send_pending) = 1;
  } else {
    SET_YELLOW_LED_PIN();
    VAR(state) = INACTIVE;
    VAR(log_line) = 0;
  }
  return 1;
}


