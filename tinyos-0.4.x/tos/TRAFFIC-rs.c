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

/* Utility functions */

typedef struct{
    char high_time;
    int time;
} LogRec;

#define MAX_HOPS 10
typedef struct {
    char nhops;
    char route[MAX_HOPS];
    int time;
    int localtime;
    int delayest;
} MagellanMsg;

struct adc_packet{
    int count;
    int data[DATA_LENGTH/sizeof(int) - 1];
};

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
    volatile char led_on;			/* counter state */
    volatile char count;			/* Component counter state */
    TOS_Msg buffer[1];
    TOS_Msg read_msg[2];
    TOS_Msg LogBuf;
    TOS_MsgPtr msg;
    char log_place;
    char read_msg_ptr;
    int max_log;
    int entry;
    char start;
    volatile char send_pending;
    int delayestimate;
    int time;
    char high_time;
    struct filt_mag_channel channel1;
    struct filt_mag_channel channel2;
    //least squares stuff.
    short data[9];
    char node[9];
    int estimate[30];
    short s[2];
    volatile short n;
    volatile char ncount;
    short speed, car_time;
    short det;
    short mat[2][2];
}
TOS_FRAME_END(TRAFFIC_frame);


/* TRAFFIC_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/

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
    TOS_CALL_COMMAND(TRAFFIC_LEDy_off)();   
    TOS_CALL_COMMAND(TRAFFIC_LEDr_off)();
    TOS_CALL_COMMAND(TRAFFIC_LEDg_off)();       /* light LEDs */
    TOS_CALL_COMMAND(TRAFFIC_SUB_INIT)();       /* initialize lower components */
    TOS_CALL_COMMAND(TRAFFIC_CLOCK_INIT)(128, 2);    /* set clock interval */
    VAR(send_pending) = 0;
    VAR(time) = 0;
    VAR(high_time) = 0;
    VAR(entry) = 0;
    VAR(max_log) = 0;
    VAR(read_msg_ptr) = 0;
    VAR(n) = 0;
    VAR(ncount) = 0;
    VAR(start) = 0;
    VAR(msg) = &(VAR(buffer)[0]);
    {
	int i;
	for(i=0;i<30;i++){
        	VAR(estimate)[i] = i << 2;
	}
    }
    printf("MAGS initialized\n");
    return 1;
}

/* TRAFFIC_START
   start data reading.
*/
char TOS_COMMAND(TRAFFIC_START)(){
    //TOS_CALL_COMMAND(TRAFFIC_GET_DATA)(MAG_CHANNEL1); /* start data reading */
    return 1;
}
//data is ready.



void signal_event(){
	//construct a log pointer.
	LogRec* log = (LogRec*)(VAR(LogBuf).data);
	MagellanMsg *msg = (MagellanMsg*)VAR(buffer)[0].data;
	//add this data to the log.
	log[(int)VAR(log_place)].high_time = VAR(high_time) & 0x3;
	log[(int)VAR(log_place)].high_time |= TOS_LOCAL_ADDRESS << 3;
	log[(int)VAR(log_place)].time = VAR(time);
	VAR(log_place) ++;

	//if log full, write it out.
	if(VAR(log_place) == 10){
        	VAR(max_log) ++;
		TOS_CALL_COMMAND(TRAFFIC_APPEND_LOG)(VAR(LogBuf).data);
		VAR(log_place) = 0;
	}
	//put the record in a message
	if (VAR(send_pending == 0)) {
	    msg->nhops = 1; 
	    msg->route[0] = TOS_LOCAL_ADDRESS;
	    TOS_CALL_COMMAND(TRAFFIC_CLOCK_GET_TIME)(&(msg->time));
	    TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(mags_msg),&VAR(buffer)[0]);
	}
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
    ch->first   = ch->first - (ch->first   >> 3);
    ch->first   += ch->reading;
    ch->second   = ch->second   - (ch-> second   >> 3);
    ch->second   += ch->first >> 3;
    ch->diff   = ch->diff - (ch-> diff   >> 3);
    tmp = ch-> first - ch-> second  ;
    if(tmp < 0) tmp = -tmp;
    ch-> diff   += tmp;
    if((ch-> diff   >> 3) > 85){
	if(VAR(led_on) == 0) {
		signal_event();
		VAR(led_on) = 45;
	}
    }
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

