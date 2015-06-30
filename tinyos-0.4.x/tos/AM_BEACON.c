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
* Authors:		Jason Hill *
 *
 */

#include "tos.h"
#include "AM_BEACON.h"


#define TOS_FRAME_TYPE AM_beacon_frame
TOS_FRAME_BEGIN(AM_beacon_frame) {
	char buf[30];
}
TOS_FRAME_END(AM_beacon_frame);

extern const char LOCAL_ADDR_BYTE_1;
extern const char TOS_LOCAL_ADDRESS;


char TOS_COMMAND(AM_BEACON_INIT)(){
	TOS_CALL_COMMAND(BEACON_SUB_INIT)();
	TOS_CALL_COMMAND(BEACON_DATA_INIT)();
 	TOS_CALL_COMMAND(BEACON_SUB_CLOCK_INIT)(0x05);
    	return 1;
}

char TOS_EVENT (BEACON_SUB_DATA_READY)(int data){
    VAR(buf)[0] = 2;
    VAR(buf)[1] = 1;
    VAR(buf)[2] = 0x7e;
    VAR(buf)[6] = (char)(data >> 8) & 0xff;
    VAR(buf)[7] = ((char)data) & 0xff;
    VAR(buf)[8] = TOS_LOCAL_ADDRESS;
    TOS_CALL_COMMAND(BEACON_SUB_SEND_MSG)(TOS_BCAST_ADDR,0x00,VAR(buf));
    return 1;
}

void TOS_EVENT (AM_BEACON_CLOCK_EVENT)(){
	 TOS_CALL_COMMAND(BEACON_SUB_READ)();
}

char TOS_EVENT (BEACON_SUB_MSG_SEND_DONE)(char success){
	TOS_CALL_COMMAND(BEACON_SUB_POWER)(0);
	return 1;
}
