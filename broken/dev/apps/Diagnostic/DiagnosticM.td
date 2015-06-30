/*									tab:4
 * 
 *  ===================================================================
 *
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation All rights
 *  reserved. Redistribution and use in source and binary forms, with
 *  or without modification, are permitted provided that the following
 *  conditions are met:
 * 
 *	Redistributions of source code must retain the above copyright
 *	notice, this * list of conditions and the following
 *	disclaimer. Redistributions in binary form must reproduce the
 *	above copyright notice, this * list of conditions and the
 *	following disclaimer in the documentation and/or other *
 *	materials provided with the distribution. Neither the name of
 *	the Intel Corporation nor the names of its contributors may *
 *	be used to endorse or promote products derived from this
 *	software without specific * prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 *  CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS CONTRIBUTORS BE
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 *  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 *  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 *  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 *  SUCH DAMAGE.
 * 
 * ===============================================================
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

includes DiagnosticMsg;
module DiagnosticM
{
	provides {
		interface StdControl ;
		//interface DiagMsgSend ;
	}
        uses {
		interface Leds;
		interface Clock;
		interface StdControl as CommControl;
		interface SendMsg as SendDiagMsg;
		interface ReceiveMsg as ReceiveDiagMsg;
	}
}

implementation {
/* incoming diagnostic AM msg data portion format */
/* msg type = 90 */
typedef struct diag_start_s {
	uint16_t source_mote_id;
	int16_t sequence_num;  
	uint8_t action; // what kind of diagnostics to do?
	uint8_t  reserve;  // reserved for possible argument related diff. diag. action 
	int16_t pattern;
	int16_t num_of_msg_to_send;
	int16_t interval;
} diag_start_t;
   
/* responding diagnostic AM msg data portion format */
/* msg type = 91 */

typedef struct diag_data_s {
	uint16_t source_mote_id;/* this mote ID */
	uint16_t sequence_num; 
    	uint16_t param;	// for action 0 this is the total responses
	int16_t data[DIAG_PATTERN_REPEATS];
} diag_data_t;

    TOS_MsgPtr pmsg;
	TOS_Msg    msg;

	uint16_t seq_num; 
    	volatile int8_t send_pending;
	int16_t pattern;
	uint8_t action; 
	int16_t interval; // interval between 2 diag response 
	volatile int16_t repeat_times; // number of resp. to send

/* DIAG_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component variables.
*/

command result_t StdControl.init() {

    send_pending = 0;
    pmsg = &msg;

    return (call CommControl.init()); 
}


command result_t StdControl.start(){
    return SUCCESS;
}

command result_t StdControl.stop(){
    return SUCCESS;
} 

inline void save_msg( int16_t * pack) {

	pack += 3; // skip src addr, seq. num and action

	pattern = * pack;
	pack ++;
	repeat_times = * pack;
	pack ++;
	interval=*pack;

}

inline void update_sequence_num(diag_data_t *pack) {
	pack->sequence_num =++seq_num;
}


task void processing() {
	diag_data_t * pack;
	TOS_MsgPtr tmp=pmsg;
	int8_t ticks, scale; //clock ticks under certain scale 
	int i;
	uint16_t NEW_SESSION=0;

    
	// toggle green led indicate that we have received a diagnostic msg 
   	call Leds.greenToggle();

    // init clock
	if ( interval > 4000 ) interval = 4000;
	if ( interval <=250 ) {
		ticks = 127; scale = 4;
	} else if (interval <=980) {
		ticks = ( int8_t)(interval * 0.128); scale = 6;
        } else  {
		ticks = ( int8_t)(interval * 0.032); scale = 7;
	}
	call Clock.setRate(ticks, scale); 
	// form a diag response msg
	tmp->addr = TOS_BCAST_ADDR;
	tmp->type = AM_DIAG_RESP;
	seq_num = NEW_SESSION;
	pack = (diag_data_t * )&(tmp->data[0]);
	pack->sequence_num = seq_num;
	pack->source_mote_id = TOS_LOCAL_ADDRESS;
	pack->param = repeat_times;
	// fill in the diag patten
        for (i=0; i<DIAG_PATTERN_REPEATS; i++)
		pack->data[i]= pattern;
	
	// send first msg to BS
	call SendDiagMsg.send(TOS_BCAST_ADDR,DIAG_RESP_LEN, pmsg);

}
// clock event handler
event result_t  Clock.fire() {
	call Leds.redToggle();
	send_pending++;
	// update sequence number
	update_sequence_num((diag_data_t *)(pmsg->data));
	
	// send msg
	pmsg->type=AM_DIAG_RESP;
	call SendDiagMsg.send(TOS_BCAST_ADDR, DIAG_RESP_LEN, pmsg);		
	return SUCCESS;
}

// msg send done event handler
event result_t SendDiagMsg.sendDone(TOS_MsgPtr data, result_t status){
    if (status== SUCCESS) {
	repeat_times--; send_pending--; 
	// toggle yellow led to indicate a diag msg is sent
	call Leds.yellowToggle();
        // if we have sent repeat_times msgs, stop the clock
	if ( repeat_times==0 )
	call Clock.setRate(127, 0); 
    }
    return status;
}

event TOS_MsgPtr ReceiveDiagMsg.receive(TOS_MsgPtr data) {

    int16_t * pack = (int16_t *)data->data;
    TOS_MsgPtr tmp ;
    // toggle green led indicate that we have received a diagnostic msg 
    call Leds.greenToggle();
    //CLR_YELLOW_LED_PIN();
    // hold on to the current buffer
    tmp = pmsg;
    pmsg = data; 
    // save info in frame static variables 
    save_msg(pack);

	// create a task to proces this diagnostic requesst	        
	// if the command handler failed, just drop the message, 
	// and forget that the message was pending

    post processing();

    send_pending = 0;

    // Return a message buffer to the lower levels
    return (tmp);
} 
}