/*   
     data: msg buffer passed
     on arrival, flash the y LED
*/
char seen_msg(TOS_MsgPtr msg) {
    char i; 
    MagellanMsg *data = (MagellanMsg *) msg->data;
    for(i = 0; i < data->nhops; i++) {
	if (data->route[i] == TOS_LOCAL_ADDRESS) 
	    return 1;
    }
    return 0;
}

TOS_MsgPtr TOS_MSG_EVENT(mags_est_delay)(TOS_MsgPtr msg) {
    MagellanMsg *data = (MagellanMsg *)msg->data;
    TOS_MsgPtr tmp;
    int now;
    if (data->nhops == 1) { // respond
	if (VAR(send_pending) == 0) {
	    data->nhops = 2;
	    data->route[1] = TOS_LOCAL_ADDRESS;
	    VAR(send_pending) = TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(data->route[0],
								       /*AM_MSG(mags_est_delay)*/ 8,
						   msg);
	    tmp = VAR(msg);
	    VAR(msg) = msg;
	    msg = tmp;
	}
    } else if ((data->nhops == 2) && (data->route[0] == TOS_LOCAL_ADDRESS) &&
	       VAR(delayestimate) == -1) {
	TOS_CALL_COMMAND(TRAFFIC_CLOCK_GET_TIME)(&now);
	VAR(delayestimate) = (now - data->time) >> 1;
    }
    return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(update_time) (TOS_MsgPtr msg){
    MagellanMsg*data = msg->data;
    int now;
    TOS_CALL_COMMAND(TRAFFIC_CLOCK_GET_TIME)(&now);
    if (data->time + data->delayest - 1 >= now) {
	now = data->time;
    }
}     

TOS_MsgPtr TOS_MSG_EVENT(mags_msg)(TOS_MsgPtr msg){
    MagellanMsg * data = (MagellanMsg*)msg->data;
    TOS_MsgPtr tmp;
    char i, nid;
    if (seen_msg(msg) ) { // it is an old message, drop it
	return msg;
    } else {
	nid = data->route[0];
	for (i = 0; i < VAR(n); i++) {
	    if (VAR(node)[i] == nid) {
		if (VAR(data)[i] >= data->time)
		    return msg;
	    }
	}
	VAR(node)[VAR(n)] = data->route[0];
	VAR(data)[VAR(n)] = data->time;
	VAR(n) ++;
	TOS_CALL_COMMAND(TRAFFIC_LEDy_on)();   
	// forward the message
	if (data->nhops < MAX_HOPS) {
	    data->route[data->nhops++] = TOS_LOCAL_ADDRESS;
	    if (VAR(send_pending == 0)) {
		VAR(send_pending) = TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(mags_msg),msg);
		tmp = VAR(msg);
     		VAR(msg) = msg;
		msg = tmp;
	    }	
	}
	VAR(ncount) = 64;
	if(VAR(n) > 4) VAR(ncount) = 2;
	return msg;
    }
}

/* Clock Event Handler: 
   signaled at end of each clock interval.

 */
void TOS_EVENT(TRAFFIC_CLOCK_EVENT)(){
    /*    if(++ VAR(time) == 0){
	 VAR(high_time) ++;
	 }*/
    /*    TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR,
	  AM_MSG(mags_est_delay), );*/
    //TOS_CALL_COMMAND(TRAFFIC_GET_DATA)(MAG_CHANNEL1); /* start data reading */
    if(VAR(led_on) != 0) {
	VAR(led_on) --;
    	TOS_CALL_COMMAND(TRAFFIC_LEDy_on)();   
    }else{
    	//TOS_CALL_COMMAND(TRAFFIC_LEDy_off)();   
    }
    if(VAR(ncount) != 0){
	VAR(ncount) --;
	if(VAR(ncount) == 0) {
		TOS_POST_TASK(step_1);
	}
    }else{
	if((((VAR(time) >> 4) & 0xff) ^ TOS_LOCAL_ADDRESS) == 0){
		send_time_update();
	}
    }
	    
}
char TOS_EVENT(TRAFFIC_WRITE_LOG_DONE)(char success){
	return 1;
}

