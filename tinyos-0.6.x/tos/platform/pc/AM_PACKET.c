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
 * Authors:		Jason Hill, Philip Levis
 *
 *
 */

//This is an AM messaging layer implementation that understands multiple
// output devices.  All packets addressed to TOS_UART_ADDR are sent to the UART
// instead of the radio.

extern short TOS_LOCAL_ADDRESS;

#include "tos.h"
#include "AM_PACKET.h"
#include "dbg.h"

#define TOS_FRAME_TYPE AM_obj_frame
TOS_FRAME_BEGIN(AM_obj_frame) {
  short addr;
  char type;
  char state;
  char group;
  char timeout;
  TOS_Msg msg;
  TOS_MsgPtr msg_ptr;
  AMBuffer buffer;
  AMBuffer_ptr buffer_ptr;
}
TOS_FRAME_END(AM_obj_frame);

static inline AMBuffer_ptr TOS_EVENT(AM_PACKET_NULL_FUNC)(AMBuffer_ptr data){return data;} /* Signal data event to upper comp */
AMBuffer_ptr AM_MSG_REC(char num, AMBuffer_ptr data);


static inline char am_header_pass(TOS_MsgPtr msg) {
  if (msg->addr != TOS_LOCAL_ADDRESS && msg->addr != (short)TOS_BCAST_ADDR) {return 0;}
  if (msg->group != LOCAL_GROUP && msg->group != TOS_BCAST_GROUP) {return 0;}
  return 1;
}

// This task schedules the transmission of the Active Message
TOS_TASK(AM_send_task)
{
  if(VAR(msg_ptr)->addr == TOS_UART_ADDR){
    if(!TOS_CALL_COMMAND(AM_UART_SUB_TX_PACKET)(VAR(msg_ptr))){
      TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(buffer_ptr));
      VAR(state) = 0;
      return;
    }
  }else{
    if(!TOS_CALL_COMMAND(AM_SUB_TX_PACKET)(VAR(msg_ptr))){
      TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(buffer_ptr));
      VAR(state) = 0;
      return;
    }
  }
}

// Command to accept transmission of an Active Message
char TOS_COMMAND(AM_SEND_MSG)(short addr,char type, AMBuffer_ptr data, char len){
  {
    int i;
    dbg(DBG_AM, ("Sending message: %hx, %hhx\n\t", addr, type));
    for(i = 0; i < sizeof(TOS_Msg); i++) {
      dbg_clear(DBG_AM, ("%02hhx ", ((char*)data)[i]));
    }
    dbg(DBG_AM, ("\n"));
  }
  if(VAR(state) == 0){
    VAR(msg_ptr) = &VAR(msg);
    VAR(buffer_ptr) = data;
    
    data->msg.hdr.dest = addr;
    data->msg.hdr.src = TOS_LOCAL_ADDRESS;
    data->msg.hdr.type = type;
    data->msg.hdr.group = LOCAL_GROUP & 0xff;

    VAR(msg).addr = data->msg.hdr.dest;
    VAR(msg).type = data->msg.hdr.type;
    VAR(msg).group = data->msg.hdr.group;
    memcpy(VAR(msg).data, data->msg.data - 4, DATA_LENGTH + 2);
    
    TOS_POST_TASK(AM_send_task);
    VAR(state) = 1;
    return 1;
  }
  return 0;
}

char TOS_COMMAND(AM_SEND_MSG_FINITE)(short addr,char type, AMBuffer_ptr data, char len, char timeout){
  return TOS_CALL_COMMAND(AM_SEND_MSG)(addr, type, data, len);
}

// Command to be used for power managment
char TOS_COMMAND(AM_POWER)(char mode){
  TOS_CALL_COMMAND(AM_SUB_POWER)(mode);
  TOS_CALL_COMMAND(AM_UART_SUB_POWER)(mode);
  return 1;
}

char TOS_EVENT(AM_SUB_TX_TIMEOUT)(TOS_MsgPtr msg) {
  TOS_SIGNAL_EVENT(AM_MSG_SEND_TIMEOUT)(VAR(buffer_ptr));
  return 1;
}

// Initialization of this component
char TOS_COMMAND(AM_INIT)(){

  TOS_CALL_COMMAND(AM_SUB_INIT)();
  TOS_CALL_COMMAND(AM_UART_SUB_INIT)();
  VAR(state) = 0;
  VAR(group) = LOCAL_GROUP;
  VAR(buffer_ptr) = &VAR(buffer);
  dbg(DBG_BOOT, ("AM Module initialized\n"));
  return 1;
}

#ifdef TOSSIM
#include "external_comm.h"
#endif

// Handle the event of the completion of a message transmission
char TOS_EVENT(AM_TX_PACKET_DONE)(TOS_MsgPtr msg){
  VAR(state) = 0;
#ifdef TOSSIM
    writeOutRadioPacket(tos_state.tos_time, NODE_NUM, (char*)msg, sizeof(TOS_Msg));
#endif
    TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(buffer_ptr));
  return 1;
}


// Handle the event of the reception of an incoming message
TOS_MsgPtr TOS_MSG_EVENT(AM_RX_PACKET_DONE)(TOS_MsgPtr buffer){
  char type;
  AMBuffer_ptr tmp;
  dbg(DBG_AM, ("AM_address = %hx, %hhx\n", buffer->addr, buffer->type));
  if(am_header_pass(buffer)) {
    type = buffer->type;
    VAR(buffer_ptr)->msg.hdr.type = type;
    VAR(buffer_ptr)->msg.hdr.dest = buffer->addr;
    VAR(buffer_ptr)->msg.hdr.group = buffer->group;
    VAR(buffer_ptr)->msg.hdr.src = 0xdead;
    memcpy(VAR(buffer_ptr)->msg.data, (buffer->data+4), DATA_LENGTH + 2);
    // Debugging output
    {
      int i;
      dbg(DBG_AM, ("Received message:\n\t"));
      for(i = 0; i < sizeof(TOS_Msg); i ++) {
	dbg_clear(DBG_AM, ("%02hhx ", ((char*)buffer)[i]));
      }
      dbg(DBG_AM, ("\n"));
      dbg(DBG_AM, ("AM_type = %d\n", type));
    }
    //send message to be dispatched.
    // invoke the corresponding handler defined by buffer->type
    //TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
    tmp = AM_MSG_REC(buffer->type, VAR(buffer_ptr));
    if(tmp != 0){
      return &VAR(msg);
    }else{
      return &VAR(msg);
    }
  }
  return buffer;
}

#include "AMdispatch.template"
