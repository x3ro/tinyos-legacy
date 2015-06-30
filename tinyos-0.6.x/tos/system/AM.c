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


// This is an AM messaging layer implementation that understands multiple
// output devices.  For all packets addressed to TOS_UART_ADDRESS, they are 
// not sent to the UART.  Please use AM_BASE message layer if you want both
// UART and radio capability.

extern short TOS_LOCAL_ADDRESS;

#include "tos.h"
#include "AM.h"
#include "dbg.h"

#ifdef TOSSIM
#include "tossim.h"
#endif


#define TOS_FRAME_TYPE AM_obj_frame
TOS_FRAME_BEGIN(AM_obj_frame) {
  char state;
  TOS_MsgPtr msg;  
}
TOS_FRAME_END(AM_obj_frame);

// Function Decalartion
TOS_MsgPtr AM_MSG_REC(char num, TOS_MsgPtr data);


// This task schedules the transmission of the Active Message
TOS_TASK(AM_send_task)
{
  //construct the packet to be sent.
  //fill in dest and type
  if(!TOS_CALL_COMMAND(AM_SUB_TX_PACKET)(VAR(msg))){
    VAR(state) = 0;
    TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(msg));
    return;
  }
}


// Command to accept transmission of an Active Message
char TOS_COMMAND(AM_SEND_MSG)(short addr,char type, TOS_MsgPtr data){
  
  //if not idle then return error.
  if(VAR(state) == 0){
    //schedule sending task.
    TOS_POST_TASK(AM_send_task);
    //set state to waiting to send.
    VAR(state) = 1;
    //store away important information.
    
    VAR(msg) = data;
    VAR(msg)->addr = addr;
    VAR(msg)->type = type;
    VAR(msg)->group = LOCAL_GROUP & 0xff;
    
    
    /* Message debugging output */	
    {
      int i;
      dbg(DBG_AM, ("Sending message: %x, %x", addr, type));
      for(i = 0; i < defaultMsgSize(data); i ++) { 
	if (i % 9 == 0) {dbg_clear(DBG_AM, ("\n\t"));}
	dbg_clear(DBG_AM, ("%02hhx ", ((char*)data)[i]));

      }
      dbg_clear(DBG_AM, ("::%d\n", defaultMsgSize(data)));
    }
    
    return 1;
  }
  return 0;
}


// Command to be used for power managment
char TOS_COMMAND(AM_POWER)(char mode){
  TOS_CALL_COMMAND(AM_SUB_POWER)(mode);
  VAR(state) = 0;
  return 1; 
}

// Initialization of this component
char TOS_COMMAND(AM_INIT)(){
  dbg(DBG_BOOT, ("AM Module initialized\n"));
  //initialize sub components
  TOS_CALL_COMMAND(AM_SUB_INIT)();
  VAR(state) = 0;
  return 1;
}

#ifdef TOSSIM
#include "external_comm.h"
#endif

// Handle the event of the completion of a message transmission
char TOS_EVENT(AM_TX_PACKET_DONE)(TOS_MsgPtr msg){
  //return to idle state.
  VAR(state) = 0;
  //fire send done event.
#ifdef TOSSIM
    writeOutRadioPacket(tos_state.tos_time, NODE_NUM, (char*)msg, sizeof(TOS_Msg));
#endif
  TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(msg);
  return 1;
}


// Handle the event of the reception of an incoming message
TOS_MsgPtr TOS_MSG_EVENT(AM_RX_PACKET_DONE)(TOS_MsgPtr packet){
  dbg(DBG_AM, ("AM_address = %x, %x\n", packet->addr, packet->type));
  //when packet is received check if it is broadcast or addressed
  // to local address.
  if(packet->group == (LOCAL_GROUP & 0xff) && (packet->addr == (short)TOS_BCAST_ADDR || packet->addr == TOS_LOCAL_ADDRESS)){
    TOS_MsgPtr tmp;
    
    /* Message debugging output */
    {
      int i;
      dbg(DBG_AM, ("Received message:\n\t"));
      for (i = 0; i < 30; i++) {
	dbg(DBG_AM, ("%x,", ((char*)packet)[i]));
      }
      dbg(DBG_AM, ("\n"));
      dbg(DBG_AM, ("AM_type = %d\n", packet->type));
    }
    
    //send message to be dispatched.
    // invoke the corresponding handler defined by packet->type
    tmp = AM_MSG_REC(packet->type, packet);
    if(tmp != 0){
      return (TOS_MsgPtr)tmp;
    }else{
      return packet;
    }
  }
  return packet;
}

#include "AMdispatch.template"
