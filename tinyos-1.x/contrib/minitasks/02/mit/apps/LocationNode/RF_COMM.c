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
 * Authors:		Jason Hill
 * 
 * This component handles the packet abstraction on the network stack 
 */
 
 // Modified according to the patch at:
 // http://sourceforge.net/forum/forum.php?thread_id=658988&forum_id=90238
 // to make the signal strength available in the in the data->strength field
 // of the received packet.

#include "tos.h"
#include "RF_COMM.h"
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
	TOS_Msg buffer;
	char* rec_ptr;
	char* send_ptr;
	unsigned char rx_count;
	char msg_length;
	char buf_head;
	char buf_end;
	char encoded_buffer[4];
	char enc_count;
	char decode_byte;
	char code_count;
	short strength; // measured strength of the baseband signal
}
TOS_FRAME_END(PACKET_obj_frame);

#define ADVANCE(x) {x++; x &= 0x3;}

	
TOS_TASK(packet_received){
	TOS_MsgPtr tmp;
	VAR(state) = IDLE_STATE;
	((TOS_Msg*)VAR(rec_ptr))->strength = VAR(strength);
	tmp = TOS_SIGNAL_EVENT(PACKET_RX_PACKET_DONE)((TOS_Msg*)VAR(rec_ptr));
	if(tmp != 0) VAR(rec_ptr) = (char*)tmp;
	TOS_CALL_COMMAND(START_SYMBOL_SEARCH)();
}

TOS_TASK(packet_sent){
    	    VAR(send_state) = IDLE_STATE;
	    VAR(state) = IDLE_STATE;
	    TOS_SIGNAL_EVENT(PACKET_TX_PACKET_DONE)((TOS_MsgPtr)VAR(send_ptr));
}


/* Command to transmit a packet */
char TOS_COMMAND(PACKET_TX_PACKET)(TOS_MsgPtr msg){
    if(VAR(send_state) == IDLE_STATE){
	VAR(send_ptr) = (char*)msg;
	VAR(send_state) = SEND_WAITING;
	VAR(tx_count) = 1;
	TOS_CALL_COMMAND(PACKET_SUB_MAC_DELAY)();
	return 1;
    }else{
	return 0;
    }
}

/* Command to control the power of the network stack */
void TOS_COMMAND(PACKET_POWER)(char mode){
    //apply your power management algorithm
    ;
}


/* Initialization of this component */
char TOS_COMMAND(PACKET_INIT)(){
    VAR(rec_ptr) = (char*)&VAR(buffer);
    VAR(send_state) = IDLE_STATE;
    VAR(state) = IDLE_STATE;
    TOS_CALL_COMMAND(MONITOR_CHANNEL_INIT)();
    TOS_CALL_COMMAND(PACKET_SUB_INIT)();
    return 1;
} 

/* The handles the latest decoded byte propagated by the Byte Level component*/
char TOS_EVENT(PACKET_SUB_START_SYM_DETECT)(){
	short tmp;
	VAR(rec_count) = 0;
	VAR(state) = RX_STATE;
	
	tmp = TOS_CALL_COMMAND(PACKET_SUB_GET_TIMING)();
	
	/* Be sure to clear the previous measurement: if the ADC measurement
	 * does not succeed, at least do not have a completely incorrect value. */
	VAR(strength) = 0;
	
	/* PACKET_SUB_GET_TIMING() returned, so we just detected the rising edge
	 * in the last 0x0f of the received start sequence. With 40 kbit/sec
	 * data rate it means that the input signal will be high for 100 microsec.
	 * 
	 * It is important to issue the sampling command now, as the
	 * PACKET_SUB_FIFO_READ() will busy-wait till the end of this high signal.
	 * 
	 * NOTE: As of TinyOS 0.6, the ADC is always driven in "First Conversion"
	 * mode - note the cbi(ADCSR, ADEN); at the end of the conversion - so the
	 * actual sample is taken ~70-80 microsec later. It works for 40 kbit/sec,
	 * but will not for a higher rate.
	 */
	TOS_CALL_COMMAND(PACKET_SUB_ADC_GET_DATA)(0);
	
	TOS_CALL_COMMAND(PACKET_SUB_FIFO_READ)(tmp);
	return 1;
}

char TOS_EVENT(PACKET_SUB_ADC_DATA_READY)(short data){ 
	/* Do not store the strength into the buffer right now, as it will be
	 * overwritten by radio garbage received after the message: */
	VAR(strength) = data;
	return 1;
}


char TOS_EVENT(PACKET_SUB_CHANNEL_IDLE)(){
  if(VAR(send_state) == SEND_WAITING){
	VAR(buf_end) = VAR(buf_head) = 0;
	VAR(enc_count) = 0;
	TOS_CALL_COMMAND(PACKET_SUB_RADIO_ENCODE)(VAR(send_ptr)[0]);
  	VAR(rx_count) = 0;
	VAR(send_state) = IDLE_STATE;
	VAR(state) = TRANSMITTING_START;
  	TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(start[0]);
  }
  return 1;
}

char TOS_EVENT(PACKET_SUB_RADIO_DECODE_DONE)(char data, char error){
    if(VAR(state) == IDLE_STATE){
	return 0;
    }else if(VAR(state) == RX_STATE){
	VAR(rec_ptr)[(int)VAR(rec_count)] = data;
	VAR(rec_count)++;
	if(VAR(rec_count) == sizeof(TOS_Msg)){
	    VAR(state) = RX_DONE_STATE;
	    TOS_CALL_COMMAND(SPI_IDLE)();
	    TOS_POST_TASK(packet_received);
	    return 0;
	}
    }
    return 1;
}

char TOS_EVENT(PACKET_SUB_RADIO_ENCODE_DONE)(char data1){
  VAR(encoded_buffer)[(int)VAR(buf_end)] = data1;
  ADVANCE(VAR(buf_end));
  VAR(enc_count) += 1;
  return 1;
}

char TOS_EVENT(PACKET_SUB_DATA_SEND_READY)(char data){
	//lower level needs another byte....
    if(VAR(state) == TRANSMITTING_START){
	TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(start[(int)VAR(tx_count)]);
	VAR(tx_count) ++;
	if(VAR(tx_count) == sizeof(start)){
		VAR(state) = TRANSMITTING;
		VAR(tx_count) = 1;
	}
    }else if(VAR(state) == TRANSMITTING){
	TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(VAR(encoded_buffer)[(int)VAR(buf_head)]);
	ADVANCE(VAR(buf_head));
	VAR(enc_count) --;
	//now check if that was the last byte.

	if(VAR(enc_count) >= 2){
		;
	}else if(VAR(tx_count) <= sizeof(TOS_Msg)){
		TOS_CALL_COMMAND(PACKET_SUB_RADIO_ENCODE)(VAR(send_ptr)[(int)VAR(tx_count)]);
		VAR(tx_count) ++;
	}else if(VAR(buf_head) != VAR(buf_end)){
		TOS_CALL_COMMAND(PACKET_SUB_RADIO_ENCODE_FLUSH)();
		;
	}else{
	    VAR(state) = DONE_TRANSMITTING;
	
	}
   }else if(VAR(state) == DONE_TRANSMITTING){
	    VAR(state) = IDLE_STATE;
    	    TOS_CALL_COMMAND(SPI_IDLE)();
    	    TOS_CALL_COMMAND(START_SYMBOL_SEARCH)();
	    TOS_POST_TASK(packet_sent);
   }else if(VAR(state) == RX_STATE){
	TOS_CALL_COMMAND(PACKET_SUB_RADIO_DECODE)(data);
   }
	
   return 1; 
}

