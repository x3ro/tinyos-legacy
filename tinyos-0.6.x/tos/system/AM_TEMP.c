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

//this component will respond to messages asking for the temperature value.


#include "tos.h"
#include "dbg.h"

#include "Photo.h"
#include "mote.h"
#include "super.h"
#include "AM.h"
#include "Temp.h"

#define TOS_FRAME_TYPE AM_temp_frame
TOS_FRAME_BEGIN(AM_temp_frame) {
    short addr;;
    char buf[26];
}
TOS_FRAME_END(AM_temp_frame);


char TOS_COMMAND(AM_temp_init)(){
    
    //initialize sub compoennts.
    TOS_CALL_COMMAND(TEMP_SUB_init)();
    TOS_CALL_COMMAND(TEMP_SUB_init2)();
    dbg(DBG_BOOT, ("AM_temp initialized"));
    return 1;
}

char TOS_EVENT (TEMP_SUB_data_ready)(char data){
    //when the data value comes back...
    //place the data value into the buffer.
    VAR(buf)[0] = data;
    //send out the data.
    TOS_CALL_COMMAND(TEMP_SUB_send_msg)(VAR(addr),4,VAR(buf));
    return 1;
}

char TOS_MSG_EVENT(AM_msg_handler_3)(char* data){
    //when you receive a request, store the information needed to 
    //reply and request the temp to be read.
    VAR(addr) = data[0] << 8 | ((int)data[1] & 0xff);
    TOS_CALL_COMMAND(TEMP_SUB_get_data)();
    return 1;
}
