/*									tab:4
 * MAGS.c - periodically emits an active message containing light reading
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
 * Authors:   Jason Hill
 * History:   created 2/25/2001
 *
 *
 */

#include "tos.h"
#include "TRAFFIC.h"
#include "system/include/2xmagvd.h"


/*
 * Message types:
 	6 -- data event, contains time and node id.
	7 -- data read out of the log after a data query
	8 -- time update, contains current time.
	9 -- data query, causes data to be set out.
	26 --
	
 	
 */



#define MAX_READINGS 9

/* Utility functions */

typedef struct{
    long time;
} TimeUpdate;


typedef struct {
    char nid;
    long time;
} MagellanMsg;

typedef struct {
    int speed;
    int det;
    long time;
    char id;
} CarEvent;

struct filt_mag_channel {
    int first;
    int second;
    int diff;
    int reading;
};

TOS_TASK(step_1);
TOS_TASK(step_2);
TOS_TASK(step_3);

#define TOS_FRAME_TYPE TRAFFIC_frame
TOS_FRAME_BEGIN(TRAFFIC_frame) {
    volatile int mag_hold;			/* counter state */
    TOS_Msg buffer[1];
    TOS_Msg read_msg[2];
    char log_count;
    char read_msg_ptr;
    unsigned int max_log;
    unsigned int entry;
    char delay;
    char start;
    volatile char send_pending;
    long time;
    struct filt_mag_channel channel1;
    struct filt_mag_channel channel2;
    //least squares stuff.
    short data[MAX_READINGS];
    char node[MAX_READINGS];
    int estimate[30];
    short s[2];
    volatile short n;
    volatile char ncount;
    short speed;
    short intercept;
    short x_base;
    long  car_time;
    short det;
    short mat[2][2];
}
TOS_FRAME_END(TRAFFIC_frame);


//utility functions to deal with variable potentometer.
static void decrease_r(char channel) {
    SET_UD_PIN();
    if (channel == 0) 
	CLR_MAG_POT1_PIN();
    else
	CLR_MAG_POT2_PIN();
    SET_INC_PIN();
    CLR_INC_PIN();
    if (channel == 0) {
	SET_MAG_POT1_PIN();
    } else{
	SET_MAG_POT2_PIN();
    }
}

static void increase_r(char channel) {
    CLR_UD_PIN();
    if (channel == 0) {
	CLR_MAG_POT1_PIN();
    } else{
	CLR_MAG_POT2_PIN();
    }
    SET_INC_PIN();
    CLR_INC_PIN();
    if (channel == 0) {
	SET_MAG_POT1_PIN();
    }else{
	SET_MAG_POT2_PIN();
    }
}


char TOS_COMMAND(TRAFFIC_INIT)(){
    SET_MAG_POT1_PIN();
    SET_MAG_POT2_PIN();
    CLR_MAG_POWER_PIN();
    TOS_CALL_COMMAND(TRAFFIC_LEDy_off)();   
    TOS_CALL_COMMAND(TRAFFIC_LEDr_off)();
    TOS_CALL_COMMAND(TRAFFIC_LEDg_off)();       /* light LEDs */
    TOS_CALL_COMMAND(TRAFFIC_SUB_INIT)();       /* initialize lower components */
    TOS_CALL_COMMAND(TRAFFIC_CLOCK_INIT)(128, 2);    /* set clock interval */
    VAR(send_pending) = 0;
    VAR(time) = 0;
    VAR(log_count) = 0;
    VAR(max_log) = 0;
    VAR(read_msg_ptr) = 0;
    VAR(n) = 0;
    VAR(ncount) = 0;
    VAR(start) = 0;
    {
	int i;
        	//VAR(estimate)[0] = 0;
	for(i=0;i<30;i++){
        	//VAR(estimate)[i] = VAR(estimate)[i-1] + 32;
        	VAR(estimate)[i] = i << 5;
	}
    }
    printf("MAGS initialized\n");
    return 1;
}

/* TRAFFIC_START
   start data reading.
*/
char TOS_COMMAND(TRAFFIC_START)(){
    return 1;
}

