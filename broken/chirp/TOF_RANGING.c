/*									tab:4
 * TOF_RANGING.c 
 *
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
 * Authors:   Kamin Whitehouse 6/02/02
 *
 *
 * This component time stamps a detected tone and compares that time with 
 * the time stamp of the most recent packet.  If the tone and the packet 
 * were sent at the same time, this time represents Time of Flight (TOF).
 * Using the speed of sound and a linear calibration function on the sounder
 * and microphone, this component then converts TOF to distance.
 * 
 * There are two protocols:  when a node receives a COMMAND, it sends a CHIRP.
 * When a node receives a DATA_REQUEST, it sends a DATA_RESPONSE.  The data
 * response holds ranging info in the form of <node_ID, distance> pairs.
 */

#include "tos.h"
#include "TOF_RANGING.h"
#include "dbg.h"
#include "sensorboard.h"




#define TIME_WINDOW_SIZE 4  //don't make this larger than the min spacing between 2 false positives, which I have found to be about 10.  also make it shorter to track faster moving things.
#define TOF_RANGING_CHIRP_AM 114    //this is the AM type of messages used for the TIME_SYNC component
#define TOF_RANGING_DATA_AM 115    //this is the AM type of messages used for the TIME_SYNC component
#define NEIGHBORHOOD_SIZE 7    //this is the AM type of messages used for the TIME_SYNC component

#define DATA_REQUEST 1   //this is used by one mote to request ranging data from another
#define DATA_RESPONSE 2  // this is used by one mote to give ranging data to another
#define COMMAND 3   //this is used by external source to command the source node to chirp
#define CHIRP 4 //this is used by the node to chirp and thereby give ranging info



typedef struct {
  short msg_type;
  short context;
  short src_ID;   
  short sounder_calib_offset;
  short sounder_calib_scale;
  short mic_calib_offset;
  short mic_calib_scale;
  short chirp_number;
} tof_ranging_chirp_bfr;

typedef struct {
  short msg_type;   
  short src_ID;   
  short ranging_info[NEIGHBORHOOD_SIZE*2];
} tof_ranging_data_bfr;




short sounderTiming;
//Frame Declaration
#define TOS_FRAME_TYPE TOF_RANGING_frame
TOS_FRAME_BEGIN(TOF_RANGING_frame) {
  short current_reading_number;          //holds the index to TOF_buffer
  unsigned short TOF_buffer[TIME_WINDOW_SIZE];   //holds all the TOF readings          
  short last_packet_time;  //this is the value of the most recent TOF reading
  short last_sounderTiming;  //this is the value of the most recent TOF reading
  char mic_reboot;//this variable is used to reboot the microphone periodically
  char micGain;      //this is used to store the current mic gain setting
  short chirp_state;//this is used to say whether or not we should be chirping
  short chirp_counter; //this is used to say how many times we chirped
  short clock_counter;   //this is used to do something 3 times per second
  TOS_Msg chirp_msg;     //this is the actual buffer that holds all chirp info
  TOS_Msg data_msg;//this is the buffer that holds all local ranging info
  tof_ranging_chirp_bfr *chirp;//this points to the relevant info in the outgoing ranging-data message
  tof_ranging_data_bfr *ranging_data; //this points to the relevant info in the outgoing ranging-data message
  char chirpCount;
}
TOS_FRAME_END(TOF_RANGING_frame);



//the following variable is defined in radio_timing.c and RF_COMM.c
//but there should be some sort of interface between these components.
extern short sounderTiming;



char TOS_COMMAND(TOF_RANGING_INIT)(){
  int i;
  //initialize the state
  VAR(current_reading_number)=0;
  for(i=0;i<TIME_WINDOW_SIZE;i++){
    VAR(TOF_buffer)[i]=0;   //holds all the TOF readings          
  }
  VAR(last_packet_time)=0;
  VAR(last_sounderTiming)=0;
  VAR(mic_reboot)=0;
  VAR(micGain) = 64;    //full range is 1-255
  VAR(chirp_state)=0xff;
  VAR(chirp_counter)=0;
  VAR(clock_counter)=0;

  VAR(chirp) = (tof_ranging_chirp_bfr*)&(VAR(chirp_msg).data);
  VAR(chirp)->msg_type=CHIRP;   
  VAR(chirp)->sounder_calib_offset=0;
  VAR(chirp)->sounder_calib_scale=1;
  VAR(chirp)->mic_calib_offset=0;
  VAR(chirp)->mic_calib_scale=1;
  VAR(chirpCount) = 0;
  
  VAR(ranging_data) = (tof_ranging_data_bfr*)&(VAR(data_msg).data);
  VAR(ranging_data)->msg_type=DATA_RESPONSE;

  //start the clock (which is used for periodically rebooting the microphone)
  TOS_CALL_COMMAND(TOF_RANGING_SUB_CLOCK_INIT)(tick32ps);

  /* Turn Microphone on and set the pot for mic gain,
     use bandpass filter output, turn interrupt off*/
  TOS_CALL_COMMAND(TOF_RANGING_MIC_INIT)();
  TOS_CALL_COMMAND(TOF_RANGING_MIC_PWR)(1);
  TOS_CALL_COMMAND(TOF_RANGING_MIC_MUX_SEL)(0);
  TOS_CALL_COMMAND(TOF_RANGING_POT_ADJUST)(VAR(micGain));
  TOS_CALL_COMMAND(TOF_RANGING_MIC_TONE_INTR)(0);

  return 1;
}



