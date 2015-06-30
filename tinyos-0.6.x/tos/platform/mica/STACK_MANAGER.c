/*									tab:4
 * "Copyright (c) 2002 and The Regents of the University 
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
 * This component handles the packet abstraction on the network stack 
 */

#include "tos.h"
#include "STACK_MANAGER.h"
#include "dbg.h"

#define IDLE_STATE 0
#define SEND_WAITING 1
#define RX_STATE 2
#define TRANSMITTING 3
#define DONE_TRANSMITTING 4
#define RECEIVING 5
#define TRANSMITTING_START 6
#define RX_DONE_STATE 7

//static char start[3] = {0xab, 0x34, 0xd5}; //10 Kbps
//static char start[6] = {0xcc, 0xcf, 0x0f, 0x30, 0xf3, 0x33}; //20 Kbps
static char start[12] = {0xf0, 0xf0, 0xf0, 0xff, 0x00, 0xff, 0x0f, 0x00, 0xff, 0x0f, 0x0f, 0x0f}; //40 Kbps

#define TOS_FRAME_TYPE PACKET_obj_frame
TOS_FRAME_BEGIN(PACKET_obj_frame) {
	char state;
        char send_state;
        char tx_count;
        char rec_count;
	AMBuffer buffer;
	AMBuffer_ptr rec_buffer_ptr;
	AMBuffer_ptr tx_buffer_ptr;
	char* rec_ptr;
	char* send_ptr;
	unsigned char rx_count;
	char msg_length;
	char tx_msg_length;
	char buf_head;
	char buf_end;
	char encoded_buffer[4];
	char enc_count;
	char decode_byte;
	char code_count;
	char headerSize;
	char headerCount;
	char recvLength;
}
TOS_FRAME_END(PACKET_obj_frame);

#define ADVANCE(x) {x++; x &= 0x3;}

	
TOS_TASK(packet_received){
	AMBuffer_ptr tmp;
	
	VAR(state) = IDLE_STATE;
	
	tmp = TOS_SIGNAL_EVENT(MANAGER_RX_PACKET_DONE)(VAR(rec_buffer_ptr));
	if(tmp != 0) {
	  VAR(rec_ptr) = (char*)tmp;
	  VAR(rec_buffer_ptr) = tmp;
	}
	
	TOS_CALL_COMMAND(START_SYMBOL_SEARCH)();
}

TOS_TASK(packet_sent){
    	    VAR(send_state) = IDLE_STATE;
	    VAR(state) = IDLE_STATE;
	    TOS_SIGNAL_EVENT(MANAGER_TX_PACKET_DONE)((AMBuffer_ptr)VAR(send_ptr));
}

void TOS_COMMAND(MANAGER_SET_HEADER_SIZE)(char size) {
  VAR(headerSize) = size;
}

char TOS_EVENT(MANAGER_SUB_CHANNEL_IDLE_TIMEOUT)() {
    VAR(send_state) = IDLE_STATE;
    return TOS_SIGNAL_EVENT(MANAGER_TX_PACKET_TIMEOUT)(VAR(tx_buffer_ptr));
}


/* Command to transmit a packet */
char TOS_COMMAND(MANAGER_TX_PACKET)(AMBuffer_ptr msg, char timeout){
    if(VAR(send_state) == IDLE_STATE){
	VAR(send_ptr) = (char*)&(msg->msg);
	VAR(tx_buffer_ptr) = msg;
	VAR(tx_msg_length) = msg->msg.hdr.length;
	VAR(send_state) = SEND_WAITING;
	VAR(tx_count) = 1;
	TOS_CALL_COMMAND(MANAGER_SUB_MAC_DELAY)(timeout);
	return 1;
    }else{
	return 0;
    }
}

/* Command to control the power of the network stack */
void TOS_COMMAND(MANAGER_POWER)(char mode){
    //apply your power management algorithm
    ;
}


/* Initialization of this component */
char TOS_COMMAND(MANAGER_INIT)(){
    VAR(rec_ptr) = (char*)&VAR(buffer);
    VAR(rec_buffer_ptr) = &VAR(buffer);
    VAR(send_state) = IDLE_STATE;
    VAR(state) = IDLE_STATE;
    TOS_CALL_COMMAND(MONITOR_CHANNEL_INIT)();
    VAR(headerSize) = 0;
    VAR(headerCount) = -1;
    return 1;
} 

/* The handles the latest decoded byte propagated by the Byte Level component*/
char TOS_EVENT(MANAGER_SUB_START_SYM_DETECT)(){
	short tmp;
	VAR(rec_count) = 0;
	VAR(recvLength) = sizeof(ActiveMessage);
	VAR(state) = RX_STATE;
	tmp = TOS_CALL_COMMAND(MANAGER_SUB_GET_TIMING)();
	TOS_CALL_COMMAND(MANAGER_SUB_FIFO_READ)(tmp);
	VAR(rec_buffer_ptr)->timing_low = tmp;
	return 1;
}