void addpoint(char nid, long time) {
    char i, n;
    MagellanMsg *msg;
    n = VAR(n);
    for (i=0; i < n; i++) {
	if (VAR(node)[(int)i] == nid) {
		return;
	}
    }
    /* store the data */
    if (n == 0){
	 VAR(car_time) = time;
	 VAR(x_base) = VAR(estimate)[(int)nid]; 
    }
    if (n < MAX_READINGS) { //make sure no overflows
	VAR(node)[(int)n] = nid;
	VAR(data)[(int)n] = time - VAR(car_time);
	VAR(n) = n + 1;
    }
    if (VAR(send_pending) == 0) {
	msg = (MagellanMsg *)(VAR(buffer)[0].data);
	msg->nid = nid;
	msg->time = time;
	VAR(send_pending) = 
	    TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR,
						   AM_MSG(mags_msg), VAR(buffer));
    }
    VAR(ncount) = 128;
    if (VAR(n) > 4)
	VAR(ncount) = 2;
}


void filter_channel(char channel) {
    int tmp;
    struct filt_mag_channel *ch;
    
    if(channel == 0){
	ch = &(VAR(channel1));
    }else{
	ch = &(VAR(channel2));
    }
  	if(ch->reading > 0x3ff - 230){
	    decrease_r(channel);
	} else if(ch->reading < 230){
	    increase_r(channel);
	}
    ch->first = ch->first - (ch->first   >> 3);
    ch->first += ch->reading;
    ch->second = ch->second   - (ch-> second   >> 3);
    ch->second += ch->first >> 3;
    ch->diff = ch->diff - (ch-> diff   >> 3);
    tmp = ch-> first - ch-> second  ;
    if(tmp < 0) tmp = -tmp;
    ch-> diff += tmp;
    if(ch-> diff > 680){
	if(VAR(mag_hold) == 0) {
	    addpoint(TOS_LOCAL_ADDRESS, VAR(time));
	    ((int*)(VAR(buffer)[0].data))[5] = ch->diff; 
    	    //TOS_CALL_COMMAND(TRAFFIC_LEDy_on)();   
	    VAR(mag_hold) = 145;
	}
    }
    	   TOS_CALL_COMMAND(TRAFFIC_LEDy_off)();   
    	   TOS_CALL_COMMAND(TRAFFIC_LEDr_off)();   
    	   TOS_CALL_COMMAND(TRAFFIC_LEDg_off)();   
}

TOS_TASK(FILTER_DATA1){
    filter_channel(0);
}

TOS_TASK(FILTER_DATA2) {
    filter_channel(1);
}

char TOS_EVENT(TRAFFIC_CHANNEL1_DATA_EVENT) (int data) {
	VAR(channel1).reading = data;
	TOS_POST_TASK(FILTER_DATA1);
    TOS_CALL_COMMAND(TRAFFIC_GET_DATA)(MAG_CHANNEL2);
    return 1;
}

char TOS_EVENT(TRAFFIC_CHANNEL2_DATA_EVENT) (int data) {
    VAR(channel2).reading = data;
    TOS_POST_TASK(FILTER_DATA2);
    return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(mags_msg)(TOS_MsgPtr msg){
    MagellanMsg *adu = (MagellanMsg *) msg->data;
    TOS_CALL_COMMAND(TRAFFIC_LEDy_on)();   
    addpoint(adu->nid, adu->time);
    return msg;
}

static inline void send_time_update(){
    TimeUpdate* log = (TimeUpdate*)VAR(buffer)[0].data;
    long time = VAR(time) + 1;
    log->time = time;
    TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(0xff,AM_MSG(TRAFFIC_TIME_UPDATE_MSG),&VAR(buffer)[0]);
}

void TOS_EVENT(TRAFFIC_CLOCK_EVENT)(){
    if( ++ VAR(time) < 0) return;
    
    TOS_CALL_COMMAND(TRAFFIC_GET_DATA)(MAG_CHANNEL1); /* start data reading */
    if(VAR(mag_hold) != 0) {
        VAR(mag_hold) --;
    }else{
    	TOS_CALL_COMMAND(TRAFFIC_LEDy_off)();   
    }
    if(VAR(mag_hold) == 255){
    	CLR_MAG_POWER_PIN();
    }

    if(VAR(ncount) != 0){
	VAR(ncount) --;
	if(VAR(ncount) == 0) {
	  TOS_POST_TASK(step_1);
	}
    }else{
	if((((char)VAR(time)) & 0xff) == ((TOS_LOCAL_ADDRESS << 3) & 0xff)){
		send_time_update();
	}
    }	    
    
    if (VAR(start) == 1){
      if (VAR(delay) == 0){
	VAR(start) = 0;
	VAR(read_msg_ptr) = 1;
	TOS_CALL_COMMAND(TRAFFIC_READ_LOG)(VAR(entry), VAR(read_msg)[0].data);
	TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR,0x07,&(VAR(read_msg)[1]));
      } else{
	VAR(delay)--;
      }
    }
}

