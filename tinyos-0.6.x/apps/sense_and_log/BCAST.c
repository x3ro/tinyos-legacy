/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
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
 * Authors:		Alec Woo, David Culler, Robert Szewczyk
 *
 *
 *
 */

 
/* This component floods the network with brute force flooding algorithm.*/

#include "tos.h"
#include "BCAST.h"

// Bcast Message Structure
typedef struct {
    char seqno;            // hop count of the source
}bcastmsg_t;

// Frame of the component
#define TOS_FRAME_TYPE BCAST_obj_frame
TOS_FRAME_BEGIN(BCAST_obj_frame) {
    TOS_Msg bcast_buf;	       // bcast message buffer
    TOS_MsgPtr msg;            // message ptr
    char bcast_pending;   // flag to see if bcast buffer is sending,
    char lastSeqno;       // seq no
}
TOS_FRAME_END(BCAST_obj_frame);

char TOS_COMMAND(BCAST_INIT)(){
    // Initialize settings
    VAR(msg) = &VAR(bcast_buf);
    VAR(bcast_pending) = 0;
    VAR(lastSeqno)=0;
    
    return 1;
}

char TOS_COMMAND(BCAST_START)(){
    return 1;
}

// Decision whether the message is new: it has to be within 127 sequence
// numbers of the last number. We'll also throw out the message if we're still
// dealing with the previous broadcast. 
inline char is_new_msg(bcastmsg_t *bmsg) {
    return ((((bmsg->seqno) - VAR(lastSeqno)) > 0) && 
	    (VAR(bcast_pending) == 0));
}

inline void remember_msg(bcastmsg_t *bmsg) {
    // Update last sequence number
    VAR(lastSeqno) = bmsg->seqno;
    // lock down the BCAST system. This will keep the system from accepting
    // another bcast message until we finish with executing the command in the
    // message, and forward the message onward. 
    VAR(bcast_pending) = 1; 
}


// Handler for the flooding the message.
TOS_MsgPtr TOS_MSG_EVENT(BCAST_UPDATE)(TOS_MsgPtr msg) {
    bcastmsg_t * bmsg = (bcastmsg_t *) msg->data;
    TOS_MsgPtr tmp = msg;
    
    // Check if this is a new broadcast message
    if (is_new_msg(bmsg)) {
	remember_msg(bmsg);
	
	// Execute the split-phase command handler for the message.  If the
	// command handler failed, just drop the message, and forget that the
	// message was pending
	if (TOS_CALL_COMMAND(BCAST_CMD_EXEC)(msg) == 0) {
		VAR(bcast_pending) = 0;
	}

	// Return a message buffer to the lower levels, and hold on to the
	// current buffer
	tmp = VAR(msg); VAR(msg) = msg;
    }
    return tmp;
}

TOS_TASK(forwarder) {
    VAR(bcast_pending) = TOS_CALL_COMMAND(BCAST_SUB_SEND_MSG)(TOS_BCAST_ADDR,
							      AM_MSG(BCAST_UPDATE), 
							      VAR(msg));
    // This version of BCAST will attempt to transmit the message only once,
    // but if it was desired to retry the transmission, we could simply
    // reschedule the task in here. 
}
							      

//Event: command interpreter has finished execution, now, forward the
//message. By forwarding the message from within a task, it will be easier to
//reschedule the message for potential retransmissions. 
char TOS_EVENT(BCAST_CMD_DONE) (TOS_MsgPtr msg, char status) {
    VAR(msg) = msg;
    if (status) {
	TOS_POST_TASK(forwarder);
    } else {
	VAR(bcast_pending) = 0;
    }
    return 0;
}

//Event: finish sending a bcast message.
char TOS_EVENT(BCAST_SEND_DONE)(TOS_MsgPtr data){
    if(data == VAR(msg)) VAR(bcast_pending) = 0;
    return 1;
}
