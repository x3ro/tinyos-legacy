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



#include "tos.h"
#include "UART_PACKET.h"
#include "dbg.h"

#ifdef FULLPC
#include "Fullpc_uart_connect.h"
#endif


#define TOS_FRAME_TYPE UART_PACKET_obj_frame
TOS_FRAME_BEGIN(UART_PACKET_obj_frame) {
        char state;
        char* send_ptr;
	char* rec_ptr;
	TOS_Msg buffer;
	char msg_length;
        char rx_count;
        char tx_count;
	char flag;
}
TOS_FRAME_END(UART_PACKET_obj_frame);

#define UART_START_SYMBOL 1

char TOS_COMMAND(UART_PACKET_TX_PACKET)(TOS_MsgPtr msg){
#ifndef FULLPC
    if(VAR(state) == 0){
	VAR(send_ptr) = (char*)msg;
	VAR(tx_count) = 1;
	VAR(state) = 1;
	if(TOS_CALL_COMMAND(UART_PACKET_SUB_TX_BYTES)(VAR(send_ptr)[0])){
	    return 1;
	}else{
	    VAR(state) = 0;
	    VAR(tx_count) = 0;
	    return 0;
	}
    }else{
	return 0;
    }
#else
    {
    	int i,j;
	int msglen;
	dbg(DBG_UART, ("uart_send_packet\n"));
	VAR(send_ptr) = (char*)msg;            

	
	msglen = defaultMsgSize(&VAR(buffer));	
	for (j=0; j < MSGLEN_TABLE_SIZE; j++){
	  if (msgTable[j].handler == VAR(send_ptr)[1]){
	    msglen = msgTable[j].length;
	  }
	}	
	
	if(uart_send != 0){
	  dbg(DBG_UART, ("UART sending packet: %d \n", write(uart_send, VAR(send_ptr), msglen)));
	}

    	for(i = 0; i < msglen; i ++) {
	  dbg(DBG_UART, ("%02x,", VAR(send_ptr)[i]&0xff));
    	}
	dbg(DBG_UART, ("\n"));
    }
    return 0;
#endif
}

void TOS_COMMAND(UART_PACKET_POWER)(char mode){
    //do this later;
    ;
}


char TOS_COMMAND(UART_PACKET_INIT)(){
  VAR(flag) = 0;
    VAR(state) = 0;
    VAR(msg_length) = defaultMsgSize(&VAR(buffer));
    VAR(rx_count) = 0;
    VAR(rec_ptr) = (char*)&VAR(buffer);
#ifdef FULLPC
   udp_init_socket();
    dbg(DBG_BOOT, ("UART Packet handler initialized.\n"));
#endif
	TOS_CALL_COMMAND(UART_PACKET_SUB_INIT)();
    return 1;
} 


char TOS_EVENT(UART_PACKET_RX_BYTE_READY)(char data, char error){
  char i;
  dbg(DBG_UART, ("UART PACKET: byte arrived: %x, STATE: %d, COUNT: %d\n", data, VAR(state), VAR(rx_count)));
    if(error){
	VAR(rx_count) = 0;
	return 0;
    }

    if(VAR(flag) == 0 && VAR(rx_count) == 0 && data == UART_START_SYMBOL) {
      VAR(flag) = 1;
      
    } else {
      
      if(VAR(flag) == 1) {
	VAR(rec_ptr)[(int)VAR(rx_count)] = data;
	VAR(rx_count)++;
	
	if (VAR(rx_count) == 1){
	  for (i=0; i < MSGLEN_TABLE_SIZE; i++){
	    if (msgTable[(int)i].handler == data){
	      VAR(msg_length) = msgTable[(int)i].length;
	    }
	  }
	} 
	
	if (VAR(rx_count) == VAR(msg_length)){
	  TOS_MsgPtr tmp;
	  VAR(flag) = 0;
	  VAR(rx_count) = 0;
	  VAR(msg_length) = defaultMsgSize(&VAR(buffer));
	  tmp = TOS_SIGNAL_EVENT(UART_PACKET_RX_PACKET_DONE)((TOS_MsgPtr)VAR(rec_ptr));
	  if(tmp != 0) VAR(rec_ptr) = (char*)tmp;
	  return 0;
	}
      }
    }
    
    return 1;
}




char TOS_EVENT(UART_PACKET_TX_BYTE_READY)(char success){
  char i;
  dbg(DBG_UART, ("UART Transmitting!"));
    if(success == 0){
	dbg(DBG_ERROR, ("UART TX_packet failed, TX_byte_failed"));
	TOS_SIGNAL_EVENT(UART_PACKET_TX_PACKET_DONE)((TOS_MsgPtr)VAR(send_ptr));
	VAR(state) = 0;
	VAR(tx_count) = 0;
    }
    if(VAR(state) == 1){
      
      if (VAR(tx_count) == 1){
	for (i=0; i < MSGLEN_TABLE_SIZE; i++){
	  if (msgTable[(int)i].handler == 
	      VAR(send_ptr)[(int)VAR(tx_count)]){
	    VAR(msg_length) = msgTable[(int)i].length;
	  }
	}
      }  
      if(VAR(tx_count) < VAR(msg_length)){
#ifndef FULLPC
	TOS_CALL_COMMAND(UART_PACKET_SUB_TX_BYTES)(VAR(send_ptr)[(int)VAR(tx_count)]);
#else 
	write(uart_send, &VAR(send_ptr)[(int) VAR(tx_count)], 1);
	TOS_ISSUE_INTERRUPT(_uart_trans_)(VAR(send_ptr)[(int) VAR(tx_count)]);
	//uarttransobj_interrupt(VAR(send_ptr)[(int) VAR(tx_count)]);
#endif
	VAR(tx_count) ++;
      }else{
	VAR(state) = 0;
	VAR(tx_count) = 0;
	VAR(msg_length) = defaultMsgSize(&VAR(buffer));
	TOS_SIGNAL_EVENT(UART_PACKET_TX_PACKET_DONE)((TOS_MsgPtr)VAR(send_ptr));
      }                                                    
    }
    return 1;    
}

char TOS_EVENT(UART_PACKET_BYTE_TX_DONE)(){
    return 1;
}

#ifdef FULLPC

void uart_packet_evt(){
        int avilable, msglen,j;

	msglen = defaultMsgSize(&VAR(buffer));	
	for (j=0; j < MSGLEN_TABLE_SIZE; j++){
	  if (msgTable[j].handler == VAR(send_ptr)[1]){
	    msglen = msgTable[j].length;
	  }
	}	

	ioctl(uart_send, FIONREAD, &avilable);
	if(avilable > msglen){
		read(uart_send, VAR(rec_ptr), msglen);
		TOS_SIGNAL_EVENT(UART_PACKET_RX_PACKET_DONE)((TOS_MsgPtr)VAR(rec_ptr));
		dbg(DBG_UART, ("UART got packet\n"));
			
	}

}



#endif
