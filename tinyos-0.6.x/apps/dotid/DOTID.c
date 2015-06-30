/* -*-Mode: C; c-file-style: "BSD" -*- 
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
 * Authors:  Sam Madden
 */

#include "tos.h"
#include "DOTID.h"

#define TOS_FRAME_TYPE DOTID_frame
TOS_FRAME_BEGIN(DOTID_frame) {
  char line[16];
  TOS_Msg msg;
}
TOS_FRAME_END(DOTID_frame);


char TOS_COMMAND(DOTID_INIT)(void) {
  short *sline = (short *)VAR(line);
  sline[0] = TOS_LOCAL_ADDRESS;

  TOS_CALL_COMMAND(DOTID_SUB_INIT)();
  TOS_CALL_COMMAND(DOTID_EEPROM_WRITE)(0, VAR(line));

  return 1;
}

char TOS_COMMAND(DOTID_START)(void) {

  return 1;
}

char TOS_EVENT(DOTID_WRITE_LOG_DONE)(char success) {
  if (success) {
    VAR(line)[0] = 0; //clear out for debugging purposes
    VAR(line)[1] = 0;
    TOS_CALL_COMMAND(DOTID_EEPROM_READ)(0, VAR(line));
    CLR_RED_LED_PIN();
  }
  return 1;
}

char TOS_EVENT(DOTID_READ_LOG_DONE)(char *data, char success) {
  if (success) {
    VAR(msg).data[0] = VAR(line)[0];
    VAR(msg).data[1] = VAR(line)[1];
    TOS_CALL_COMMAND(DOTID_SUB_SEND_MSG)(TOS_BCAST_ADDR, 100, &VAR(msg));
    CLR_YELLOW_LED_PIN();
  }
  return 1;
}

char TOS_EVENT(DOTID_MSG_SENT)(TOS_MsgPtr msg) {
  return 1;
}
