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
 * Authors:   David Culler
 * History:   created 10/5/2000
 *
 *
 */

#include "tos.h"
#include "MAGx2.h"
#include "2xmagvd.h"

/* Utility functions */

struct adc_packet{
    short count;
    int data[5];
};

struct filt_mag_channel {
    short first;
    short second;
    short diff;
    short reading;
    short pot_wait;
};

char process_data(char channel, short data);

#define TOS_FRAME_TYPE MAGx2_frame
TOS_FRAME_BEGIN(MAGx2_frame) {
    volatile char led_on;			/* counter state */
    volatile char state;			/* Component counter state */
    TOS_Msg msg[2];
    volatile char send_pending;
    short local_data[8];
    char curr; 
    struct filt_mag_channel channel1;
    struct filt_mag_channel channel2;
}
TOS_FRAME_END(MAGx2_frame);


/* MAGx2_INIT:  
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


char TOS_COMMAND(MAGx2_INIT)(){
    unsigned char i;
    SET_MAG_POT1_PIN();
    SET_MAG_POT2_PIN();

    TOS_CALL_COMMAND(MAGx2_LEDy_off)();   
    TOS_CALL_COMMAND(MAGx2_LEDr_off)();
    TOS_CALL_COMMAND(MAGx2_LEDg_off)();       /* light LEDs */
    TOS_CALL_COMMAND(MAGx2_SUB_INIT)();       /* initialize lower components */
    TOS_CALL_COMMAND(MAGx2_CLOCK_INIT)(128, 2);    /* set clock interval */
    VAR(curr) = 0;
    VAR(state) = 0;
    VAR(send_pending) = 0;

    for (i=0; i<100; i++) {
	decrease_r(0);
	decrease_r(1);
    }

    printf("MAGS initialized\n");
    return 1;
}

/* MAGx2_START
   start data reading.
*/
char TOS_COMMAND(MAGx2_START)(){
    TOS_CALL_COMMAND(MAGx2_GET_DATA)(MAG_CHANNEL1); /* start data reading */
    return 1;
}
//data is ready.

void filter_channel(char channel) {
    struct filt_mag_channel *ch;
    int tmp;
    
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
    ch->first   = ch->first - (ch->first >> 4);
    ch->first   += ch->reading;
    ch->second   = ch->second - (ch->second >> 6);
    ch->second   += ch->first >> 6;
    ch->diff   = ch->diff - (ch->diff >> 7);
    tmp = ch-> first - ch-> second;
    if(tmp < 0) tmp = -tmp;
    ch-> diff += tmp >> 2;
    process_data(channel, ch->reading);   
}

TOS_TASK(FILTER_DATA1){
    filter_channel(0);
}

TOS_TASK(FILTER_DATA2) {
    filter_channel(1);
}

char process_data(char channel, short data){
    struct adc_packet* pack = (struct adc_packet*)(VAR(msg)[(int)VAR(curr)].data);
    printf("data_event\n");
    if(VAR(send_pending) == 2){
	return 0;
    }
    pack->data[(int)VAR(state)] = data;
    VAR(state) ++;
    if(VAR(state) == 4){
    	pack->count ++; 
	VAR(state) = 0;
  	if (TOS_CALL_COMMAND(MAGx2_SUB_SEND_MSG)(TOS_UART_ADDR,AM_MSG(mags_msg),&VAR(msg)[(int)VAR(curr)])) {
	    VAR(send_pending)++;
	    VAR(curr) ^= 0x1;
	    return 1;
	} else {
	    return 0;
  	}
    }
    return 1;
}



char TOS_EVENT(MAGx2_CHANNEL1_DATA_EVENT) (short data) {
VAR(channel1).reading = data;
TOS_POST_TASK(FILTER_DATA1);
    TOS_CALL_COMMAND(MAGx2_GET_DATA)(MAG_CHANNEL2);
    return 1;
}

char TOS_EVENT(MAGx2_CHANNEL2_DATA_EVENT) (short data) {
	VAR(channel2).reading = data;
	TOS_POST_TASK(FILTER_DATA2);
	    return 1;
}

/*   

     data: msg buffer passed
     on arrival, flash the y LED
*/
TOS_MsgPtr TOS_MSG_EVENT(mags_msg)(TOS_MsgPtr msg){
    printf("MAGS: %x, %x\n", msg->data[0], msg->data[1]);
    return msg;
}
/*   MAGx2_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(MAGx2_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
    VAR(send_pending) --;
    return 1;
}



/* Clock Event Handler: 
   signaled at end of each clock interval.

 */
void TOS_EVENT(MAGx2_CLOCK_EVENT)(){
    TOS_CALL_COMMAND(MAGx2_GET_DATA)(MAG_CHANNEL1); /* start data reading */
}

