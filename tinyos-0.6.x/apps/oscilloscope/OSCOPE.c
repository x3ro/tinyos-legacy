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
 *
 *
 *
 * This appilcaton periodically samples the ADC and sends packet full of data out over the 
 * UART.  There are 10 readings per packet.
 *
 *
 */

#include "tos.h"
#include "OSCOPE.h"
#include "dbg.h"
/* Utility functions */

#define OSCOPE_MSG_TYPE 10 
#define READINGS_PER_PACKET 10 
#define DATA_CHANNEL 1

struct data_packet{
    unsigned int source_mote_id;
    unsigned int last_reading_number;
    unsigned int channel;
    int data[READINGS_PER_PACKET];
};

#define TOS_FRAME_TYPE OSCOPE_frame
TOS_FRAME_BEGIN(OSCOPE_frame) {
    volatile char led_on;			/* counter state */
    volatile char state;			/* Component counter state */
    unsigned int reading_number;
    char curr;
    TOS_Msg msg[2];
    volatile char send_pending;
    short local_data[8];
    char data_channel;
}
TOS_FRAME_END(OSCOPE_frame);


/* OSCOPE_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/

char TOS_COMMAND(OSCOPE_INIT)(){
    TOS_CALL_COMMAND(OSCOPE_LEDy_off)();   
    TOS_CALL_COMMAND(OSCOPE_LEDr_off)();
    TOS_CALL_COMMAND(OSCOPE_LEDg_off)();       /* light LEDs */
    TOS_CALL_COMMAND(OSCOPE_SUB_INIT)();       /* initialize lower components */
    TOS_CALL_COMMAND(OSCOPE_CLOCK_INIT)(128, 3);    /* set clock interval */
    VAR(curr) = 0;
    VAR(state) = 0;
    VAR(send_pending) = 0;
    VAR(reading_number) = 0;
    VAR(data_channel) = DATA_CHANNEL;

    //turn on the sensors so that they can be read.
    SET_PW1_PIN();
    SET_PW2_PIN();
    dbg(DBG_BOOT, ("OSCOPE initialized\n"));
    return 1;
}

/* OSCOPE_START
   start data reading.
*/
char TOS_COMMAND(OSCOPE_START)(){
    return 1;
}


char TOS_EVENT(OSCOPE_CHANNEL1_DATA_EVENT) (short data) {
    struct data_packet* pack = (struct data_packet*)(VAR(msg)[(int)VAR(curr)].data);
    dbg(DBG_USR1, ("data_event\n"));
    pack->data[(int)VAR(state)] = data;
    VAR(state) ++;
    VAR(reading_number) ++;
    if(VAR(state) == READINGS_PER_PACKET){
	VAR(state) = 0;
	pack->channel = VAR(data_channel);
	pack->last_reading_number = VAR(reading_number);
	pack->source_mote_id = TOS_LOCAL_ADDRESS;
  	if (TOS_CALL_COMMAND(OSCOPE_SUB_SEND_MSG)(TOS_UART_ADDR,OSCOPE_MSG_TYPE,&VAR(msg)[(int)VAR(curr)])) {
	    VAR(send_pending)++;
	    VAR(curr) ^= 0x1;
    if(VAR(curr))TOS_CALL_COMMAND(OSCOPE_LEDy_on)();
    else TOS_CALL_COMMAND(OSCOPE_LEDy_off)();
		
	    return 1;
	} else {
	    return 0;
  	}
    }
    if(data > 0x20)TOS_CALL_COMMAND(OSCOPE_LEDr_on)();
    else TOS_CALL_COMMAND(OSCOPE_LEDr_off)();
    return 1;
}



/*   OSCOPE_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(OSCOPE_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
    VAR(send_pending) --;
    return 1;
}


/* Clock Event Handler: 
   signaled at end of each clock interval.

 */
void TOS_EVENT(OSCOPE_CLOCK_EVENT)(){
    TOS_CALL_COMMAND(OSCOPE_GET_DATA)(VAR(data_channel)); /* start data reading */
}

TOS_MsgPtr TOS_MSG_EVENT(RESET_COUNTER)(TOS_MsgPtr msg){
	VAR(reading_number) = 0;
	return msg;
}

