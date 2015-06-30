#include "tos.h"
#include "MAG_EVENT_DETECT.h"


//this component runs the threshoding and the baseline detection using 2 filters


#define BUFFER_SIZE 10

struct oscope_data{
    unsigned int source_mote_id;
    unsigned int last_sample_number;
    unsigned int channel;
    int data[BUFFER_SIZE];
};



#define MAG_THRESHOLD 0x3f
#define STABLE_TIME 5
#define SAMP_PER_SECOND 32
#define MAG_EVENT_DETECT_SEND_RATE 7, 0x5
#define OFF_RANGE_MAX 1
#define AVG_UPDATE_RATE 0 

#define TOS_FRAME_TYPE MAG_EVENT_DETECT_obj_frame
TOS_FRAME_BEGIN(MAG_EVENT_DETECT_obj_frame) {
    char msgIndex;            // index to the array
    char msg_pending;         // true if message pending
    TOS_Msg buffer1;           // double buffer
    TOS_Msg buffer2;           // double buffer
    TOS_MsgPtr msgPtr1;         //temperature message buffer
    TOS_MsgPtr oldmsgPtr1;      //accelerometer message buffer
    TOS_Msg buffer3;           // double buffer
    TOS_Msg buffer4;           // double buffer
    TOS_MsgPtr msgPtr2;         //temperature message buffer
    TOS_MsgPtr oldmsgPtr2;      //accelerometer message buffer
    unsigned short last_sample_number;

	uint16_t x_avg;
	uint16_t x_val;
	uint16_t y_avg;
	uint16_t y_val;

	unsigned short stable;
	unsigned short off_range_count_x;
	unsigned short off_range_count_y;

	short magnitude;
	unsigned char mag_sent_ctr;
	unsigned char potx;
	unsigned char poty;
	
	unsigned char new_pot_y;
	unsigned char new_pot_x;
	short data_hold;
	unsigned char avg_change_rate;
}
TOS_FRAME_END(MAG_EVENT_DETECT_obj_frame);

char TOS_COMMAND(MAG_EVENT_DETECT_INIT)(){
    //initialize sub components
    VAR(msgIndex) = 0;
    VAR(msg_pending) = 0; 
    VAR(msgPtr1) = &VAR(buffer1);
    VAR(oldmsgPtr1) = &VAR(buffer2);
    VAR(msgPtr2) = &VAR(buffer3);
    VAR(oldmsgPtr2) = &VAR(buffer4);
    VAR(last_sample_number) = 0;

   TOS_CALL_COMMAND(MAG_SUB_INIT)();
   VAR(stable) = SAMP_PER_SECOND * STABLE_TIME; 
   VAR(x_avg) = 0;
   VAR(y_avg) = 0;
   VAR(x_val) = 0;
   VAR(y_val) = 0;
   VAR(potx) = 128;
   VAR(poty) = 128;
   //set rate for sampling.
   TOS_COMMAND(MAG_EVENT_DETECT_SUB_CLOCK_INIT)(MAG_EVENT_DETECT_SEND_RATE);
   VAR(mag_sent_ctr) = 0;
   VAR(off_range_count_x) = 0;
   VAR(off_range_count_y) = 0;
   return 1;
}

char TOS_COMMAND(MAG_EVENT_DETECT_START)(){
	return 1;
}

void TOS_EVENT(MAG_EVENT_CLOCK_EVENT)(){
    //    TOS_CALL_COMMAND(RED_LED_TOGGLE)();
	   if(VAR(stable) > 0) VAR(stable) --;
	   TOS_CALL_COMMAND(MAG_GET_XDATA)();
}


