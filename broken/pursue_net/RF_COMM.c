#include "tos.h"
#include "RF_COMM.h"
#include "dbg.h"


#define ENCODE_PACKET_LENGTH_DEFAULT MSG_DATA_SIZE*3 
#define ACK_CNT 4 

#define IDLE_STATE 0
#define SEND_WAITING 1
#define RX_STATE 2
#define ACK_SEND_STATE 9
#define RX_DONE_STATE 8
#define TRANSMITTING 3
#define TRANSMITTING_START 7
#define SENDING_STRENGTH_PULSE 5
#define WAITING_FOR_ACK 4


//static char start[3] = {0xab, 0x34, 0xd5}; //10 Kbps
//static char start[6] = {0xcc, 0xcf, 0x0f, 0x30, 0xf3, 0x33}; //20 Kbps
static char start[12] = {0xf0, 0xf0, 0xf0, 0xff, 0x00, 0xff, 0x0f, 0x00, 0xff, 0x0f, 0x0f, 0x0f}; //40 Kbps

#define TOS_FRAME_TYPE PACKET_obj_frame
TOS_FRAME_BEGIN(PACKET_obj_frame) {
	char state;
        char send_state;
        char tx_count;
	short calc_crc;
        uint8_t ack_count;
        char rec_count;
	TOS_Msg buffer;
	TOS_Msg* rec_ptr;
	TOS_Msg* send_ptr;
	unsigned char rx_count;
	char msg_length;
	char buf_head;
	char buf_end;
	char encoded_buffer[4];
	char enc_count;
	char decode_byte;
	char code_count;
}
TOS_FRAME_END(PACKET_obj_frame);

#define ADVANCE(x) {x++; x &= 0x3;}
short add_crc_byte(char new_byte, short crc);

	
TOS_TASK(packet_received){
	TOS_MsgPtr tmp;
	VAR(state) = IDLE_STATE;
		//outp(VAR(state), UDR);
	tmp = TOS_SIGNAL_EVENT(PACKET_RX_PACKET_DONE)((TOS_Msg*)VAR(rec_ptr));
	if(tmp != 0) VAR(rec_ptr) = tmp;
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
	VAR(send_ptr) = msg;
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
    VAR(rec_ptr) = &VAR(buffer);
    VAR(send_state) = IDLE_STATE;
    VAR(state) = IDLE_STATE;
    TOS_CALL_COMMAND(MONITOR_CHANNEL_INIT)();
    TOS_CALL_COMMAND(RF_COMM_ADC_INIT)();
    outp(12, UBRR);

//>>>>>>>>>>>>>>>>>>>>>>>>>>DEBUG
//inp(UDR);
//outp(0xd8,UCR);
//sbi(USR, TXC);
//>>>>>>>>>>>>>>>>>>>>>>>>>>>DEBUG
    return 1;
} 

char global;

/* The handles the latest decoded byte propagated by the Byte Level component*/
char TOS_EVENT(PACKET_SUB_START_SYM_DETECT)(){
	short tmp;
	VAR(ack_count) = 0;
	VAR(rec_count) = 0;
	VAR(state) = RX_STATE;
		//outp(VAR(state), UDR);
	tmp = TOS_CALL_COMMAND(PACKET_SUB_GET_TIMING)();
	TOS_CALL_COMMAND(PACKET_SUB_FIFO_READ)(tmp);
  	VAR(msg_length) = MSG_DATA_SIZE - 2;
  	VAR(calc_crc) = 0;
	VAR(rec_ptr)->time = tmp;
	VAR(rec_ptr)->strength = 0;
	return 1;
}


char TOS_EVENT(PACKET_SUB_CHANNEL_IDLE)(){
  if(VAR(send_state) == SEND_WAITING){
	char first = ((char*)VAR(send_ptr))[0];
	VAR(buf_end) = VAR(buf_head) = 0;
	VAR(enc_count) = 0;
	TOS_CALL_COMMAND(PACKET_SUB_RADIO_ENCODE)(first);
  	VAR(rx_count) = 0;
	VAR(msg_length) = (unsigned char)(VAR(send_ptr)->length) + MSG_DATA_SIZE - DATA_LENGTH - 2;
	VAR(send_state) = IDLE_STATE;
	VAR(state) = TRANSMITTING_START;
  	TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(start[0]);
	VAR(send_ptr)->time = TOS_CALL_COMMAND(RF_COMM_SUB_GET_CURRENT_TIME)();
	VAR(calc_crc) = add_crc_byte(first, 0x00);
  }
  return 1;
}