char TOS_EVENT(TRAFFIC_READ_LOG_DONE)(char* data, char success){
	if(VAR(start) == 1){
		VAR(entry) ++;
		VAR(start) = 0;
		TOS_CALL_COMMAND(TRAFFIC_READ_LOG)(VAR(entry),VAR(read_msg)[1].data);
		TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_UART_ADDR,0x07,&(VAR(read_msg)[0]));
	}
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
			TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR,0x07,&(VAR(read_msg)[(int)VAR(read_msg_ptr)]));
		} 
		
	} else if (msg == VAR(msg)) {
	    if (VAR(send_pending) == 1) {
		VAR(send_pending) = 2;
		TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(0x7e, msg->type, msg);
	    } else {
		VAR(send_pending) = 0;
	    }
	}	    
	return 0;
}
TOS_MsgPtr TOS_EVENT(TRAFFIC_TIME_UPDATE_MSG)(TOS_MsgPtr msg){
    LogRec* log = (LogRec*)msg->data;
    if(log->high_time >= VAR(high_time)){
	if(log->time > VAR(time)){
		VAR(time) = log->time;
	}
	VAR(high_time) = log->high_time;
    }
    return msg;
}
TOS_MsgPtr TOS_EVENT(TRAFFIC_READ_MSG)(TOS_MsgPtr msg){
	char* data = msg->data;
	int log_line = data[1] & 0xff;
	log_line |= data[0] << 8;
	VAR(entry) = log_line;
	VAR(start) = 1;
	VAR(read_msg_ptr) = 0;
        TOS_CALL_COMMAND(TRAFFIC_READ_LOG)(log_line,VAR(read_msg)[0].data);
        return msg;
}

TOS_TASK(step_1){
	char i;
	int sv, sv2;
	int s0, s1;
	s0 = s1 = sv = sv2 = 0;
	
	//build the matrix on the first task
	for(i = 0; i < VAR(n); i ++){
		int val = VAR(estimate)[VAR(node)[i]];
		int dta = VAR(data)[i] - VAR(car_time);
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
	VAR(mat)[1][0] = VAR(mat)[0][1];
	TOS_POST_TASK(step_2);
}

TOS_TASK(step_2){
	//invert A*A' on the next task.
	VAR(det )= VAR(mat)[1][1] * VAR(n )- VAR(mat)[1][0] * VAR(mat)[1][0];
	VAR(mat)[0][0] = VAR(n);
	
	printf("m %d\n", VAR(mat)[0][0]);
	printf("m %d\n", VAR(mat)[0][1]);
	printf("m %d\n", VAR(mat)[1][0]);
	printf("m %d\n", VAR(mat)[1][1]);

	if(VAR(det) == 0) return;
	VAR(speed)= (VAR(mat)[0][0] * VAR(s)[0] + VAR(s)[1] * VAR(mat)[0][1])/VAR(det);
	printf("speed %d\n", VAR(speed));
	if(VAR(speed) == 0) return;
	VAR(car_time)+= (VAR(mat)[1][0] * VAR(s)[0] + VAR(s)[1] * VAR(mat)[1][1])/VAR(det);
	printf("s1 %d\n", VAR(s)[0]);
	printf("s2 %d\n", VAR(s)[1]);
	printf("det %d\n", VAR(det));
	printf("car_time %d\n", VAR(car_time));
    		TOS_CALL_COMMAND(TRAFFIC_LEDg_on)();   
	TOS_POST_TASK(step_3);
}
TOS_TASK(step_3){
	char i;
	int data, tmp;
	char index;
	for(i = 0; i < VAR(n); i ++){
	    index = VAR(node)[i];
	    data = VAR(data)[i];
	    
		printf("e %d,", VAR(estimate)[index]);
		tmp = (VAR(estimate)[index] << 3) - VAR(estimate)[index] + (data - VAR(car_time)) / VAR(speed);
		VAR(estimate)[index] = tmp >> 3; 
                printf("e %d\n", (data - VAR(car_time))/VAR(speed));
                printf("e %d\n", VAR(estimate)[index]);
        }
	{
		int* foo = (int*)VAR(buffer)[0].data;
		foo[0] = VAR(speed);
		foo[1] = VAR(car_time);
    		TOS_CALL_COMMAND(TRAFFIC_LEDr_on)();   
  		TOS_CALL_COMMAND(TRAFFIC_SUB_SEND_MSG)(TOS_BCAST_ADDR,19,&VAR(buffer)[0]);
		VAR(n) = 0;
	}
		
}
