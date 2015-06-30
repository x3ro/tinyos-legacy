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
 * Authors:		Phil Levis
 * History              2/15/02 Kamin Whitehouse added the ability to send
 *                              functions of arbitrary length
 *
 *
 */



#include "tos.h"
#include "UART_PACKET_9600.h"
#include "dbg.h"

#define TOS_FRAME_TYPE UART_PACKET_obj_frame
TOS_FRAME_BEGIN(UART_PACKET_obj_frame) {
        char state;
        char* send_ptr;
	char msg_length;
        char tx_count;
}
TOS_FRAME_END(UART_PACKET_obj_frame);

char TOS_COMMAND(UART_PACKET_TX_BYTES)(char* bytes, char num_bytes){
  if(VAR(state) == 0){
    VAR(state) = 1;
    VAR(send_ptr) = (char*)bytes;
    if(TOS_CALL_COMMAND(UART_PACKET_SUB_TX_BYTES)(VAR(send_ptr)[0])){
      VAR(msg_length) = num_bytes;
      VAR(tx_count) = 1;
      return 1;
    }else{
      VAR(state) = 0;
      return 0;
    }
  }else{
    return 0;
  }
}

void TOS_COMMAND(UART_PACKET_POWER)(char mode){
    //do this later;
    ;
}


char TOS_COMMAND(UART_PACKET_INIT)(){
    VAR(state) = 0;
    TOS_CALL_COMMAND(UART_PACKET_SUB_INIT)();
    return 1;
} 


char TOS_EVENT(UART_PACKET_TX_BYTE_READY)(char success){
  dbg(DBG_UART, ("UART Transmitting!"));
  if(success == 0){
    dbg(DBG_ERROR, ("UART TX_packet failed, TX_byte_failed"));
    TOS_SIGNAL_EVENT(UART_PACKET_TX_PACKET_DONE)(VAR(send_ptr));
    VAR(state) = 0;
    VAR(tx_count) = 0;
  }
  if(VAR(state) == 1){
    if(VAR(tx_count) < VAR(msg_length)){
      TOS_CALL_COMMAND(UART_PACKET_SUB_TX_BYTES)(VAR(send_ptr)[(int)VAR(tx_count)]);
      VAR(tx_count) ++;
    }else{
      VAR(state) = 0;
      VAR(tx_count) = 0;
      TOS_SIGNAL_EVENT(UART_PACKET_TX_PACKET_DONE)(VAR(send_ptr));
    }                                                    
  }
  return 1;    
}

char TOS_EVENT(UART_PACKET_BYTE_TX_DONE)(){
    return 1;
}




