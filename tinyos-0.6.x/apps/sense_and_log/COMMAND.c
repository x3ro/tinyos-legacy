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

// packet formats used by the component: depending on the command, we expect
// different argument structures.

typedef struct {
    short nsamples;
    char scale;
    char nticks;
} start_sense_args;

typedef struct {
    short address;
    short logLine;
} read_log_args;

typedef struct {
    char seqno;
    char action;
    short source;
    unsigned char hop_count;
    union {
	start_sense_args ss_args;
	read_log_args rl_args;
	char untyped_args[0];
    } args;
} cmdmsg_t;  

  
// Log message structure

typedef struct {
    short source; 
    short address;
    char log[16];
    unsigned hop_count;
} logmsg_t;

// Action constants

#define LED_ON        1
#define LED_OFF       2
#define RADIO_QUIETER 3
#define RADIO_LOUDER  4
#define START_SENSING 5
#define READ_LOG      6

// Communication with the broadcast component
#define BCAST_PRUNE   0
#define BCAST_FORWARD 1

// Since the commands operate on messages, and are executed within a task, the
// local state needs to hold on to the message pointer. We also keep track of
// the "parent" in the multihop tree. Additionally, since this component sends
// out the log readings, we need to allocate a message buffer, and a flag
// indicating whether the message system is busy.

#define TOS_FRAME_TYPE COMMAND_obj_frame
TOS_FRAME_BEGIN(COMMAND_obj_frame) {
    TOS_MsgPtr msg;
    TOS_Msg log_msg;
    short parent;
    char send_pending;
    char pending;
}
TOS_FRAME_END(COMMAND_obj_frame);

//Initialization command. 

char TOS_COMMAND(COMMAND_INIT) () {
    VAR(pending) = 0;
    VAR(send_pending) = 0; 
    return 1;
}


// Task for evaluating the command. The protocol for the command interpreter
// is that it operates on the message and returns a (potentially modified)
// message to the calling layer, as well a status word for whether the message
// should be futher processed. 
TOS_TASK(eval_cmd) {
    cmdmsg_t * cmd = (cmdmsg_t *) VAR(msg)->data;
    char status = BCAST_FORWARD;
    // do local packet modifications: update the hop count and packet source
    cmd->hop_count++;
    VAR(parent) = cmd->source;
    cmd->source = TOS_LOCAL_ADDRESS;

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
    case START_SENSING:
	// Initialize the sensing component, and start reading data from it. 
	TOS_CALL_COMMAND(COMMAND_SENSE_INIT)();
	TOS_CALL_COMMAND(COMMAND_START_SENSING) 
	    (cmd->args.ss_args.nsamples, 
	     cmd->args.ss_args.nticks,
	     cmd->args.ss_args.scale);
	break;
    case READ_LOG:
	//Check if the message is meant for us, if so issue a split phase call
	//to the logger
	if ((cmd->args.rl_args.address == TOS_LOCAL_ADDRESS) &&
	    (VAR(send_pending) == 0)) {
	    if (TOS_CALL_COMMAND(COMMAND_READ_LOG)
		((short)(cmd->args.rl_args.logLine), 
		 ((logmsg_t*) VAR(log_msg).data)->log)) {
		VAR(pending) ++;
	    }
	    status = BCAST_PRUNE;
	}
	break;
    }
    VAR(pending) --;
    TOS_SIGNAL_EVENT(COMMAND_DONE)(VAR(msg), status);
}


// Command to schedule the eval_task
char TOS_COMMAND(COMMAND_EXECUTE)(TOS_MsgPtr msg) {
    if (VAR(pending)) {
	return 0;
    }
    VAR(pending) = 1;
    VAR(msg) = msg;
    TOS_POST_TASK(eval_cmd);
    return 1;
}

// The log has completed the reading, and now we're ready to send out this
// message. Note a potential problem: what is send_pending set to? 

char TOS_EVENT(COMMAND_READ_LOG_DONE)(char* packet, char success) {
    if (success) {
	VAR(pending) = 0;
	VAR(send_pending) = TOS_CALL_COMMAND(COMMAND_SUB_SEND_MSG)
	    (VAR(parent), AM_MSG(LOG_MSG), &VAR(log_msg));
    }
    return 1;
}

// Routing handler for the LOG_MSG. The default handler is very simple: we
// copy the data out of the packet into the log buffer, and forward it to the
// parent. Exercise to the reader: what are the rece conditions in routing and
// how can they be fixed? 

TOS_MsgPtr TOS_MSG_EVENT(LOG_MSG)(TOS_MsgPtr msg) {
    char i;
    char *ptr1, *ptr2;
    if (VAR(send_pending) == 0) {
	VAR(send_pending) = 1;
	ptr1 = (char *) &(VAR(log_msg));
	ptr2 = (char *) msg;
	for (i =0; i < defaultMsgSize(msg); i++) {
	    *ptr1++ = *ptr2++;
	}
	if (TOS_CALL_COMMAND(COMMAND_SUB_SEND_MSG)
	    (VAR(parent), AM_MSG(LOG_MSG), &VAR(log_msg)) == 0) {
	    VAR(send_pending) = 0;
	}

    }
    return msg;
}

//Event: finish sending a log message.
char TOS_EVENT(COMMAND_SEND_DONE)(TOS_MsgPtr data){
    if(data == &VAR(log_msg)) 
	VAR(send_pending) = 0;
    return 1;
}
