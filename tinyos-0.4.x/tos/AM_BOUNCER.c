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
 * Authors:		Jason Hill
 *
 *
 */

#include "tos.h"
#include "AM_BOUNCER.h"

#define TOS_FRAME_TYPE AM_BOUNCER_OBJ
TOS_FRAME_BEGIN(AM_BOUNCER_OBJ) {
	TOS_Msg buf;
	TOS_MsgPtr msg;
}   
TOS_FRAME_END(AM_BOUNCER_OBJ);



char TOS_COMMAND(AM_BOUNCER_INIT)(){
  VAR(msg) = &VAR(buf);
  TOS_CALL_COMMAND(BOUNCER_SUB_INIT)();
  return 1;
}

extern const char TOS_LOCAL_ADDRESS;

TOS_MsgPtr TOS_MSG_EVENT(AM_BOUNCE_MSG)(TOS_MsgPtr msg){
  TOS_MsgPtr hold = VAR(msg);
  char* data = msg->data;
  char RtCount = ((unsigned char)data[0] >> 4) & 0xf;
  char Handler = 0;
  char tmp;
  VAR(msg) = msg;
  printf("got bouncer object\n");
  data[0] = RtCount;
  data[1] = data[7];

  if (RtCount > 1) {
    tmp = data[2];
    data[2] = data[4];
    data[4] = tmp;
    tmp = data[5];
    data[(int)(RtCount)] = data[6];
  }
  else {
    tmp = data[6];
    Handler = data[7];
  } 
   data[6] = TOS_LOCAL_ADDRESS;
   printf("%x, %x, %x\n", data[0], data[1], data[5]);
   TOS_CALL_COMMAND(BOUNCER_SUB_SEND_MSG)(tmp,Handler,msg);
   return hold;
}
