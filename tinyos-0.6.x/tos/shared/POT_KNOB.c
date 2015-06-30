/*									tab:4
 * POT_KNOB.c
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
 * Authors:   Solomon Bien
 * History:   created 8/14/2001
 *
 *
 * This component contains AM handlers to manipulate the potentiometer setting
 * It uses AM Handler # 98
 * 
 */

#include "tos.h"
#include "POT_KNOB.h"

typedef struct{
  char isAbsolute;  /* 1 if absolute setting, 0 if relative setting */
  char sign;        /* 1 for a positive value, 0 for a negative value */
  char pot_setting; /* absolute setting or relative offset of setting */
} pot_knob_msg;


#define TOS_FRAME_TYPE POT_KNOB_frame
TOS_FRAME_BEGIN(POT_KNOB_frame) {
  char pending;
  TOS_Msg data; 
}
TOS_FRAME_END(POT_KNOB_frame);


char TOS_COMMAND(POT_KNOB_INIT)(){
  TOS_CALL_COMMAND(POT_KNOB_SUB_INIT)();
  return 1;
}

char TOS_COMMAND(POT_KNOB_START)(){
  return 1;
}


char TOS_EVENT(POT_KNOB_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg) {
  if (VAR(pending) && msg == &VAR(data)) {
    VAR(pending) = 0;
    return 1;
  }
  return 0;
}


TOS_MsgPtr TOS_MSG_EVENT(SET_POT_MSG)(TOS_MsgPtr msg){
  pot_knob_msg * t;
  int i;
  
  t = (pot_knob_msg *) msg->data;
  
  if(t->isAbsolute) {
#ifdef RENE
    TOS_CALL_COMMAND(POT_KNOB_POT_SET)(t->pot_setting);    
#endif
  } else {
    for(i = 0; i < t->pot_setting; i++) {
      if(t->sign) {
#ifdef RENE
	TOS_CALL_COMMAND(POT_KNOB_POT_INC)();
#endif
      } else {
#ifdef RENE
	TOS_CALL_COMMAND(POT_KNOB_POT_DEC)();
#endif
      }
    }
  }
  return msg;
}


