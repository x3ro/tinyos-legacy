/*									tab:2
 *  ===================================================================================
 *
 *  IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  
 *  By downloading, copying, installing or using the software you agree to this license.
 *  If you do not agree to this license, do not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met: 
 * 
 *	Redistributions of source code must retain the above copyright notice, this 
 *  list of conditions and the following disclaimer. 
 *	Redistributions in binary form must reproduce the above copyright notice, this
 *  list of conditions and the following disclaimer in the documentation and/or other 
 *  materials provided with the distribution. 
 *	Neither the name of the Intel Corporation nor the names of its contributors may 
 *  be used to endorse or promote products derived from this software without specific 
 *  prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *  IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
 *  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
 *  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 *  POSSIBILITY OF SUCH DAMAGE.
 * 
 * ====================================================================================
 *
 * Authors:		Su Ping <su.ping@intel.com
 *				Intel Research Berkeley Lab
 * Date:        5/30/2002
 *
 * The time sync module handles STSP request and response, adjust 
 * locol clock to synchronize with a STSP server upon the reception
 * of a STSP response. Round_trip time estimation is also implemented
 * uing STSP ECHO REQUEST and RESPONSE  Upon receiving the expected 
 * STSP ECHO RESPONSE, a mote immediately obtains an arrival time stamp.
 * Round trip time is calculated by comparing the 
 * arrival time stamp of a STSP ECHO RESPONSE msg with the original
 * time stamp. 
 * 
 * Clock over flow interrupt is used as a timer.
 * Every 3.9 min a STSP response is broascasted from root time server.
 * This implementation is not meant for multihop network 
 *
 */


#include "tos.h"
#include "stsp_msg.h"
#include "STSP.h"
#include "dbg.h"
#include "sensorboard.h"
#include <string.h>

extern short TOS_LOCAL_ADDRESS;
//#define STSP_SERVER 1

#define TOS_FRAME_TYPE STSP_obj_frame
TOS_FRAME_BEGIN(STSP_obj_frame) {
  TOS_Msg buffer;	    // A packet buffer we hand around
  char send_pending;
  char offset_pending;  // indicate that we are waiting for a echo response
						// in order to calculate RTT 
  short offset_pending_src; // from which mote we expect the echo response 
#ifdef STSP_SERVER
  char int_cnt;		    // count the number of CLOCK interrupt
  char interval;        // 50 interrupt make 3.9 sec when prescale is 1	
#endif
  char status; 
  char  type;
  short sequence;
  short sender;         // this field holds the dest address we send msg to
  short sender_seq;     
  short sender_offset;
  short sender_stampH;
  char  sender_stampL;
}

TOS_FRAME_END(STSP_obj_frame);

char TOS_COMMAND(STSP_INIT)() {
  int i;
  char* ptr;

  dbg(DBG_BOOT, ("STSP initialized.\n"));
  
  ptr = (char*)&VAR(buffer);;
  memcpy(ptr, "test", 4);
  for (i = 0; i < sizeof(TOS_Msg); i++) {
    ptr[i] = 0;
  }
#ifdef STSP_SERVER
  VAR(status)=0x0;
  VAR(interval) = 10;
  VAR(int_cnt)=0;
#else
  VAR(status)=0xff; // client 
#endif
  VAR(sequence)=0;
  VAR(send_pending) = 0;
  TOS_CALL_COMMAND(STSP_SUB_INIT)();
  TOS_CALL_COMMAND(STSP_CLOCK_INIT)(0x1, 0x3);
  TOS_CALL_COMMAND(STSP_LED_INIT)();
  TOS_CALL_COMMAND(STSP_RED_TOGGLE)();
  return 1;
}

char TOS_COMMAND(STSP_START)() {
   return 1;
}


/* my new clock1 module does not signal CLOCK_FIRE_EVENT
void TOS_EVENT(STSP_CLOCK_EVENT)() {
	// No op 
}
*/

