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
#include "AM_LIGHT.h"
#include "dbg.h"

#define TOS_FRAME_TYPE AM_light_frame
TOS_FRAME_BEGIN(AM_light_frame) {
        short addr;
	char* buf;
	char type;
}
TOS_FRAME_END(AM_light_frame);


char TOS_COMMAND(AM_LIGHT_INIT)(){
    TOS_CALL_COMMAND(LIGHT_SUB_INIT)();
    TOS_CALL_COMMAND(LIGHT_SUB_INIT2)();
    
    dbg(DBG_BOOT, ("AM_light initialized"));
    return 1;
}

char LIGHT_SUB_DATA_READY(short data){
    VAR(buf)[26] = (data >> 8)&0xff;
    VAR(buf)[27] = data & 0xff;
    TOS_CALL_COMMAND(LIGHT_SUB_SEND_MSG)(VAR(addr),VAR(type),VAR(buf) + 2);
	return 1;
}

char AM_msg_handler_1(char* data){
    VAR(addr) = data[0];
    VAR(type) = data[1];
    VAR(buf) = data;
    TOS_CALL_COMMAND(LIGHT_SUB_GET_DATA)();

	return 1;
}
