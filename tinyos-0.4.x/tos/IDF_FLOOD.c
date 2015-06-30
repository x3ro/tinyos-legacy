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
 * Authors:		Alec Woo
 *
 * $Log: IDF_FLOOD.c,v $
 * Revision 1.5  2001/08/29 23:42:54  smadden
 * merge from IDF branch
 *
 * Revision 1.4.2.2  2001/08/23 00:25:43  alecwoo
 * Type cast the seqno evaluation to char.
 *
 * Revision 1.4.2.1  2001/08/22 06:38:48  alecwoo
 * Fixed the seqno to make it monotonically increasing.
 *
 * Revision 1.4  2001/08/20 23:35:38  alecwoo
 * Shrink the message payload to be 7 bytes.
 * Clean up the code.
 *
 * Revision 1.3  2001/08/20 08:46:14  alecwoo
 * Shrink the flood message size to deal with clock screw in the dot.
 *
 * Revision 1.2  2001/08/17 02:01:21  alecwoo
 * Seperate level between flood and command_inter.
 *
 * Revision 1.1  2001/08/17 01:06:45  alecwoo
 * Sepearte Flodding component from command interpreter component.
 *
 *
 */

 
/* This component floods the network with brute force flooding algorithm.*/

#include "tos.h"
#include "IDF_FLOOD.h"

extern short TOS_LOCAL_ADDRESS;  // This is the ID of the mote retrieved from the EEPROM

// Flood Message Structure
typedef struct {
    unsigned char hop_count;            // hop count of the source
    char seqno;       // seqneunce number
}floodmsg_t;

// Frame of the component
#define TOS_FRAME_TYPE IDF_FLOOD_obj_frame
TOS_FRAME_BEGIN(IDF_FLOOD_obj_frame) {
    TOS_Msg flood_buf;	       // flood message buffer
    TOS_MsgPtr msg;            // message ptr
    char flood_send_pending;   // flag to see if flood buffer is sending
    char lastSeqno;       // seq no
}
TOS_FRAME_END(IDF_FLOOD_obj_frame);

char TOS_COMMAND(IDF_FLOOD_INIT)(){
    //initialize sub components
    TOS_CALL_COMMAND(IDF_FLOOD_SUB_INIT)();
    
    // Initialize settings
    VAR(msg) = &VAR(flood_buf);
    VAR(flood_send_pending) = 0;
    VAR(lastSeqno)=0;
    
    return 1;
}

char TOS_COMMAND(IDF_FLOOD_START)(){
    return 1;
}

// Handler for the flooding the message.
TOS_MsgPtr TOS_MSG_EVENT(IDF_FLOOD_UPDATE)(TOS_MsgPtr msg){
    floodmsg_t * fmsg = (floodmsg_t *) msg->data;
    TOS_MsgPtr tmp;

    // If this is the new flood message
    // new if fmsg->seqno > VAR(lastSeqno)
    // new if fmsg->seqno < VAR(lastSeqno) - 4  (works for wrap around case)
    // * both variables are unsigned char
    if ( ((char)((fmsg->seqno) - VAR(lastSeqno))) > 0){
    
	// Update last sequence number
	VAR(lastSeqno) = fmsg->seqno;	   
	
	// set hop count and source of flood message
	(fmsg->hop_count)++;     

	// Signal upper level for incoming messages
	TOS_SIGNAL_EVENT(IDF_FLOOD_REC_MSG)(msg);
	
	// Start sending the flood message
	if (VAR(flood_send_pending) == 0){
	    VAR(flood_send_pending) = TOS_CALL_COMMAND(IDF_FLOOD_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(IDF_FLOOD_UPDATE),msg);
	    tmp = VAR(msg);
	    VAR(msg) = msg;
	    return tmp;
	}
    }
    
    return msg;
}


//Event: finish sending a flood message.
char TOS_EVENT(IDF_FLOOD_SEND_DONE)(TOS_MsgPtr data){
    if(data == VAR(msg)) VAR(flood_send_pending) = 0;
    return 1;
}
