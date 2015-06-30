/*									tab:4
 * 
 *  ===================================================================================
 *
 *  IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  
 *  By downloading, copying, installing or using the software you agree to this license.
 *  If you do not agree to this license, do not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met: 
 * 
 *	Redistributions of source code must retain the above copyright notice, this 
 *  list of conditions and the following disclaimer. 
 *	Redistributions in binary form must reproduce the above copyright notice, this
 *  list of conditions and the following disclaimer in the documentation and/or other 
 *  materials provided with the distribution. 
 *	Neither the name of the Intel Corporation nor the names of its contributors may 
 *  be used to endorse or promote products derived from this software without specific 
 *  prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *  IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
 *  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
 *  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 *  POSSIBILITY OF SUCH DAMAGE.
 * 
 * ====================================================================================
 * 
 * Authors:  SU Ping  
 *           Intel Research Berkeley Lab
 * Date:     3/26/2002
 *
 * This component wait for diagnostic requessts
 * When a diagnostic request is received, it 
 * starts the following diagnostic process
 *  	1. create diagnostic msg using the specified pattern. 
 *  	2. sending a msg out 
 *  	3. wait for n ms 
 *	repeat step 2-3 until number of msg sent = num_of_msg_to_send
 */

#include "tos.h"
#include "DIAG.h"
#include "dbg.h"
#include "sensorboard.h"

#define DIAG_MSG_TYPE        90 // should move to MSG.h 
#define DIAG_RESP_TYPE       91 // should move to MSG.h
#define NEW_SESSION          0
#define PATTERN_REPEAT_TIMES 12 

/* incoming diagnostic AM msg data portion format */
/* msg type = 90 */
typedef struct diag_start_s {
	unsigned short source_mote_id;
	short sequence_num;  
	unsigned char action; // what kind of diagnostics to do?
#define PACKET_LOSS  0
#define POWER_LEVEL  1
#define HW_DIAGNOSTIC 2

	unsigned char  reserve;  // reserved for possible argument related diff. diag. action 
	short pattern;
	short num_of_msg_to_send;
	short interval;
} diag_start_t;
   
/* responding diagnostic AM msg data portion format */
/* msg type = 91 */

typedef struct diag_data_s {
	unsigned short source_mote_id;/* this mote ID */
	unsigned short sequence_num; 
    unsigned short param;	// for action 0 this is the total responses
	short data[PATTERN_REPEAT_TIMES];
} diag_data_t;

#define TOS_FRAME_TYPE DIAG_frame
TOS_FRAME_BEGIN(DIAG_frame) {
    TOS_MsgPtr pmsg;
	TOS_Msg    msg;

	unsigned short seq_num; 
    volatile char send_pending;
	short pattern;
	unsigned char action; 
	short interval; // interval between 2 diag response 
	volatile short repeat_times; // number of resp. to send
}
TOS_FRAME_END(DIAG_frame);

/* DIAG_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component variables.
*/

char TOS_COMMAND(DIAG_INIT)(){
    TOS_CALL_COMMAND(DIAG_LEDy_off)();      // diag response LED 
    TOS_CALL_COMMAND(DIAG_LEDr_on)();		// power on LED 
    TOS_CALL_COMMAND(DIAG_LEDg_off)();      // diag request LED
    TOS_CALL_COMMAND(DIAG_SUB_INIT)();       /* initialize lower components */

    VAR(send_pending) = 0;
//	VAR(seq_num) = NEW_SESSION;
	VAR(pmsg) = &VAR(msg);

    return 1;
}


char TOS_COMMAND(DIAG_START)(void){
    return 1;
}

inline void save_msg( short * pack) {

	pack += 3; // skip src addr, seq. num and action

	VAR(pattern) = * pack;
	pack ++;
	VAR(repeat_times) = * pack;
	pack ++;
	VAR(interval)=*pack;

}

inline void update_sequence_num(diag_data_t *pack) {
//	VAR(seq_num)++ ;
	pack->sequence_num =++VAR(seq_num);
}


TOS_TASK(processing) {
	diag_data_t * pack;
	TOS_MsgPtr tmp=VAR(pmsg);
	char ticks, scale; //clock ticks under certain scale 
	int i;
    
	// toggle green led indicate that we have received a diagnostic msg 
//    TOS_CALL_COMMAND(DIAG_RX_FLASH)();

    // init clock
	if ( VAR(interval) > 4000) VAR(interval) = 4000;
	if ( VAR(interval) <=250 ) {
		ticks = 127; scale = 4;
	} else if (VAR(interval) <=980) {
		ticks = ( char)(VAR(interval) * 0.128); scale = 6;
    } else  {
		ticks = ( char)(VAR(interval) * 0.032); scale = 7;
	}
	TOS_CALL_COMMAND(DIAG_CLOCK_INIT)(ticks, scale); 
	// form a diag response msg
	tmp->addr = TOS_BCAST_ADDR;
	tmp->type = DIAG_RESP_TYPE;
	VAR(seq_num) = NEW_SESSION;
	pack = (diag_data_t * )&(tmp->data[0]);
	pack->sequence_num = VAR(seq_num);
	pack->source_mote_id = TOS_LOCAL_ADDRESS;
	pack->param = VAR(repeat_times);
	// fill in the diag patten
    for (i=0; i<PATTERN_REPEAT_TIMES; i++)
		pack->data[i]= VAR(pattern);
	
	// send first msg to BS
	TOS_CALL_COMMAND(DIAG_SUB_SEND_MSG)(TOS_BCAST_ADDR, DIAG_RESP_TYPE,VAR(pmsg));

}

void TOS_EVENT(DIAG_CLOCK_EVENT)(void)
{

		// TOS_CALL_COMMAND(DIAG_CLK_FLASH)();
	    VAR(send_pending)++;
		// update sequence number
		update_sequence_num((diag_data_t *)(VAR(pmsg)->data));
	
		// send msg
		TOS_CALL_COMMAND(DIAG_SUB_SEND_MSG)(TOS_BCAST_ADDR, DIAG_RESP_TYPE,VAR(pmsg));		

}

char TOS_EVENT(DIAG_MSG_SEND_DONE)(TOS_MsgPtr data){
	VAR(repeat_times)--; VAR(send_pending)--; 
	// toggle yellow led to indicate a diag msg is sent
	TOS_CALL_COMMAND(DIAG_TX_FLASH)();
    // if we have sent repeat_times msgs, stop the clock
	if ( VAR(repeat_times)== 0 )
		TOS_CALL_COMMAND(DIAG_CLOCK_INIT)(127, 0); 
    return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(DIAG_RX_PACKET)(TOS_MsgPtr msg) {

	short * pack = (short *)msg->data;
    TOS_MsgPtr tmp ;
	// toggle green led indicate that we have received a diagnostic msg 
    TOS_CALL_COMMAND(DIAG_RX_FLASH)();
	// hold on to the current buffer
	tmp = VAR(pmsg);
	VAR(pmsg) = msg; 


	// save info in frame static variables 
    save_msg(pack);

		// create a task to proces this diagnostic requesst	        
		// if the command handler failed, just drop the message, 
		// and forget that the message was pending

	TOS_POST_TASK(processing);

    VAR(send_pending) = 0;

	// Return a message buffer to the lower levels
    return tmp;

}