TOS_TASK(check_X){
	short data = VAR(data_hold);
	if(VAR(stable) != 0 || VAR(avg_change_rate) == 0){
		VAR(x_avg) -= VAR(x_avg) >> 5;
		VAR(x_avg) += data >> 3;
	}
	VAR(x_val) -= VAR(x_val) >> 2;
	VAR(x_val) += data << 1;
	if(VAR(new_pot_x) == 1)  VAR(x_avg) = (data -  0xeb) << 2;
	VAR(new_pot_x) = 0;
	if(data > 700 || data < 300 || VAR(stable) > 100){
		VAR(off_range_count_x) ++;
	} else if(data < 600 || data > 400){
		VAR(off_range_count_x) = 0;
	}
	if(VAR(off_range_count_x) > OFF_RANGE_MAX || 
		(VAR(stable) != 0 && VAR(off_range_count_x) > 1)){
		if(data > 500){
			if(VAR(potx) < 255)
				VAR(potx) ++;
		}else{
			if(VAR(potx) > 0)
				VAR(potx) --;
		}
		TOS_CALL_COMMAND(MAG_SET_POT_X)(VAR(potx));
		VAR(new_pot_x) = 1;
	}
	TOS_CALL_COMMAND(MAG_GET_YDATA)();
}

#if 0
char TOS_EVENT(MAG_DATAX_READY)(short data){
	VAR(data_hold) = data;
	TOS_POST_TASK(check_X);
	return 1;
}
#else
char TOS_EVENT(MAG_DATAX_READY)(short data){
    struct oscope_data * pkt = (struct oscope_data *) VAR(msgPtr1)->data;
    TOS_MsgPtr tmp;
    unsigned short out;
    out = 70*VAR(potx) + (data>>1);
    pkt->data[VAR(msgIndex)] = out;
    //    VAR(msgIndex)++;
    TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
#if 0
    if (VAR(msgIndex) >= BUFFER_SIZE){
	pkt->source_mote_id = TOS_LOCAL_ADDRESS;
	pkt->channel = 2;
	pkt->last_sample_number = VAR(last_sample_number);
	//	VAR(last_sample_number)+=BUFFER_SIZE;
	//	VAR(msgIndex) = 0;
	if (VAR(msg_pending) == 0) {
	    VAR(msg_pending) = 1;
	    TOS_CALL_COMMAND(MAG_SEND_MSG)(TOS_BCAST_ADDR, 10, VAR(msgPtr1));
	}
	tmp = VAR(oldmsgPtr1);
	VAR(oldmsgPtr1) = VAR(msgPtr1);
	VAR(msgPtr1) = tmp;
    }
#endif
    VAR(data_hold) = data;
    TOS_POST_TASK(check_X);
    return 1;
}
#endif