TOS_TASK(send) {
  char timeL;
  short timeH;

  stsp_msg * msg = (stsp_msg*)&(VAR(buffer).data);
  if  (VAR(send_pending)) return ;
  else VAR(send_pending) =1;
  msg->source_addr = TOS_LOCAL_ADDRESS;
  msg->dest_addr = VAR(sender);
  msg->subticks =0;
  msg->offset=VAR(sender_offset);
  msg->type = VAR(type);
  msg->sequence = VAR(sender_seq);
  
  if ((VAR(type)== STSP_RESPONSE)||(VAR(type)==STSP_ECHO_REQUEST)) {
    TOS_CALL_COMMAND(STSP_SUB_GET_TIME)(&timeL, &timeH);
TOS_CALL_COMMAND(STSP_GREEN_TOGGLE)();
    msg->timestampL = timeL;
    msg->timestampH = timeH;
	msg->status = VAR(status);
	msg->sequence = VAR(sequence);
	VAR(sequence)++;
  } else {
	  msg->timestampL = VAR(sender_stampL);
	  msg->timestampH = VAR(sender_stampH);
	  msg->sequence= VAR(sender_seq);
  }

  TOS_CALL_COMMAND(STSP_SUB_SEND_MSG)(msg->dest_addr, STSP_TYPE, &VAR(buffer));
TOS_CALL_COMMAND(STSP_YELLOW_TOGGLE)();
}

TOS_MsgPtr TOS_EVENT(STSP_MSG)(TOS_MsgPtr data) {
  char tempL, diffL;
  char tempH, diffH ;
  stsp_msg* msg = (stsp_msg*)(data->data);

  dbg(DBG_ROUTE, ("STSP: received  message from %i\n", (int)msg->source_addr));

  if (msg->dest_addr != TOS_LOCAL_ADDRESS &&
      msg->dest_addr != (short) 0xffff) {
    dbg(DBG_ROUTE, ("STSP: received  message from %i\n", (int)msg->source_addr));
 
    // Do nothing
	return data;
  }
  TOS_CALL_COMMAND(STSP_YELLOW_TOGGLE)();
  // save sender info
  VAR(sender) = msg->source_addr;
  VAR(sender_seq) = msg->sequence;
  VAR(sender_stampL)= msg->timestampL;
  VAR(sender_stampH)= msg->timestampH;
  switch (msg->type ) {
  case STSP_RESPONSE:
	  // STSP response received 
	  // if we are waiting for a ECHO response ignore this msg
	  if (!VAR(offset_pending)) {
		  if (msg->status <= VAR(status))  {
			  // if the msg is from a mote closer to root server
		      // set our clock
		      if ( msg->offset ==0 ) {
			      // if we are waiting for a ECHO response ignore this msg			  
			      TOS_CALL_COMMAND(STSP_SUB_SET_TIME)(msg->timestampL, msg->timestampH);
			      VAR(offset_pending) =1;
			      VAR(offset_pending_src)= msg->source_addr;
				  VAR(type)=STSP_ECHO_REQUEST;
			      TOS_POST_TASK(send);
			  } 
		  }
		  else {
			  TOS_CALL_COMMAND(STSP_GREEN_TOGGLE)();
			  // adjust the time using offset
			  tempL = msg->timestampL + (msg->offset&0xff); 
			  tempH = msg->timestampH + (msg->offset>>8);
			  TOS_CALL_COMMAND(STSP_SUB_SET_TIME)(tempL, tempH);
		  }
	  }
	  break;
  case STSP_REQUEST:
	  // if we are not a client and status lower than the msg sender
	  // response to the sender
	  if ( (msg->status > VAR(status)) && (VAR(status)<0xf )) {
		VAR(type)= STSP_RESPONSE ;
		TOS_POST_TASK(send);
	  }
	  break;
  case STSP_ECHO_REQUEST:
	  VAR(type)= STSP_ECHO_RESPONSE ;
	  TOS_POST_TASK(send);
	  break;
  case STSP_ECHO_RESPONSE:
	  if (VAR(offset_pending) && VAR(offset_pending_src)== msg->source_addr){
		  // get our current time;
		  TOS_CALL_COMMAND(STSP_SUB_GET_TIME)(&tempL, &tempH);
		  // calculate RTT
		  diffH = tempH - msg->timestampH;
		  diffL = tempL - msg->timestampL;
		  diffH/=2;
		  diffL/=2;
		  
	      // set our time
		  TOS_CALL_COMMAND(STSP_SUB_SET_TIME)(tempL+diffL, tempH+diffH);
	  }
	  break;
  }
  
  return data;
}



char TOS_EVENT(STSP_SEND_DONE)(TOS_MsgPtr data) {
  VAR(send_pending) = 0;
  TOS_CALL_COMMAND(STSP_RED_TOGGLE)();
  return 1;
}
void TOS_EVENT(STSP_CLOCK_OVERFLOW)() {
#ifdef STSP_SERVER
	if (++VAR(int_cnt)==VAR(interval)) {
//TOS_CALL_COMMAND(STSP_YELLOW_TOGGLE)();
		//	create a task to handle STSP 
		VAR(type) = STSP_RESPONSE;
		VAR(sender) = 0xffff;
		TOS_POST_TASK(send);
	}
#endif
}


