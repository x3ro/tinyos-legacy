/*									tab:4
 * SLEEP_TEST.c - periodically emits an active message containing light reading
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
 */

#include "tos.h"
#include "SLEEP_TEST_BASE.h"
#include "dbg.h"

typedef struct {
    short address;
    short on_time;
    short off_time;
    unsigned char level;
    unsigned char phase;
    unsigned char old_time;
} beacon_msg;

// number of consecutive sleep cycles where we can miss the beacon
#define MAX_DISCONNECT 3 

// maximum allowed skew between the local clock and the beacon
#define MAX_SKEW 2

//

//your FRAME
#define TOS_FRAME_TYPE SLEEP_TEST_frame
TOS_FRAME_BEGIN(SLEEP_TEST_frame) {
    
  char state;			/* Component counter state */
  char send_pending;		/* Variable to store state of buffer*/
  TOS_Msg data; 		/* Message to be sent out */
  TOS_Msg beacon_data;
  TOS_MsgPtr bmsg;
  short count;
  short on_time;
  short off_time;
  char need_beacon;
  char alive;
}
TOS_FRAME_END(SLEEP_TEST_frame);

/* SLEEP_TEST_INIT:  
   turn on the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(SLEEP_TEST_INIT)(){
  TOS_CALL_COMMAND(SLEEP_TEST_LEDy_on)();   
  TOS_CALL_COMMAND(SLEEP_TEST_LEDr_off)();
  TOS_CALL_COMMAND(SLEEP_TEST_LEDg_off)();       /* light LEDs */
  TOS_CALL_COMMAND(SLEEP_TEST_SUB_INIT)();       /* initialize lower components */
  VAR(state) = 0;
  VAR(off_time) = 3200;
  VAR(bmsg) = &VAR(beacon_data);
  VAR(data).data[0] = TOS_LOCAL_ADDRESS; //record your id in the packet.

  VAR(alive) = 1; // We need to synchronize with the network first
  VAR(need_beacon) = 0;
  VAR(on_time) = 160;
  VAR(count) = 0;
  TOS_CALL_COMMAND(SLEEP_TEST_CLOCK_INIT)(16, 5);    /* set clock interval,
							0.25 second */
  dbg(DBG_BOOT, ("SLEEP_TEST initialized\n"));
  return 1;
}

/* FIXME */
char TOS_COMMAND(SLEEP_TEST_START)(){
    //  TOS_CALL_COMMAND(SLEEP_TEST_GET_DATA)(); /* start data reading */
    return 1;
}

/* Clock Event Handler: 
   signaled at end of each clock interval.
   
 */

void TOS_EVENT(SLEEP_TEST_CLOCK_EVENT)(){
    VAR(count)++;
    if (VAR(count) >= VAR(on_time)) {
	VAR(count) = 0;
	
	// Everytime clock ticks, decrement the alive counter. This
	// enforces how tight a synchronization we must maintain
	// with the rest of the network, how many beacons we must
	// hear.
	
	/* FIXME: for maximum flecibility, this should be invoked only when
	   some additional counter expires. As a practical matter, the on
	   cycle may be longer than the longest timer expiration. Incorporate
	   the times as soon as possible */
	
	if (VAR(alive) > 0) { 
	    TOS_CALL_COMMAND(SLEEP_TEST_LEDy_off)();
	    
	    if (VAR(send_pending) == 0) {
		TOS_CALL_COMMAND(SLEEP_TEST_LEDr_off)();
		TOS_CALL_COMMAND(SLEEP_TEST_LEDg_off)();
		TOS_CALL_COMMAND(SLEEP_TEST_SLEEP_INIT)(VAR(off_time));
	    } else {
		VAR(off_time) -= 2;
	    }
	}
    }
}

void send_beacon() {
    beacon_msg * msg = (beacon_msg *)(VAR(bmsg)->data);
    msg->address = TOS_LOCAL_ADDRESS;
    msg->phase = 20;
    msg->off_time = VAR(off_time);
    msg->on_time = VAR(on_time);
    msg->level = 1;
    if (TOS_CALL_COMMAND(SLEEP_TEST_SUB_SEND_MSG)
	(TOS_BCAST_ADDR,AM_MSG(SLEEP_TEST_MSG),VAR(bmsg))) {
    	VAR(send_pending) = 1;
    }
}

void TOS_EVENT(SLEEP_TEST_WAKEUP)() {
    send_beacon();
    VAR(need_beacon) = 0;
    TOS_CALL_COMMAND(SLEEP_TEST_LEDy_on)(); 
}

/*   SLEEP_TEST_SUB_MSG_SEND_DONE event handler:
     beacon was resent. turn off the LED
*/
char TOS_EVENT(SLEEP_TEST_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
    //check to see if the message that finished was yours.
    //if so, then clear the send_pending flag.
    if(VAR(bmsg) == msg){ 
	VAR(send_pending) = 0;
	TOS_CALL_COMMAND(SLEEP_TEST_LEDg_off)();
    }
    return 1;
}

static inline char check_skew(short phase) {
    short  tmp;
    
    tmp = VAR(count) - (phase>>4);
    if (tmp < 0 ) {
	tmp = -tmp;
    }
    return (tmp > MAX_SKEW);
}

static inline void sync_clock(short phase) {
    VAR(count) = phase >> 4;
    outp(phase & 0xf, TCNT2);
}
	


TOS_MsgPtr TOS_MSG_EVENT(SLEEP_TEST_MSG)(TOS_MsgPtr data){
    beacon_msg * msg = (beacon_msg *)data->data;
    beacon_msg * b_state = (beacon_msg *) VAR(bmsg)->data;
    VAR(alive) = MAX_DISCONNECT;
    b_state->on_time = msg->on_time;
    b_state->off_time = msg->off_time;
    b_state->phase = msg->phase+16;
    b_state->level = msg->level+1;
    if (VAR(need_beacon)) {
	b_state->old_time = VAR(count); // record our old time, for debugging
	VAR(off_time) = msg->off_time; // set the off time
	VAR(on_time) = msg->on_time; // set the on time
	if (check_skew(msg->phase)) {
	    sync_clock(msg->phase);
	    TOS_CALL_COMMAND(SLEEP_TEST_LEDr_on)();
	}
	send_beacon();
    }
    VAR(need_beacon) = 0;
    TOS_CALL_COMMAND(SLEEP_TEST_LEDg_on)();
    dbg(DBG_USR1, ("SLEEP_TEST: %x, %x\n", data->data[0], data->data[1]));
    return data;
}


