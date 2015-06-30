/*									tab:4
 * WAKEUP.c
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
 * Authors:   Deepak Ganesan
 * History:   created 07/08/2001
 *
 *
 */

#include "tos.h"
#include "WAKEUP.h"

#define LISTEN 100
#define WAKEUP_NETWORK 101
#define ALIVE 102
#define SHUTDOWN_NETWORK 103

#define ALIVE_COUNTDOWN 600
#define MAX_WAKEUP_NETWORK 20



//your FRAME
#define TOS_FRAME_TYPE WAKEUP_frame
TOS_FRAME_BEGIN(WAKEUP_frame) {
  char state;			/* Component state */
  unsigned int counter;                 /* Count of Rebroadcasts */
  TOS_Msg data; 		/* Message to be sent out */
  char send_pending;		/* Variable to store state of buffer*/
}
TOS_FRAME_END(WAKEUP_frame);

/* WAKEUP_INIT:  
   turn on the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(WAKEUP_INIT)(){
  //CLR_RED_LED_PIN();
  /* Uncomment below if not used with probrouter_light_wakeup* */
  //  TOS_CALL_COMMAND(WAKEUP_SUB_INIT)();       /* initialize lower components (radio) */
  /*
    The rene has woken either for the first time
    or after a watchdog interrupt. 
    Rene goes to listen mode and waits for wakeup packet
    for 1 second.
  */
  
  VAR(state) = ALIVE;
  VAR(counter) = 0;

  /* Uncomment below if not used with probrouter_light_wakeup* */
  //  TOS_CALL_COMMAND(WAKEUP_CLOCK_INIT)(tick1ps);    /* set clock interval */
  printf("WAKEUP initialized\n");
  return 1;
}


char TOS_COMMAND(WAKEUP_START)(){
  return 1;
}

void TOS_COMMAND(WAKEUP_SET_WATCHDOG)() {

  //Explicitly disable interrupts
  //Alternatively execute PWR(down) on radio stack
  //Prevents SEND_DONE from screwing u up
  cli();
  
  //Set LED pins to input/high impedance
  MAKE_RED_LED_INPUT();
  MAKE_GREEN_LED_INPUT();
  MAKE_YELLOW_LED_INPUT();
  SET_RED_LED_PIN();
  SET_GREEN_LED_PIN();
  SET_YELLOW_LED_PIN();

  //Set misc pins to input & high impedance
  MAKE_POT_SELECT_INPUT();
  MAKE_PW4_INPUT();
  MAKE_PW3_INPUT();
  MAKE_PW2_INPUT();
  MAKE_PW1_INPUT();

  //Set Radio to sleep
  //Set TXMOD to low
  sbi(DDRB, 2);
  cbi(PORTB, 2);
  //Set CTRL1 and CRTL0 to low
  sbi(DDRB, 1);
  sbi(DDRB, 0);
  cbi(PORTB, 1);
  cbi(PORTB, 0);

  //Set watchdog timeout to 6secs
  sbi(WDTCR, WDP2);
  sbi(WDTCR, WDP1);
  sbi(WDTCR, WDP0);
  sbi(WDTCR, WDE); //Watchdog Enable

  //Set processor to PowerDown Mode
  sbi(MCUCR, SM1);
  cbi(MCUCR, SM0);
  sbi(MCUCR, SE); 
  asm volatile ("sleep" ::);
  asm volatile ("nop" ::);
  asm volatile ("nop" ::);

}


/* Clock Event Handler: 
   signaled at end of each clock interval.

 */

void TOS_EVENT(WAKEUP_CLOCK_EVENT)(){
  /*
    If state = LISTEN, goto sleep
  */
  if (VAR(state) == LISTEN || VAR(state)==SHUTDOWN_NETWORK) {
    //SET_RED_LED_PIN();
    //CLR_YELLOW_LED_PIN();
    TOS_CALL_COMMAND(WAKEUP_SET_WATCHDOG)();
  }

  /*
    Blasting data for MAX_WAKEUP_NETWORK seconds. Count till MWN then stop
    Set counter to period for which inactivity is monitored
  */
  if (VAR(state) == WAKEUP_NETWORK && ++VAR(counter) == MAX_WAKEUP_NETWORK) {
    VAR(state) = ALIVE;
    VAR(counter) = ALIVE_COUNTDOWN;
    return;
  }

  /*
    If state = ALIVE and counter has expired,
    Goto LISTEN state
  */
  if (VAR(state)==ALIVE && --VAR(counter)==0) VAR(state)=LISTEN;

}


/*   WAKEUP_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(WAKEUP_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
  //check to see if the message that finished was yours.
  //if so, then clear the send_pending flag.
  if(&VAR(data) == msg){ 
    VAR(send_pending) = 0;
    SET_YELLOW_LED_PIN();
    
    if (VAR(state) == WAKEUP_NETWORK) {
      //Broadcast wakeup message
      if (TOS_CALL_COMMAND(WAKEUP_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(WAKEUP_MSG),&VAR(data))) {
	//CLR_YELLOW_LED_PIN();
	VAR(send_pending) = 1;
	    }
    }
  }
  
  return 1;
}

/*   AM_msg_handler_6      handler for msg of type 6

     Message to Wakeup Rene from DeepSleep recvd.
     For next DUTY_CYCLE_PERIOD, broadcast Wakeup signal
*/
TOS_MsgPtr TOS_MSG_EVENT(WAKEUP_MSG)(TOS_MsgPtr data){
  //CLR_GREEN_LED_PIN();
  
  if (VAR(state) == LISTEN) {
    VAR(state) = WAKEUP_NETWORK;
    VAR(counter) = 0;
  }

  if (VAR(state) == WAKEUP_NETWORK) {
    //Broadcast wakeup message
    if (TOS_CALL_COMMAND(WAKEUP_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(WAKEUP_MSG),&VAR(data))) {
      CLR_YELLOW_LED_PIN();
      VAR(send_pending) = 1;
    }
  }

  return data;
}

/*   AM_msg_handler_7      handler for msg of type 7

     Message to Shutdown Rene recvd
     Propagate Message ONCE, then goto sleep
*/
TOS_MsgPtr TOS_MSG_EVENT(SHUTDOWN_MSG)(TOS_MsgPtr data){
  //CLR_GREEN_LED_PIN();

  VAR(state) = SHUTDOWN_NETWORK;
  //Broadcast shutdown message ONCE
  if (TOS_CALL_COMMAND(WAKEUP_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(SHUTDOWN_MSG),&VAR(data))) {
    //CLR_YELLOW_LED_PIN();
    VAR(send_pending) = 1;
  }
  
  return data;
}

/*
  Promiscous mode: intended for one of the other component handlers
  Notifies Wakeup Component that activity is taking place
*/
TOS_MsgPtr TOS_MSG_EVENT(PROMISCUOUS_MODE_MSG)(TOS_MsgPtr data){
  /*
    Packets are floating around. Mote assumes it has missed the WAKEUP_NETWORK packet
    and goes to ALIVE directly
  */
  if (VAR(state)==LISTEN) {
    VAR(state) = ALIVE;
    VAR(counter) = ALIVE_COUNTDOWN;
  }
  if (VAR(state)==ALIVE) VAR(counter) = ALIVE_COUNTDOWN;
  return data;
}