char TOS_EVENT(TRAFFIC_WRITE_LOG_DONE)(char success){
	return 1;
}

char TOS_EVENT(TRAFFIC_READ_LOG_DONE)(char* data, char success){
  return 1;
}
/*   TRAFFIC_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(TRAFFIC_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
	if(msg == &(VAR(read_msg)[(int)VAR(read_msg_ptr)])) {
		VAR(entry)++;
        	if(VAR(entry) <= VAR(max_log)){
		  TOS_CALL_COMMAND(TRAFFIC_READ_LOG)(VAR(entry),VAR(read_msg)[(int)VAR(read_msg_ptr)].data);
		  VAR(read_msg_ptr) ^= 1;
		  TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(TRAFFIC_READ_MSG),&(VAR(read_msg)[(int)VAR(read_msg_ptr)]));
		} 
	}else{
        	VAR(send_pending) = 0;
	}
	return 0;
}

TOS_MsgPtr TOS_EVENT(TRAFFIC_TIME_UPDATE_MSG)(TOS_MsgPtr msg){
    TimeUpdate* log = (TimeUpdate*)msg->data;
    if(log->time > VAR(time)){
	VAR(time) = log->time;
    }
    return msg;
}


TOS_MsgPtr TOS_EVENT(TRAFFIC_READ_MSG)(TOS_MsgPtr msg){
	//handler id 7
  if (VAR(start) == 1 && VAR(delay) != 0){
    VAR(start) = 0;
    VAR(delay) = 0;
  }
  return msg;
}

TOS_MsgPtr TOS_EVENT(TRAFFIC_RESET)(TOS_MsgPtr msg){
	//handler id 10.
    TOS_CALL_COMMAND(TRAFFIC_INIT)();       
    VAR(mag_hold) = 32 * 60 * msg->data[0];
    if(VAR(mag_hold) > 256){
   	 SET_MAG_POWER_PIN();
    }
    return msg;
}

TOS_MsgPtr TOS_EVENT(TRAFFIC_START_TO_SEND)(TOS_MsgPtr msg){
	//handler id 9
  /* Plane signals start to send event */
  if(VAR(max_log) == 0) return msg;
  VAR(entry) = VAR(max_log) - 50;
  if(VAR(entry) < 0) VAR(entry) = 0;
  VAR(delay) = ((VAR(time) & 0xff) ^ TOS_LOCAL_ADDRESS) & 0x1f;
  VAR(start) = 1;
  return msg;
}


TOS_TASK(step_1){
	char i;
	/*	VAR(mat)[1][1] = 0;
	VAR(mat)[0][1] = 0;
	VAR(s)[0] = 0;
	VAR(s)[1] = 0;*/
	int sv, sv2;
	int s0, s1;
	s0 = s1 = sv = sv2 = 0;
	//build the matrix on the first task
	for(i = 0; i < VAR(n); i ++){
		int val = VAR(estimate)[(int)VAR(node)[(int)i]] - VAR(x_base);
		int dta = VAR(data)[(int)i];
		printf("val %d\n", val);
		sv -= val;
		sv2 += val * val;
		s0 += val * dta;
		s1 += dta;
	}
	VAR(s)[0] = s0;
	VAR(s)[1] = s1;
	VAR(mat)[1][1] = sv2;
	VAR(mat)[0][1] = sv;
	VAR(mat)[1][0] = sv;
	TOS_POST_TASK(step_2);
}

