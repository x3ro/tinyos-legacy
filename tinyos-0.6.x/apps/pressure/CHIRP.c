/*									tab:4
 * CHIRP.c - periodically emits an active message containing light reading
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
#include "CHIRP.h"
#include "dbg.h"

#define MAX_CHIRPS 1000


//your FRAME
#define TOS_FRAME_TYPE CHIRP_frame
TOS_FRAME_BEGIN(CHIRP_frame) {
  char state;			/* Component counter state */
  TOS_Msg data; 		/* Message to be sent out */
  char send_pending;		/* Variable to store state of buffer*/
  unsigned short c1;
  unsigned short c2;
  unsigned short c3;
  unsigned short c4;
  unsigned short c5;
  unsigned short c6;
}
TOS_FRAME_END(CHIRP_frame);

/* CHIRP_INIT:  
   turn on the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(CHIRP_INIT)(){
  TOS_CALL_COMMAND(CHIRP_LEDy_off)();   
  TOS_CALL_COMMAND(ADG715_INIT)();
  TOS_CALL_COMMAND(CHIRP_LEDg_off)();       /* light LEDs */
  VAR(state) = 0;
  VAR(data).data[0] = TOS_LOCAL_ADDRESS; //record your id in the packet.
  TOS_CALL_COMMAND(INTERSEMA_INIT)();
  TOS_CALL_COMMAND(CHIRP_LEDr_on)();
  TOS_CALL_COMMAND(INTERSEMA_POWER)(1);
  //TOS_CALL_COMMAND(INTERSEMA_COMMAND)(1);
  TOS_CALL_COMMAND(CHIRP_CLOCK_INIT)(40,3);    /* set clock interval */
  dbg(DBG_BOOT, ("CHIRP initialized\n"));
  return 1;
}


char TOS_COMMAND(CHIRP_START)(){
    //  TOS_CALL_COMMAND(CHIRP_GET_DATA)(); /* start data reading */
  return 1;
}

/* Clock Event Handler: 
   signaled at end of each clock interval.

 */

void TOS_EVENT(CHIRP_CLOCK_EVENT)(){
  if (VAR(state) < MAX_CHIRPS && VAR(send_pending) == 0) {
      TOS_CALL_COMMAND(CHIRP_SUB_PWR)(PWR_OFF);
	TOS_CALL_COMMAND(CHIRP_SUB_PWR)(PWR_OFF);
    	TOS_CALL_COMMAND(CHIRP_LEDr_on)();
	//    	TOS_CALL_COMMAND(CHIRP_GET_DATA)(); /* start data reading */

	if (VAR(state) < 4) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(VAR(state));
	} else if (VAR(state) == 4) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(4);
	} else if (VAR(state) == 5) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(7);
	} else if (VAR(state) == 6) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(5);
	} else if (VAR(state) == 7) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(7);
	}	//increment the counter
	VAR(state) ++;
	VAR(state) &= 31;
	//turn on the red led while data is being read.
  }
}


/*  CHIRP_DATA_EVENT(data):
    handler for subsystem data event, fired when data ready.
    Put int data in a broadcast message to handler 0.
    Post msg.
 */

char TOS_EVENT(CHIRP_SET_SWITCH_DONE)(char success) {
    TOS_CALL_COMMAND(CHIRP_LEDr_off)();
    if (success) {
	TOS_CALL_COMMAND(CHIRP_LEDy_on)();
    } else {
	TOS_CALL_COMMAND(CHIRP_LEDy_off)();
    }
    return 1;
}
char TOS_EVENT(CHIRP_SET_SWITCH_ALL_DONE)(char success) {
    TOS_CALL_COMMAND(CHIRP_LEDr_off)();
    if (success) {
	TOS_CALL_COMMAND(CHIRP_LEDy_on)();
    } else {
	TOS_CALL_COMMAND(CHIRP_LEDy_off)();
    }
    return 1; 
}

char TOS_EVENT(CHIRP_GET_SWITCH_DONE)(char value) {
    TOS_CALL_COMMAND(CHIRP_LEDr_off)();
    return 1;
}

