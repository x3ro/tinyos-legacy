/*									tab:4
 * MOTEINFO.c
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


 C file for component which broadcasts indentifying information about motes
 over the radio.  This information consists of the following:
 
 - ID : A single character ID for this mote;  used to differentiate this mote from other motes
 - VERSION : A foure byte version code identifying the software revision running on this mote.
             Includes two project id bytes plus two version bytes.  Project id bytes identify
	     the type of project (e.g. TEMPERATURE_SENSOR) version bytes the revision number
	     e.g "1.2";
 - SCHEMA : A single character used to identify which sensor readings are available on this
 mote. See Schema.h for routines to parse this code.
 
 Authors:  Sam Madden
 Date: 6/8/01
*/

#include "tos.h"
#include "MOTEINFO.h"

#include "MoteInfoStructs.h"
#include "version.h"

#include "moteschema.h"

#define SCHEMA_BYTE 0x01
#define VERSION_BYTE 0x02
#define ID_BYTE 0x03

/* Utility functions */

#define TOS_FRAME_TYPE MOTEINFO_frame

TOS_FRAME_BEGIN(MOTEINFO_frame) {
  char pending;  /* is something being xmitted */
  char pending_schema;
  char cur_schema;

  TOS_Msg msg_data;
}
TOS_FRAME_END(MOTEINFO_frame);

char TOS_COMMAND(MOTEINFO_INIT)(){
  TOS_CALL_COMMAND(MOTEINFO_SUB_INIT)();
  printf("MOTEINFO initialized\n");
  VAR(pending) = 0;
  VAR(pending_schema) = 0;
  return 1;
}

char TOS_COMMAND(MOTEINFO_START)(){
  return 1;
}

/* Broadcast schema information for this mote */
char TOS_COMMAND(SCHEMA_OUTPUT)(){
	schema_msg* message = (schema_msg*)VAR(msg_data).data;
	if (!VAR(pending_schema)) {
	  message->src = TOS_LOCAL_ADDRESS;
	  message->count = gMoteSchema.cnt;
	  message->index = VAR(cur_schema);
	  message->schema = gMoteSchema.fields[VAR(cur_schema)];
	  
	  if (TOS_COMMAND(MOTEINFO_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(SCHEMA_READING), &VAR(msg_data))) {
	    VAR(pending_schema) = 1;
	    return 1;
	  }
	}
	return 0;
}

/* Broadcast version information for this mote */
char TOS_COMMAND(VERSION_OUTPUT)(){
	version_msg* message = (version_msg*)VAR(msg_data).data;
	if (!VAR(pending)) {
	  message->vers_project = kVERS_PROJECT;
	  message->vers_major = kVERS_MAJOR;
	  message->vers_minor = kVERS_MINOR;
	  message->src = TOS_LOCAL_ADDRESS;
	  if (TOS_COMMAND(MOTEINFO_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(VERSION_READING), &VAR(msg_data))) {
	    VAR(pending) = 1;
	    return 1;
	  }
	}
	return 0;
}

/* Broadcast id for this mote */
char TOS_COMMAND(ID_OUTPUT)(){
	id_msg* message = (id_msg*)VAR(msg_data).data;
	if (!VAR(pending)) {
	  message->val = ID_BYTE;
	  message->src = TOS_LOCAL_ADDRESS;
	  if (TOS_COMMAND(MOTEINFO_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(ID_READING), &VAR(msg_data))) {
	    VAR(pending) = 1;
	    return 1;
	  }
	}
	return 0;
}


/* Send completion event
   Determine if this event was ours.
   If so, process it by freeing output buffer and signalling event.

*/
char TOS_EVENT(MOTEINFO_SUB_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer){
  if (VAR(pending_schema) && sentBuffer == &VAR(msg_data)) {
    VAR(pending_schema) = 0;
    VAR(cur_schema) = VAR(cur_schema) + 1;
    if (VAR(cur_schema) < gMoteSchema.cnt)
      TOS_COMMAND(SCHEMA_OUTPUT)(); //send the next schema message
    //    TOS_SIGNAL_EVENT(SCHEMA_TO_RFM_COMPLETE)(1);
    return 1;
  } else
  if (VAR(pending) && sentBuffer == &VAR(msg_data)) {
    VAR(pending) = 0;
    //    TOS_SIGNAL_EVENT(ID_TO_RFM_COMPLETE)(1);
    return 1;
  }

  return 0;
}

/* Active Message handler
 */

TOS_MsgPtr TOS_MSG_EVENT(SCHEMA_READING)(TOS_MsgPtr val){
  return val;
}


TOS_MsgPtr TOS_MSG_EVENT(ID_READING)(TOS_MsgPtr val){
  return val;
}


TOS_MsgPtr TOS_MSG_EVENT(VERSION_READING)(TOS_MsgPtr val){
  return val;
}


/* Active message handler to request information about this mote
   be broadcast out to the world.
   Requires:  TOS_MsgPtr->data contains an info_request_msg
              info_request_msg is one of :
	        kSCHEMA_REQUEST
		KID_REQUEST
		kVERSION_REQUEST
   Effects:   Broadcasts the requested information via the 
              appropriate active message handler.
*/
TOS_MsgPtr TOS_MSG_EVENT(INFO_REQUEST_READING)(TOS_MsgPtr msg) {

  info_request_msg* message = (info_request_msg *)msg->data;
  printf ("in info_request_reading\n");
  switch (message->type) {
  case (kSCHEMA_REQUEST) :
    printf ("schema request\n");
    VAR(cur_schema) = 0;
    TOS_COMMAND(SCHEMA_OUTPUT)();
    break;
  case (kID_REQUEST) :
    printf ("id request\n");
    TOS_COMMAND(ID_OUTPUT)();
    break;
  case (kVERSION_REQUEST) :  
    printf ("version request\n");
    TOS_COMMAND(VERSION_OUTPUT)();
    break;
  }
  return msg;
}