TOS_TASK(step_2){
	//invert A*A' on the next task.
	//TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(0xff,19,&VAR(read_msg)[1]);
	VAR(det)= VAR(mat)[1][1] * VAR(n)- VAR(mat)[1][0] * VAR(mat)[1][0];
	VAR(mat)[0][0] = VAR(n);
	
	printf("m %d\n", VAR(mat)[0][0]);
	printf("m %d\n", VAR(mat)[0][1]);
	printf("m %d\n", VAR(mat)[1][0]);
	printf("m %d\n", VAR(mat)[1][1]);

	if(VAR(det) == 0) {
	//	((int*)(VAR(read_msg)[1].data))[1] = VAR(mat)[1][1];
	//	((int*)(VAR(read_msg)[1].data))[2] = VAR(mat)[1][0];
	//	((int*)(VAR(read_msg)[1].data))[3] = VAR(mat)[0][1];
	//	((int*)(VAR(read_msg)[1].data))[4] = VAR(n);
		VAR(n) = 0;
		return;
	}
	VAR(speed)= (VAR(mat)[0][0] * VAR(s)[0] + VAR(s)[1] * VAR(mat)[0][1]);
	printf("speed %d\n", VAR(speed));
	if(VAR(speed) == 0){
		VAR(n) = 0;
	//	VAR(read_msg)[1].data[7] = 10;
		return;
	}
  	VAR(intercept) = (VAR(mat)[1][0] * VAR(s)[0]/VAR(det)) + (VAR(s)[1] * VAR(mat)[1][1]/VAR(det));
	if(VAR(intercept) > (32 * 4) || VAR(intercept) < (-32 * 4)){
		VAR(n) = 0;
		VAR(intercept) = 0;
	}
	VAR(car_time)+= VAR(intercept);
	printf("s1 %d\n", VAR(s)[0]);
	printf("s2 %d\n", VAR(s)[1]);
	printf("det %d\n", VAR(det));
	printf("car_time %d\n", VAR(car_time));
	TOS_POST_TASK(step_3);
}
TOS_TASK(step_3){
	char i;
	int data, tmp;
	char index;
	int speed= 0;
	if(VAR(speed) >> 4 == 0){
		VAR(n) = 0;
	}else{
		speed = VAR(det) / (VAR(speed) >> 4);
	}
	if(speed == 0){
		VAR(n) = 0;
	}
	if(speed < (10 * 16) && speed > (-160)){
		for(i = 0; i < VAR(n); i ++){
	    		index = VAR(node)[(int)i];
	    		data = VAR(data)[(int)i];
			tmp = (VAR(estimate)[(int)index] << 3) - VAR(estimate)[(int)index] + VAR(x_base) + (((data - VAR(intercept))*speed) >> 4);
			//VAR(estimate)[(int)index] = tmp >> 3; 
        	}
	}
	{
		CarEvent* foo = (CarEvent*)VAR(read_msg)[1].data;
		foo->speed = VAR(speed);
		foo->time = VAR(car_time);
		foo->det = VAR(det);
		foo->id = TOS_LOCAL_ADDRESS;
		//foo[(int)VAR(log_count)].speed = VAR(speed);
		//foo[(int)VAR(log_count)].time = VAR(car_time);
		//foo[(int)VAR(log_count)].det = VAR(det);
		//VAR(log_count) ++;
		TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(0xff,19,&VAR(read_msg)[1]);
  		//if(VAR(log_count) == 1) {
			TOS_CALL_COMMAND(TRAFFIC_APPEND_LOG)(VAR(read_msg)[1].data);
			VAR(max_log) ++;
			//VAR(log_count) = 0;
		//}
		VAR(n) = 0;
	}
		
}