void parse_calib_data(unsigned char *calib_data) {
    unsigned short cd1, cd2, cd3, cd4; 
    cd1 = ((calib_data[0] & 0xff) << 8) + (calib_data[1] & 0xff);
    cd2 = ((calib_data[2] & 0xff) << 8) + (calib_data[3] & 0xff);
    cd3 = ((calib_data[4] & 0xff) << 8) + (calib_data[5] & 0xff);
    cd4 = ((calib_data[6] & 0xff) << 8) + (calib_data[7] & 0xff);
    //printf("0x%04x 0x%04x 0x%04x 0x%04x\n", cd1, cd2, cd3, cd4);
    VAR(c1) =  (cd1 >> 1) & 0x7fff;
    VAR(c2) = ((cd3 &0x003f) << 6) | (cd4 & 0x003f);
    VAR(c3) = (cd4 >> 6) & 0x3ff;
    VAR(c4) = (cd3 >> 6) & 0x3ff;
    VAR(c5) =  (cd2 >> 6)&0x3ff; 
    if (cd1 & 1) 
	VAR(c5) |= 0x0400;
    VAR(c6) = (cd2 &0x3f);
}

TOS_TASK(process_data) {
    long ut1;
    short dt;
    long temp;
    unsigned short d1, d2; 
    long off;
    long sens;
    long x, p;
    d1 =(VAR(data).data[11] << 8) + (VAR(data).data[12] & 0xff);
    d2 =(VAR(data).data[13] << 8) + (VAR(data).data[14] & 0xff);

    parse_calib_data(&(VAR(data).data[1]));
    ut1=20224;
    ut1 += (VAR(c5)<<3);
    dt = d2-ut1;
    temp = ((long)dt) * ((long)(VAR(c6)+50));
    temp >>= 10;
    temp += 200;
    VAR(data).data[15] = (char)(temp >> 8) & 0xff;
    VAR(data).data[16] = (char)(temp & 0xff);

    off=-512; 
    off+=VAR(c4);
    off *= dt;
    off >>= 12;
    off += (VAR(c2)<<2);

    sens = (VAR(c3) * dt) >> 10; 
    sens += VAR(c1) + 24576;
      
    x = (sens * (d1 -7168)>>14)-off;
    p = (x* 10)>>5;
    p += 2500;

    VAR(data).data[17] = (char)(p >> 8) & 0xff;
    VAR(data).data[18] = (char)(p & 0xff);

	
    TOS_CALL_COMMAND(CHIRP_SUB_PWR)(PWR_ON);
    if (VAR(send_pending) == 0) {
	if (TOS_CALL_COMMAND(CHIRP_SUB_SEND_MSG)(TOS_UART_ADDR,AM_MSG(CHIRP_MSG),&VAR(data))) {
	    VAR(send_pending) = 1;
	    TOS_CALL_COMMAND(CHIRP_LEDg_on)();
	}
    }
}

char TOS_EVENT(CHIRP_DATA_EVENT)(unsigned short data){
    if (VAR(state) <= 4){
	VAR(data).data[VAR(state)*2-1] = (char)(data >> 8) & 0xff;
	VAR(data).data[VAR(state)*2] =   (char)(data & 0xff);
    } else if (VAR(state) == 6) {
 	VAR(data).data[11] = (char)(data >> 8) & 0xff;
	VAR(data).data[12] = (char)(data & 0xff) ;
    } else if (VAR(state) == 8) {
 	VAR(data).data[13] = (char)(data >> 8) & 0xff;
	VAR(data).data[14] = (char)(data & 0xff);
    TOS_POST_TASK(process_data);
    }
    return 1;
}

/*   CHIRP_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(CHIRP_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
	//check to see if the message that finished was yours.
	//if so, then clear the send_pending flag.
  if(&VAR(data) == msg){ 
	  VAR(send_pending) = 0;
	  TOS_CALL_COMMAND(CHIRP_LEDg_off)();
  }
  return 1;
}

/*   AM_msg_handler_0      handler for msg of type 0

     data: msg buffer passed
     on arrival, flash the y LED
*/
TOS_MsgPtr TOS_MSG_EVENT(CHIRP_MSG)(TOS_MsgPtr data){
  TOS_CALL_COMMAND(CHIRP_LEDy_on)();
  dbg(DBG_USR1, ("CHIRP: %x, %x\n", data->data[0], data->data[1]));
  return data;
}


