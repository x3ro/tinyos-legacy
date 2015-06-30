/*
 * @(#)COMMAND.c
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
 * Author:  Robert Szewczyk
 *
 * This component demonstrates a simple message interpreter. The component is
 * accessed through the command interface; when the command is finished
 * executing, the component signals the upper layers with the message buffer
 * and the status indicating whether the message should be further processed. 
 * 
 * $\Id$
 */

#include "tos.h"
#include "COMMAND.h"


// Command Message structure. We anticipate that many commands will find it
// useful to know who forwarded the current packet, how deep the current node
// is in the broadcast tree, etc. 

typedef struct {
    char seqno;
    char action;
    short source;
    unsigned char hop_count;
    char arg[0];
} cmdmsg_t;    


#define LED_ON        1
#define LED_OFF       2
#define RADIO_QUIETER 3
#define RADIO_LOUDER  4
#define SOUNDER_ON    7
#define SOUNDER_OFF   8
// Since the commands operate on messages, and are executed within a task, the
// local state needs to hold on to the message pointer.

#define TOS_FRAME_TYPE COMMAND_obj_frame
TOS_FRAME_BEGIN(COMMAND_obj_frame) {
    TOS_MsgPtr msg;	       
    char pending;
    TOS_Msg buf;
}
TOS_FRAME_END(COMMAND_obj_frame);


// Task for evaluating the command. The protocol for the command interpreter
// is that it operates on the message and returns a (potentially modified)
// message to the calling layer, as well a status word for whether the message
// should be futher processed. 
TOS_TASK(eval_cmd) {
    cmdmsg_t * cmd = (cmdmsg_t *) VAR(msg)->data;
    // do local packet modifications: update the hop count and packet source
    cmd->hop_count++;
    cmd->source = TOS_LOCAL_ADDRESS;
    
    // Interpret the command: Display the level on red and green led
    if (cmd->hop_count & 0x1)  
	TOS_CALL_COMMAND(COMMAND_GREEN_LED_ON)();
    else 
	TOS_CALL_COMMAND(COMMAND_GREEN_LED_OFF)();
    if (cmd->hop_count & 0x2) 
	TOS_CALL_COMMAND(COMMAND_RED_LED_ON)();
    else 
	TOS_CALL_COMMAND(COMMAND_RED_LED_OFF)();
    // Execute the command

    switch (cmd->action) {
    case LED_ON:
	TOS_CALL_COMMAND(COMMAND_YELLOW_LED_ON)();
	break;
    case LED_OFF:
	TOS_CALL_COMMAND(COMMAND_YELLOW_LED_OFF)();
	break;
    case RADIO_QUIETER:
	TOS_CALL_COMMAND(COMMAND_POT_INC)();
	break;
    case RADIO_LOUDER:
	TOS_CALL_COMMAND(COMMAND_POT_DEC)();
	break;
    }
    VAR(pending) = 0;
    TOS_SIGNAL_EVENT(COMMAND_DONE)(VAR(msg), 1);
}

char TOS_COMMAND(COMMAND_INIT) () {
    VAR(msg) = &(VAR(buf));
    VAR(pending) = 0;
    return 1;
}


char TOS_COMMAND(COMMAND_START)(){
    return 1;
}

char TOS_COMMAND(COMMAND_EXECUTE)(TOS_MsgPtr msg) {
    if (VAR(pending)) {
	return 0;
    }
    VAR(pending) = 1;
    VAR(msg) = msg;
    TOS_POST_TASK(eval_cmd);
    return 1;
}
TOS_MsgPtr TOS_MSG_EVENT(COMMAND_MSG)(TOS_MsgPtr msg) {
    TOS_MsgPtr ret = VAR(msg);
    if (TOS_CALL_COMMAND(COMMAND_EXECUTE)(msg)) {
	return ret;
    } else {
	return msg;
    }
}

//Dummy handlers necessary to make the component self contatained.
char TOS_EVENT(COMMAND_CMD_DONE) (TOS_MsgPtr msg, char status) {
    return 0;
} 

char TOS_EVENT(COMMAND_SEND_DONE)(TOS_MsgPtr data){
    return 1;

}