char TOS_EVENT(PACKET_SUB_RADIO_DECODE_DONE)(char data, char error){
    if(VAR(state) == IDLE_STATE){
	return 0;
    }else if(VAR(state) == RX_STATE){
	((char*)VAR(rec_ptr))[(int)VAR(rec_count)] = data;
	VAR(rec_count)++;
	if(VAR(rec_count) >= MSG_DATA_SIZE){
		TOS_CALL_COMMAND(RF_COMM_ADC_GET_DATA)(0);
		//outp(VAR(rec_ptr)->crc >> 8, UDR);
		//outp(VAR(calc_crc) >> 8, UDR);
		//outp(((char*)VAR(rec_ptr))[global], UDR);
		global ++;
		global &= 0xf;
		if(VAR(calc_crc) == VAR(rec_ptr)->crc){
			VAR(rec_ptr)->crc = 1;
			if(VAR(rec_ptr)->addr == TOS_LOCAL_ADDRESS ||
			   VAR(rec_ptr)->addr == TOS_BCAST_ADDR){
	        		TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(0x55);
			}
		}else{
			VAR(rec_ptr)->crc = 0;
		}
   		VAR(state) = ACK_SEND_STATE;
		//outp(VAR(state), UDR);
		return 0;
	}else if(VAR(rec_count) <= MSG_DATA_SIZE-2){
		VAR(calc_crc) = add_crc_byte(data, VAR(calc_crc));
	}
        if(VAR(rec_count) == LENGTH_BYTE_NUMBER){
		if(((unsigned char)data) < DATA_LENGTH){
			VAR(msg_length) = ((unsigned char)data) + MSG_DATA_SIZE - DATA_LENGTH - 2;
		}
	}
	if(VAR(rec_count) == VAR(msg_length)){
		VAR(rec_count) = MSG_DATA_SIZE-2;
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
	}else if(VAR(tx_count) < MSG_DATA_SIZE){ 
		char next_data = ((char*)VAR(send_ptr))[(int)VAR(tx_count)];
		TOS_CALL_COMMAND(PACKET_SUB_RADIO_ENCODE)(next_data);
		VAR(tx_count) ++;
		if(VAR(tx_count) <= VAR(msg_length)){
		        VAR(calc_crc) = add_crc_byte(next_data, VAR(calc_crc));
		}
		if(VAR(tx_count) == VAR(msg_length)){
			//the last 2 bytes must be the CRC and are
			//transmitted regardless of the length.
			VAR(tx_count) = MSG_DATA_SIZE - 2;
			VAR(send_ptr)->crc = VAR(calc_crc);
		}
	}else if(VAR(buf_head) != VAR(buf_end)){
		TOS_CALL_COMMAND(PACKET_SUB_RADIO_ENCODE_FLUSH)();
	}else{
	    VAR(state) = SENDING_STRENGTH_PULSE;
///////////////DEBUG>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	    //outp(0x7e, UDR);
	    VAR(tx_count) = 0;
///////////////DEBUG>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	}
   }else if(VAR(state) == SENDING_STRENGTH_PULSE){
	    VAR(tx_count) ++;
	    if(VAR(tx_count) == 3){
	       VAR(state) = WAITING_FOR_ACK;
		//outp(VAR(state), UDR);
	        TOS_CALL_COMMAND(PHASE_SHIFT)();
	       VAR(tx_count) = 1;
		TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(0x00);
	
	    }else{
		TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(0xff);

    	}
   }else if(VAR(state) == WAITING_FOR_ACK){
	    data &= 0x7f;
	    TOS_CALL_COMMAND(PACKET_SUB_FIFO_SEND)(0x00);
	    if(VAR(tx_count) == 1) TOS_CALL_COMMAND(SPI_RX_MODE)();
	    VAR(tx_count) ++;  
///////////////DEBUG>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	    if(VAR(tx_count) == ACK_CNT + 2) {
  		//outp(data, UDR);
///////////////DEBUG>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		VAR(send_ptr)->ack = (data == 0x55);
	    	VAR(state) = IDLE_STATE;
		//outp(VAR(state), UDR);
    	    	TOS_CALL_COMMAND(SPI_IDLE)();
    	    	TOS_CALL_COMMAND(START_SYMBOL_SEARCH)();
	    	TOS_POST_TASK(packet_sent);
	    }
   }else if(VAR(state) == RX_STATE){
	TOS_CALL_COMMAND(PACKET_SUB_RADIO_DECODE)(data);
   }else if(VAR(state) == ACK_SEND_STATE){
	VAR(ack_count) ++;
	if(VAR(ack_count) > ACK_CNT + 1){
	    VAR(state) = RX_DONE_STATE;
		//outp(VAR(state), UDR);
	    TOS_CALL_COMMAND(SPI_IDLE)();
	    TOS_POST_TASK(packet_received);
	}else{
	    TOS_CALL_COMMAND(SPI_TX_MODE)();
	}
   }
	
   return 1; 
}


char TOS_EVENT(SIG_STRENGTH_READING)(short data){
//        outp(data >> 2, UDR);
	VAR(rec_ptr)->strength = data;
        return 1;
}


short add_crc_byte(char new_byte, short crc){
	uint8_t i;
        crc = crc ^ (int) new_byte << 8;
        i = 8;
        do
        {
            if (crc & 0x8000)
                crc = crc << 1 ^ 0x1021;
            else
                crc = crc << 1;
        } while(--i);
	return crc;
}
