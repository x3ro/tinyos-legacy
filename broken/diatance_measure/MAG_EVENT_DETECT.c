#include "tos.h"
#include "MAG_EVENT_DETECT.h"


//this component runs the threshoding and the baseline detection using 2 filters





#define MAG_THRESHOLD 0x3f
#define STABLE_TIME 10
#define SAMP_PER_SECOND 32
#define MAG_EVENT_DETECT_SEND_RATE 7, 0x5
#define OFF_RANGE_MAX 32
#define AVG_UPDATE_RATE 0 

#define TOS_FRAME_TYPE MAG_EVENT_DETECT_obj_frame
TOS_FRAME_BEGIN(MAG_EVENT_DETECT_obj_frame) {
	uint16_t x_avg;
	uint16_t x_val;
	uint16_t y_avg;
	uint16_t y_val;

	unsigned short stable;
	short off_range_count_x;
	short off_range_count_y;

	short magnitude;
	unsigned char mag_sent_ctr;
	unsigned char potx;
	unsigned char poty;
	
	char new_pot_y;
	char new_pot_x;
	short data_hold;
	unsigned char avg_change_rate;
}
TOS_FRAME_END(MAG_EVENT_DETECT_obj_frame);

char TOS_COMMAND(MAG_EVENT_DETECT_INIT)(){
    //initialize sub components
   TOS_CALL_COMMAND(MAG_INIT)();
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
		TOS_CALL_COMMAND(MAG_SET_POT_Y)(VAR(potx));
		VAR(new_pot_x) = 1;
	}
	TOS_CALL_COMMAND(MAG_GET_YDATA)();
}
char TOS_EVENT(MAG_DATAX_READY)(short data){
	VAR(data_hold) = data;
	TOS_POST_TASK(check_X);
	return 1;
}

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
		TOS_CALL_COMMAND(MAG_SET_POT_X)(VAR(poty));
		VAR(new_pot_y) = 1;
	}
	if(VAR(mag_sent_ctr) > 0){
	   VAR(mag_sent_ctr) --;
	} else if(VAR(stable) == 0){
	  short x_mag = (VAR(x_avg) >> 2) - (VAR(x_val) >> 3);
	  short y_mag = (VAR(y_avg) >> 2) - (VAR(y_val) >> 3);
	  x_mag >>= 2;
	  y_mag >>= 2;
	  short magnitude = (x_mag * x_mag + y_mag * y_mag);
	  //TOS_SIGNAL_EVENT(MAG_EVENT_DETECT_DATA)(magnitude);
	  TOS_SIGNAL_EVENT(DATA_DEBUG)(magnitude, VAR(x_val) >> 3, VAR(y_val) >> 3, VAR(x_avg) >> 2, VAR(y_avg) >> 2, VAR(potx), VAR(poty));
	  VAR(mag_sent_ctr) = 4;
   	}	
}
char TOS_EVENT(MAG_DATAY_READY)(short data){
	VAR(data_hold) = data;
	TOS_POST_TASK(check_Y);
	return 1;
}
char TOS_EVENT(MAG_SET_POT_X_DONE)(char success){
	return 1;
}
char TOS_EVENT(MAG_SET_POT_Y_DONE)(char success){
	return 1;
}