char TOS_COMMAND(TOF_RANGING_START)(){
  return 1;
}




TOS_MsgPtr TOS_MSG_EVENT(TOF_RANGING_RECV_CHIRP)(TOS_MsgPtr msg){
  tof_ranging_chirp_bfr *chirp;           
  chirp = (tof_ranging_chirp_bfr*)&(msg->data);
  
  if(chirp->msg_type == COMMAND){
    VAR(chirp_state)=chirp->chirp_number;//the desired number of chirps (or 0xFF to chirp forever)
    VAR(chirp_counter)=0;
    VAR(clock_counter)=0;
  }


  else if(chirp->msg_type == CHIRP){
    //if there is valid TOF data, collect it and process it.
    if( (VAR(last_sounderTiming) == sounderTiming) && (VAR(last_packet_time) != 0) ){ //if a tone was detected and no packets have come in since
      TOS_CALL_COMMAND(TOF_RANGING_PROCESS_RANGING_INFO)(chirp->src_ID, chirp->sounder_calib_offset, chirp->sounder_calib_scale, VAR(last_packet_time)-VAR(last_sounderTiming));
    }    
    /*Turn the microphone off in case it started oscillating, and prepare to reboot it*/
    TOS_CALL_COMMAND(TOF_RANGING_MIC_TONE_INTR)(0);
    TOS_CALL_COMMAND(TOF_RANGING_MIC_PWR)(0);
    VAR(mic_reboot)=1;
    TOS_CALL_COMMAND(TOF_RANGING_LEDg_TOGGLE)();
  }
  
  return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(TOF_RANGING_RECV_DATA_MSG)(TOS_MsgPtr msg){
  tof_ranging_data_bfr *data;           
  data = (tof_ranging_data_bfr*)&(msg->data);
  
  if(data->msg_type == DATA_REQUEST){
    *((short*)&(VAR(data_msg).data[2]))=TOS_LOCAL_ADDRESS;
    TOS_CALL_COMMAND(TOF_RANGING_SEND_DATA)(data->src_ID, TOF_RANGING_DATA_AM, &VAR(data_msg));
  }
  
  
  else if(data->msg_type == DATA_RESPONSE){
  }
  
  
  return msg;
}




void TOS_EVENT(TOF_RANGING_CLOCK_EVENT)(){
  /*if I just turned off the microphone, turn it back on*/
  if(VAR(clock_counter)>=32){
    TOS_CALL_COMMAND(TOF_RANGING_CHIRP)();
    VAR(chirp_counter)++;
    VAR(clock_counter)=0;
  }

  if (VAR(mic_reboot) == 1){
    TOS_CALL_COMMAND(TOF_RANGING_MIC_PWR)(1);
    VAR(mic_reboot)=0;
  }

  VAR(clock_counter)++;
    
}



char TOS_EVENT(TOF_RANGING_MIC_TONE_DETECTED)(void){
  //notice that sounderTiming should really be called packetTiming;
  //we are timing the packet and comparing with current time.
  //sounderTiming is stored to make sure it has a new value (i.e. that this isn't a random tone)
  if (sounderTiming != VAR(last_sounderTiming)){
    VAR(last_packet_time) = __inw(TCNT1L);
    VAR(last_sounderTiming) = sounderTiming;
  }
  
  TOS_CALL_COMMAND(TOF_RANGING_LEDy_TOGGLE)();
  return 1;
}



/* This event is triggered from the ADC */
char TOS_EVENT(TOF_RANGING_DATA_EVENT)(short data){
  return 1;
}

// I hate you, Kamin. 
#define RANGING 1


/* This event is triggered by GENERIC_COMM */
char TOS_EVENT(TOF_RANGING_DATA_SEND_DONE)(TOS_MsgPtr data){
  //reset the value of the TOF to zero so we know if we got one or not
  VAR(last_packet_time)=0;
  if (VAR(chirpCount) >= TIME_WINDOW_SIZE) {
    VAR(chirpCount) = 0;
    return data;
  }
  else {
    tof_ranging_chirp_bfr* buffer = (tof_ranging_chirp_bfr*)VAR(chirp_msg).data;
    buffer->msg_type = CHIRP;
    buffer->context = RANGING;
    buffer->src_ID = TOS_LOCAL_ADDRESS;
    buffer->sounder_calib_offset = 0;
    buffer->sounder_calib_scale = 1;
    buffer->mic_calib_offset = 0;
    buffer->mic_calib_scale = 1;
    VAR(chirp_msg).length = 29;
    if (TOS_CALL_COMMAND(TOF_RANGING_SEND_DATA)(TOS_BCAST_ADDR, TOF_RANGING_CHIRP_AM, &VAR(chirp_msg))) {
      VAR(chirpCount)++;
    }
  }
  return 1;
}



char TOS_COMMAND(TOF_RANGING_SET_MIC_GAIN)(char gain){
  /*set the gain on the microphone*/
  VAR(micGain)=gain;
  TOS_CALL_COMMAND(TOF_RANGING_POT_ADJUST)(VAR(micGain));
  return 1;
}




char TOS_COMMAND(TOF_RANGING_SET_CALIBRATION)(short sounder_offset, short sounder_scale, short mic_offset, short mic_scale){
  VAR(chirp)->sounder_calib_offset=sounder_offset;
  VAR(chirp)->sounder_calib_scale=sounder_scale;
  VAR(chirp)->mic_calib_offset=mic_offset;
  VAR(chirp)->mic_calib_scale=mic_scale;
  return 1;
}


char TOS_COMMAND(TOF_RANGING_CHIRP)(void){
  tof_ranging_chirp_bfr* buffer = (tof_ranging_chirp_bfr*)VAR(chirp_msg).data;
  buffer->msg_type = CHIRP;
  buffer->context = RANGING;
  buffer->src_ID = TOS_LOCAL_ADDRESS;
  buffer->sounder_calib_offset = 0;
  buffer->sounder_calib_scale = 1;
  buffer->mic_calib_offset = 0;
  buffer->mic_calib_scale = 1;
  VAR(chirp_msg).length = 29;
 
  if (TOS_CALL_COMMAND(TOF_RANGING_SEND_DATA)(TOS_BCAST_ADDR, TOF_RANGING_CHIRP_AM, &VAR(chirp_msg))) {
    VAR(chirpCount)++;
    TOS_CALL_COMMAND(TOF_RANGING_LEDg_on)();
  }
  else {
    TOS_CALL_COMMAND(TOF_RANGING_LEDg_off)();
  }
  return 1;
}



char TOS_COMMAND(TOF_RANGING_PROCESS_RANGING_INFO)(short src_ID, short sounder_calib_offset, short sounder_calib_scale, short TOF){
  unsigned short lower_bound;
  unsigned short min1;
  unsigned short min2;
  short i;
  
  //store the reading
  VAR(TOF_buffer)[VAR(current_reading_number)] = (unsigned short)TOF;
  VAR(current_reading_number)=VAR(current_reading_number)+1;


  //if we have enough readings
  //filter them and send them off
  if(VAR(current_reading_number)==TIME_WINDOW_SIZE){
    VAR(current_reading_number)=0;
    
    //first, filter the readings: choose the min unless it is too far from the second min.  this accounts for up to one false positive
    min1=65535;//max value for a unsigned short
    for(i=0;i<TIME_WINDOW_SIZE;i++){
      if(VAR(TOF_buffer)[i]<min1){
	min1=VAR(TOF_buffer)[i];
      }
    }

    min2=65535;//max value for a unsigned short
    for(i=0;i<TIME_WINDOW_SIZE;i++){
      if( (VAR(TOF_buffer)[i]<min2) && (VAR(TOF_buffer)[i]!=min1) ){
	min2=VAR(TOF_buffer)[i];
      }
    }

    lower_bound = (min2>>4)*13-3776; //effectively, lowerBound=.8125*min-3776
    min1=min1<lower_bound ? min2 : min1; // choose the min over lower_bound

    //Here, I  turn the TOF into a distance (cm) and calibrate.
    //Speed of Sound ~= .0352 and clock ticks are every .25 microsecs,
    //so I really want to multiply by .0087
    min1>>=4;//turn clock ticks into microseconds
    min1*=9;//turn clock ticks into microseconds
    min1>>=6;//turn clock ticks into microseconds

    //the following is some preliminary calibration that should be
    //approximately correct for most sensor boards, but should be changed
    //if the sensor board changes somehow.
    min1 >>= 1;
    min1 = min1+9;

    //the following is further calibration that should be specified
    //for each individual sensor board
    //min1 = min1*sounder_calib_scale + min1*VAR(chirp)->mic_calib_scale + sounder_calib_offset + VAR(chirp)->mic_calib_offset;

    //then, send off the filtered value
    VAR(ranging_data)->src_ID=TOS_LOCAL_ADDRESS;
    VAR(ranging_data)->ranging_info[0]=src_ID;
    VAR(ranging_data)->ranging_info[1]= (short)min1;
    TOS_CALL_COMMAND(TOF_RANGING_SEND_DATA)(TOS_BCAST_ADDR, TOF_RANGING_DATA_AM, &VAR(data_msg));
  }
  
  return 1;
}

