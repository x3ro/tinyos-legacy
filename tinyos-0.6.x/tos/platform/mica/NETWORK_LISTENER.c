/*									tab:4
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:		Jason Hill, Philip Levis
 *
 */


#define IDLE_STATE 0
#define START_SYMBOL_SEARCH 1
#define MAC_IDLE 1
#define PACKET_START 2
#define DISABLED_STATE 3

#include "tos.h"
#include "NETWORK_LISTENER.h"
#include "dbg.h"


#define SAMPLE_RATE 100/2*4

TOS_FRAME_BEGIN(CHAN_MON_frame) {
	unsigned short search[2];
	char state;
	unsigned char last_bit;
	unsigned char startSymBits;
	short waiting;
	char max_timeout;
	short length;
}
TOS_FRAME_END(CHAN_MON_frame);

	char state;
	unsigned char last_bit;
int ssearch;
	unsigned short search[2];
	unsigned char startSymBits;

char TOS_COMMAND(LISTENER_INIT)(){
	VAR(waiting) = -1;
	VAR(length) = 0;
	return TOS_CALL_COMMAND(START_LISTENING)();
}

char TOS_COMMAND(START_LISTENING)(){
  //Reset to idle state.
  VAR(state) = IDLE_STATE;
  //set the RFM pins.
  SET_RFM_CTL0_PIN();
  SET_RFM_CTL1_PIN();
  CLR_RFM_TXD_PIN();
  cbi(TIMSK, OCIE2); //clear interrupts
  cbi(TIMSK, TOIE2);  //clear interrupts
  cbi(TIMSK, OCIE2); //clear interrupts
  outp(0x09, TCCR2); //scale the counter
  outp(SAMPLE_RATE, OCR2); // set upper byte of comp reg.
  sbi(TIMSK, OCIE2); // enable timer1 interupt
  outp(0x00, TCNT2); // clear current counter value
  sbi(DDRB, 6);
  return 1;
}

char dest;

TOS_SIGNAL_HANDLER(SIG_OUTPUT_COMPARE2, ()){
 char bit = READ_RFM_RXD_PIN();
 VAR(length)++;
 if (VAR(length) == (1 << 15)) {VAR(length) --;} // Don't go over threshold
 
 //fire the bit arrived event and send up the value.
 if (state == IDLE_STATE) {
   search[0] <<= 1;
   search[0] = search[0] | (bit & 0x1);
   if(VAR(waiting) != -1){
     VAR(waiting) --;
     if(VAR(waiting) == 1){
       if ((search[0] & 0xf) == 0) {
	 VAR(waiting) = -1;
	 TOS_SIGNAL_EVENT(NETWORK_IDLE_DETECT)();
       }else{
	 if (VAR(max_timeout)) {
	   VAR(max_timeout)--;
	   if (VAR(max_timeout) == 0) {
	     TOS_SIGNAL_EVENT(NETWORK_IDLE_TIMEOUT)();
	   }
	 }
	 VAR(waiting) = (TOS_CALL_COMMAND(MAC_SUB_NEXT_RAND)() & 0xf) + 50;
       } 
     }
   }
   if ((search[0] & 0x777) == 0x707){
     state = START_SYMBOL_SEARCH;
     search[0] = search[1] = 0;
     startSymBits = 30;
   }
 }else if(state == START_SYMBOL_SEARCH){
   unsigned int current = search[last_bit];
   startSymBits--;
   if (startSymBits == 0){
     state = IDLE_STATE;
     return;
   }
   current <<= 1;
   current &=  0x1ff;  // start symbol is 9 bits
   if(bit) current |=  0x1;  // start symbol is 9 bits
   if (current == 0x135) {
     cbi(TIMSK, OCIE2); 
     state = IDLE_STATE;
     VAR(length) = VAR(length) >> 1;
     TOS_SIGNAL_EVENT(START_SYM_DETECT)();
     return;
   }
   search[last_bit] = current;
   last_bit ^= 1;
 }
 return;
}

char TOS_COMMAND(STOP_LISTENING)(){
	//disable timer
  	cbi(TIMSK, OCIE2); 
	VAR(state) = DISABLED_STATE;
	return 1;
}

short TOS_COMMAND(GET_IDLE_VALUE)() {
  return VAR(length);
}

char TOS_COMMAND(MAC_DELAY)(char timeout){
	VAR(search)[0] = 0xff;
	if(VAR(waiting) == -1) {
	  VAR(max_timeout) = timeout;
	  VAR(waiting) = (TOS_CALL_COMMAND(MAC_SUB_NEXT_RAND)() & 0x3f) + 100;
	}
	return 1;
}