char TOS_EVENT(MANAGER_SUB_CHANNEL_IDLE)(){
  if(VAR(send_state) == SEND_WAITING){
	VAR(buf_end) = VAR(buf_head) = 0;
	VAR(enc_count) = 0;
	TOS_CALL_COMMAND(MANAGER_SUB_RADIO_ENCODE)(VAR(send_ptr)[0]);
  	VAR(rx_count) = 0;
	VAR(send_state) = IDLE_STATE;
	VAR(state) = TRANSMITTING_START;
  	TOS_CALL_COMMAND(MANAGER_SUB_FIFO_SEND)(start[0]);
  }
  return 1;
}

char TOS_EVENT(MANAGER_SUB_RADIO_DECODE_DONE)(char data, char error){
  char rval = 1;

  if(VAR(state) == IDLE_STATE){
    return 0;
  }
  else if(VAR(state) == RX_STATE){
    VAR(rec_ptr)[(int)VAR(rec_count)] = data;
    VAR(rec_count)++;
    // This code causes the stack to hang ...
    //	if (error) { // add rec_count bit
    //  VAR(rec_buffer_ptr)->errors[VAR(rec_count) / 8] |= (1 << (7 - (VAR(rec_count) % 8)));
    //}
    //else { // strip out rec_count bit
    //  VAR(rec_buffer_ptr)->errors[VAR(rec_count) / 8] &= ~(1 << (7 - (VAR(rec_count) % 8)));
    //}
    //if (VAR(headerSize) > 0) {
    //  VAR(headerCount)++;
    // }
    //if (VAR(headerCount) == VAR(headerSize)) {
    //  TOS_SIGNAL_EVENT(MANAGER_RX_HEADER_DONE)(&(VAR(rec_ptr)[VAR(rec_count) - VAR(headerCount)]), VAR(headerSize));
    //  VAR(headerSize) = -1;
    // VAR(headerCount) = 0;
    //}
    if (VAR(rec_count) == sizeof(AMHeader)) {
      AMBuffer_ptr buffer_ptr = (AMBuffer_ptr)VAR(rec_ptr);
      VAR(recvLength) = buffer_ptr->msg.hdr.length;
      VAR(recvLength) = (VAR(recvLength) < sizeof(ActiveMessage))? VAR(recvLength):sizeof(ActiveMessage);
    }
    else if(VAR(rec_count) >= VAR(recvLength)) {
      VAR(state) = RX_DONE_STATE;
      TOS_CALL_COMMAND(SPI_IDLE)();
      TOS_POST_TASK(packet_received);
      rval = 0;
    }
  }
  return rval;
}

char TOS_EVENT(MANAGER_SUB_RADIO_ENCODE_DONE)(char data1){
  VAR(encoded_buffer)[(int)VAR(buf_end)] = data1;
  ADVANCE(VAR(buf_end));
  VAR(enc_count) += 1;
  return 1;
}

char TOS_EVENT(MANAGER_SUB_DATA_SEND_READY)(char data){
  //lower level needs another byte....
  
  if(VAR(state) == TRANSMITTING_START){
      TOS_CALL_COMMAND(MANAGER_SUB_FIFO_SEND)(start[(int)VAR(tx_count)]);
      VAR(tx_count) ++;
      if(VAR(tx_count) == sizeof(start)){
	VAR(state) = TRANSMITTING;
	VAR(tx_count) = 1;
      }
    }
    else if(VAR(state) == TRANSMITTING){
      TOS_CALL_COMMAND(MANAGER_SUB_FIFO_SEND)(VAR(encoded_buffer)[(int)VAR(buf_head)]);
      ADVANCE(VAR(buf_head));
      VAR(enc_count) --;
      //now check if that was the last byte.
      
      if(VAR(enc_count) >= 2){
	;
      }
      else if(VAR(tx_count) <= VAR(tx_msg_length)){ // Msg hdr + body
	TOS_CALL_COMMAND(MANAGER_SUB_RADIO_ENCODE)(VAR(send_ptr)[(int)VAR(tx_count)]);
	VAR(tx_count) ++;
      }
      else if(VAR(buf_head) != VAR(buf_end)){
	TOS_CALL_COMMAND(MANAGER_SUB_RADIO_ENCODE_FLUSH)();
      }
      else{
	VAR(state) = DONE_TRANSMITTING;
      }
    }
    else if(VAR(state) == DONE_TRANSMITTING){
      VAR(state) = IDLE_STATE;
      TOS_CALL_COMMAND(SPI_IDLE)();
      TOS_CALL_COMMAND(START_SYMBOL_SEARCH)();
      TOS_POST_TASK(packet_sent);
    }
    else if(VAR(state) == RX_STATE){
      TOS_CALL_COMMAND(MANAGER_SUB_RADIO_DECODE)(data);
    }
    
    return 1; 
}