TOS_TASK(check_Y){
	short data = VAR(data_hold);
	if(VAR(stable) != 0 || VAR(avg_change_rate) == 0){
		VAR(y_avg) -= VAR(y_avg) >> 5;
		VAR(y_avg) += data >> 3;
		VAR(avg_change_rate) = AVG_UPDATE_RATE;
	} else{
		VAR(avg_change_rate) --;
	}
	VAR(y_val) -= VAR(y_val) >> 2;
	VAR(y_val) += data << 1;
	
	if(VAR(new_pot_y) == 1)  VAR(y_avg) = (data-0xeb) << 2;
	VAR(new_pot_y) = 0;
	if(data > 700 || data < 300 || VAR(stable) > 100){
		VAR(off_range_count_y) ++;
	} else if(data < 600 || data > 400){
		VAR(off_range_count_y) = 0;
	}

	//POT adjustment step.
	if(VAR(off_range_count_y) > OFF_RANGE_MAX || 
		(VAR(stable) != 0 && VAR(off_range_count_y) > 1)){
		if(data > 500){
			if(VAR(poty) < 255) VAR(poty) ++;
		}else{
			if(VAR(poty) > 0) VAR(poty) --;
		}
		TOS_CALL_COMMAND(MAG_SET_POT_Y)(VAR(poty));
		VAR(new_pot_y) = 1;
	}
	if(VAR(mag_sent_ctr) > 0){
	   VAR(mag_sent_ctr) --;
	} else if(VAR(stable) == 0){
	  short x_mag = (VAR(x_avg) >> 2) - (VAR(x_val) >> 3);
	  short y_mag = (VAR(y_avg) >> 2) - (VAR(y_val) >> 3);
	  x_mag >>= 2;
	  y_mag >>= 2;
	  y_mag = 0;
	  if(x_mag < 0) x_mag = -x_mag;
	  if(x_mag > 127) x_mag = 127;
	  if(y_mag < 0) y_mag = -y_mag;
	  if(y_mag > 127) y_mag = 127;
	  short magnitude = (x_mag * x_mag + y_mag * y_mag);
	  //	  TOS_SIGNAL_EVENT(MAG_EVENT_DETECT_DATA)(magnitude);
	  //TOS_SIGNAL_EVENT(DATA_DEBUG)(magnitude, VAR(x_val) >> 3, VAR(y_val) >> 3, VAR(x_avg) >> 2, VAR(y_avg) >> 2, VAR(potx), VAR(poty));
	  VAR(mag_sent_ctr) = 4;
   	}	
}
#if 1
char TOS_EVENT(MAG_DATAY_READY)(short data){
    struct oscope_data * pkt = (struct oscope_data *) VAR(msgPtr2)->data;
    TOS_MsgPtr tmp;
    unsigned short out;
    TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
    out = 70*VAR(poty) + (data>>1);
    pkt->data[VAR(msgIndex)] = out;
    VAR(msgIndex)++;
    if (VAR(msgIndex) >= BUFFER_SIZE){
	/* configure Y-axis packet*/
	pkt->source_mote_id = TOS_LOCAL_ADDRESS;
	pkt->channel = 4;
	pkt->last_sample_number = VAR(last_sample_number);

	tmp = VAR(oldmsgPtr2);
	VAR(oldmsgPtr2) = VAR(msgPtr2);
	VAR(msgPtr2) = tmp;

	/* configure X-axis packet */
	pkt = (struct oscope_data *) VAR(msgPtr1)->data;
	pkt->source_mote_id = TOS_LOCAL_ADDRESS;
	pkt->channel = 2;
	pkt->last_sample_number = VAR(last_sample_number);

	tmp = VAR(oldmsgPtr1);
	VAR(oldmsgPtr1) = VAR(msgPtr1);
	VAR(msgPtr1) = tmp;

	/* reset data structures */
	VAR(last_sample_number)+=BUFFER_SIZE;
	VAR(msgIndex) = 0;


	if (VAR(msg_pending) == 0) {
	    VAR(msg_pending) = 1;
	    TOS_CALL_COMMAND(MAG_SEND_MSG)(TOS_BCAST_ADDR, 10, VAR(oldmsgPtr1));
	}
    }
    VAR(data_hold) = data;
    TOS_POST_TASK(check_Y);
    return 1;
}
#else
char TOS_EVENT(MAG_DATAY_READY)(short data){
	VAR(data_hold) = data;
	TOS_POST_TASK(check_Y);
	return 1;
}
#endif
char TOS_EVENT(MAG_SET_POT_X_DONE)(char success){
	return 1;
}
char TOS_EVENT(MAG_SET_POT_Y_DONE)(char success){
	return 1;
}

char TOS_EVENT(MAG_MSG_SEND_DONE)(TOS_MsgPtr msg) {
    if (msg == VAR(oldmsgPtr1)) {
	TOS_CALL_COMMAND(MAG_SEND_MSG)(TOS_BCAST_ADDR, 10, VAR(oldmsgPtr2));
    } else {
	VAR(msg_pending) = 0;
	TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
    }
    return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(RESET_MSG)(TOS_MsgPtr msg){
    short *num = msg->data;
    //    TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
    //    TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
    //    TOS_CALL_COMMAND(RED_LED_TOGGLE)();
    //      VAR(samp_on) = 1;
      TOS_CALL_COMMAND(MAG_EVENT_DETECT_SUB_CLOCK_INIT)(64, 0x02); /* every 16 milli seconds */
      //      VAR(msgIndex) = 0;
      //      VAR(last_sample_number) = 0;
      //      VAR(num_samples) = num[0];
      return msg;
}


