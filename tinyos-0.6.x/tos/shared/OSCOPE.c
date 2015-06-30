/*									tab:4
 * OSCOPE.c - periodically emits an active message containing light reading
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
 * Authors:   Jason Hill
 * History:   created 10/5/2001
 *            Kamin Whitehouse 2/14/02 
 *               componentized and cleaned up and expanded it
 *
 *
 *
 * This applicaton periodically samples the ADC and sends a packet 
 * full of data out over the UART.  There are 10 readings per packet.
 * 
 * It has been expanded to let the user specify the following parameters:
 * 1.  Start and Stop
 * 2.  Data channel
 * 3.  Clock Speed
 * 4.  Max Number of Bytes
 * 5.  Number of bytes per reading
 * 6.  Whether to send the data as a packet or just as raw data
 */

#include "tos.h"
#include "OSCOPE.h"
#include "dbg.h"
#include "sensorboard.h"

#define AM_TYPE 10 
#define BUFFER_SIZE 10 
#define INITIAL_DATA_CHANNEL 1
#define START_SYMBOL 0x7e //this will be used in raw data mode
#define SEND_PACKET_TO_UART 0
#define SEND_RAW_DATA_TO_UART 1
#define SEND_PACKET_TO_BCAST 2

struct oscope_data{
    unsigned int source_mote_id;
    unsigned int last_sample_number;
    unsigned int channel;
    int data[BUFFER_SIZE];
};

#define TOS_FRAME_TYPE OSCOPE_frame
TOS_FRAME_BEGIN(OSCOPE_frame) {
  char active;                   //whether this component is sensing or not
  char bytes_per_sample;
  unsigned char max_samples;
  volatile char buffer_index;	       
  unsigned int sample_count;
  struct oscope_data* current_pkt;
  char current_buffer_number;
  TOS_Msg msg_buffer[2];
  volatile char send_pending;
  char data_channel;
  char send_type; //0=raw UART data, 1=packet to UART, 2=packet to BCAST
}
TOS_FRAME_END(OSCOPE_frame);


/* OSCOPE_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component buffer_index, including constant portion of msgs.
*/

char TOS_COMMAND(OSCOPE_INIT)(){
    VAR(active) = 0;
    VAR(bytes_per_sample) = 1;
    VAR(max_samples) = 0; //zero means collect indefinitly
    VAR(buffer_index) = 0;
    VAR(sample_count) = 0;
    VAR(current_pkt) = (struct oscope_data*)(VAR(msg_buffer)[(int)VAR(current_buffer_number)].data);
    VAR(current_buffer_number) = 0;
    VAR(send_pending) = 0;
    VAR(data_channel) = INITIAL_DATA_CHANNEL;
    VAR(send_type) = SEND_PACKET_TO_UART;

    //turn on the sensors so that they can be read.
    ADC_PORTMAP_BIND(TOS_ADC_PORT_1, PHOTO_PORT);
    MAKE_PHOTO_CTL_OUTPUT();
    SET_PHOTO_CTL_PIN();

    dbg(DBG_BOOT, ("OSCOPE initialized\n"));
    return 1;
}

char TOS_COMMAND(OSCOPE_START)(){
  return 1;
}

char TOS_COMMAND(OSCOPE_SET_DATA_CHANNEL)(char channel){
  VAR(data_channel)=channel;
  return 1;
}

char TOS_COMMAND(OSCOPE_SET_BYTES_PER_SAMPLE)(char numBytes){
  VAR(bytes_per_sample)=numBytes;
  return 1;
}

char TOS_COMMAND(OSCOPE_SET_MAX_SAMPLES)(char maxSamples){
  VAR(max_samples)=maxSamples;
  return 1;
}

//indicates if the data is to be sent over the UART or broadcasted
char TOS_COMMAND(OSCOPE_SET_SEND_TYPE)(char sendType){
  VAR(send_type)=sendType;
  return 1;
}

char TOS_COMMAND(OSCOPE_ACTIVATE)(){
  VAR(active)=1;
  TOS_CALL_COMMAND(OSCOPE_CLOCK_INIT)(32, 3);    /* set clock interval */
  return 1;
}

char TOS_COMMAND(OSCOPE_DEACTIVATE)(){
  VAR(active)=0;
  return 1;
}

char TOS_COMMAND(OSCOPE_RESET_SAMPLE_COUNT)(){
  VAR(sample_count) = 0;
  return 1;
}

char TOS_EVENT(OSCOPE_DATA_RXD) (short data) {
  TOS_MsgPtr msg;
  short sendAddress=0;
  dbg(DBG_USR1, ("data_event\n"));

  //store the data sample
  VAR(current_pkt)->data[(int)VAR(buffer_index)] = data; 
  VAR(buffer_index) ++;
  VAR(sample_count) ++;

  //if the buffer is full, send the data in one of three ways
  if(VAR(buffer_index) == BUFFER_SIZE){
    if(VAR(send_pending) == 0){

      //if we want to send raw data, add a start symbol before data and send
      if(VAR(send_type)==SEND_RAW_DATA_TO_UART){
	VAR(current_pkt)->channel = START_SYMBOL;
	if(TOS_CALL_COMMAND(OSCOPE_UART_TX_BYTES)((char*)&(VAR(current_pkt)->channel), BUFFER_SIZE*2+2)){
	  VAR(send_pending)++;
	}
      }

      //otherwise prepare the packet and send
      else {
	VAR(current_pkt)->channel = VAR(data_channel);
	VAR(current_pkt)->last_sample_number =  VAR(sample_count);
	VAR(current_pkt)->source_mote_id = TOS_LOCAL_ADDRESS;
	
	if(VAR(send_type)==SEND_PACKET_TO_UART){
	  sendAddress=TOS_UART_ADDR;
	}else if(VAR(send_type)==SEND_PACKET_TO_BCAST){
	  sendAddress=TOS_BCAST_ADDR;
	}
	
	msg = &VAR(msg_buffer)[(int)VAR(current_buffer_number)];
	if(TOS_CALL_COMMAND(OSCOPE_SUB_SEND_MSG)(sendAddress,AM_TYPE, msg)) {
	  VAR(send_pending)++;
	}
      }

      //switch to the other buffer while this one is being sent
      VAR(buffer_index) = 0;
      VAR(current_buffer_number) ^= 0x1;
      VAR(current_pkt) = (struct oscope_data*)(VAR(msg_buffer)[(int)VAR(current_buffer_number)].data);
    }
    
    //but if the old buffer is not finished being sent yet, wait a minute.
    else{
      VAR(buffer_index)--;
      VAR(sample_count)--;
    }
  }
  return 1;
}

char TOS_EVENT(OSCOPE_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
  if(msg == &VAR(msg_buffer)[(int)VAR(current_buffer_number^0x1)]){
    VAR(send_pending)--;
    return 1;
  }
  return 0;
}

char TOS_EVENT(OSCOPE_SUB_UART_MSG_SEND_DONE)(TOS_MsgPtr bytes){
  if((char*)bytes == (char*)&(((struct oscope_data*)((VAR(msg_buffer)[(int)VAR(current_buffer_number^0x1)]).data))->channel)){
    VAR(send_pending)--;
    return 1;
  }
  return 0;
}

void TOS_EVENT(OSCOPE_CLOCK_EVENT)(){
  if( (VAR(active)==1) && ( (VAR(max_samples)==0) || (VAR(max_samples)>VAR(sample_count)) || (VAR(buffer_index) != 0)  ) )
    TOS_CALL_COMMAND(OSCOPE_GET_DATA)(VAR(data_channel)); /* start read cycle*/
}











