/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:  SU Ping  
 *           Intel Research Berkeley Lab
 * Date:     3/26/2002
 */

/**
 * This application is design for packet loss testing. 
 * When a diagnostic request is received, it 
 * starts the following diagnostic process
 *  	1. create diagnostic msg using the specified pattern. 
 *  	2. sending a msg out 
 *  	3. wait for n ms 
 *	repeat step 2-3 until number of msg sent = num_of_msg_to_send
 **/

includes DiagnosticMsg;
module DiagnosticM
{
	provides {
		interface StdControl ;
		//interface DiagMsgSend ;
	}
        uses {
		interface Leds;
		interface Timer as Timer0;
		interface StdControl as CommControl;
		interface SendMsg as SendDiagMsg;
		interface ReceiveMsg as ReceiveDiagMsg;
	}
}

implementation {

    TOS_MsgPtr pmsg;
	TOS_Msg    msg;

	uint16_t seq_num; 
    volatile int8_t send_pending;
	int16_t pattern;
	uint8_t action; 
	int16_t interval; // interval between 2 diag response 
	volatile int16_t repeat_times; // number of resp. to send

 /**
  * Initialize the component. Initialize communication stack
  * 
  * @return returns <code>SUCCESS</code> or <code>FAIL</code>
  **/

command result_t StdControl.init() {

    send_pending = 0;
    pmsg = (TOS_MsgPtr)&msg;
    call Leds.init();
    return call CommControl.init(); 
}


command result_t StdControl.start(){
    return SUCCESS;
}

command result_t StdControl.stop(){
    return SUCCESS;
} 

   /**
    * Module scoped method.  save a DiagMsg data a module static variables
    * 
    *
    * @return void
    **/
	
inline void save_msg( int16_t * pack) {

	pack += 3; // skip src addr, seq. num and action

	pattern = * pack;
	pack ++;
	repeat_times = * pack;
	pack ++;
	interval=*pack;

}

inline void update_sequence_num(struct DiagRspMsg *pack) {
	pack->sequence_num =++seq_num;
}

 /** 
  *  Module task. Process a DiagMsg and send DiagRspMsg back.
  *
  **/
task void processing() {
	struct DiagRspMsg * pack;
	TOS_MsgPtr tmp=pmsg;
	int i;
	uint16_t NEW_SESSION=0;

    
	// toggle green led indicate that we have received a diagnostic msg 
   	call Leds.greenToggle();

    // start a timer
	call Timer0.start(TIMER_REPEAT, interval);
	
	// form a diag response msg
	tmp->addr = TOS_BCAST_ADDR;
	tmp->type = AM_DIAGRSPMSG;
	seq_num = NEW_SESSION;
	pack = (struct DiagRspMsg * )&(tmp->data[0]);
	pack->sequence_num = seq_num;
	pack->source_mote_id = TOS_LOCAL_ADDRESS;
	pack->param = repeat_times;
	// fill in the diag patten
        for (i=0; i<DIAG_PATTERN_REPEATS; i++)
		pack->data[i]= pattern;
	
	// send first msg to BS
	call SendDiagMsg.send(TOS_BCAST_ADDR,DIAG_RESP_LEN, pmsg);

}


/** 
 *  Handler for Timer0.fired event.
 *  Update increment the sequence number by one and 
 *  If we have send the required number of DiagRspMsg, 
 *  stop the timer. Else, send a DiagRspMsg and 
 *  decrement the msg sent counter by 1.
 *  
 *  @return returns <code>SUCCESS</code> 
**/
event result_t  Timer0.fired() {
	call Leds.redToggle();
	if ( repeat_times==0 ) {
		call Timer0.stop(); 
    } else {
		send_pending++;
		// update sequence number
		update_sequence_num((struct DiagRspMsg *)(pmsg->data));
	
		// send msg
		pmsg->type=AM_DIAGRSPMSG;
		call SendDiagMsg.send(TOS_BCAST_ADDR, DIAG_RESP_LEN, pmsg);	
		repeat_times--;
	}	
	return SUCCESS;
}

/**
 *  Handler for msg sendDone event.
 *  Toggle  yellow Led.
 *  set send_pending to 0
 *  @return returns <code>SUCCESS</code> or <code>FAIL</code>
 **/
event result_t SendDiagMsg.sendDone(TOS_MsgPtr data, result_t status){
    if (status== SUCCESS) {
		send_pending=0; 
		// toggle yellow led to indicate a diag msg is sent
		call Leds.yellowToggle();
    }    
    return status;
}

/**
 *  Handler for receving a DiagMsg event.
 *  Toggle green Led
 *  Save the received message in module varaibles
 *  post a task to proces this diagnostic requesst
 *
 *  @return a message buffer
 **/

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

    //send_pending = 0;

    // Return a message buffer to the lower levels
    return (tmp);
} 
}

