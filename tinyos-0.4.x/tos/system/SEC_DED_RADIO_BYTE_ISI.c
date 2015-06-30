/*									tab:4
 *
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
 * Authors:		Jason Hill, Wei Ye
 *
 *
 */




#include "tos.h"
#include "SEC_DED_RADIO_BYTE.h"


/* list of states:
 *
 * IDLE_CS -- idle and carrier sense. Searching for preamble
 * START_TX -- start a transmission, 0 bytes encoded.
 * ONE_ENCODED -- 1 byte encoded
 * ONE_WAITING -- 1 byte encoded, 1 byte waiting to be encoded
 * TWO_ENCODED -- 2 bytes encoded
 * READ_FIRST_BIT -- matched start symbol, waiting for first bit
 * CLOCK_BITS -- clocking in bits
 * READ_LAST_BIT -- read last useful bit
 * DECODE_READY -- ready to decode 1 byte
 * MATCH_START_SYMBOL -- matching start symbol 101011001
 * ADJUST_SAMPLE_POS -- adjust sampling positions 
 *
 * followings are implemented by Wei Ye (USC/ISI)
 * 1. Add a preamble (x111x000x111 at 2X rate) for early noise rejection
 * 2. Carrier sense is combined at idle state -- don't miss packets arrived 
 *    during carrier sense.
 * 3. Use 2 groups of samples to match the start symbol -- don't miss start 
 *    symbol even if one group of samples falling on edges.
 * 4. Align sampling positions by 2 groups of samples -- close to center of
 *    of each pulses.
 *  
 */

#define IDLE_CS 0
#define START_TX 1
#define ONE_ENCODED 2
#define ONE_WAITING 3
#define TWO_ENCODED 4
#define READ_FIRST_BIT 5
#define CLOCK_BITS 6
#define READ_LAST_BIT 7
#define DECODE_READY 8
#define MATCH_START_SYMBOL 11
#define ADJUST_SAMPLE_POS 12

extern short TOS_LOCAL_ADDRESS;

#define TOS_FRAME_TYPE bitread_frame
TOS_FRAME_BEGIN(radio_frame) {
	char primary[3];
	char secondary[3];
	char state;
	char count;
	char last_bit;
	char TxRequest;
	char preambleL;  // lower part of preamble
	char preambleH;  // higher part of preamble
	unsigned int shift_reg;	// random number generation
    unsigned char csBits;  // number of bits to be read for carrier sense
}
TOS_FRAME_END(radio_frame);

TOS_TASK(radio_encode_thread)
{
	//encode byte and store it into buffer.
	encodeData();
	//if this is the start of a transmisison, encode the start symbol.
	if(VAR(state) == START_TX){
		VAR(primary)[0] = 0x2;  //start frame 0x10
		VAR(primary)[1] = 0x6a; //start frame 0x01101010
		VAR(primary)[2] = 0xcd; //start frame 0x11001101
		VAR(count) = 0;
	}
	VAR(state) = TWO_ENCODED; //there are now 2 bytes encoded.
	    
#ifdef FULLPC_DEBUG
    printf("radio_encode_thread running: %x, %x\n", VAR(secondary[1]), VAR(secondary[2]));
#endif
}

TOS_TASK(radio_decode_thread)
{
#ifdef FULLPC_DEBUG
    printf("radio_decode_thread running: %x, %x\n", VAR(secondary[1]), VAR(secondary[2]));
#endif
    //decode the byte that has been recieved.
    if(!(TOS_SIGNAL_EVENT(RADIO_BYTE_RX_BYTE_READY)(decodeData(), 0))){
	//if the event returns false, then stop receiving, go to search for the
	//start symbol at the high sampling rate.
	VAR(state) = IDLE_CS;
	TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
    }
}		

char TOS_COMMAND(RADIO_BYTE_INIT)(){
    VAR(state) = IDLE_CS;
    VAR(TxRequest) = 0;
    VAR(csBits) = 0;
	VAR(preambleH) = 0;
	VAR(preambleL) = 0;
    VAR(shift_reg) = 119 * TOS_LOCAL_ADDRESS;	// seed for Rand
    TOS_CALL_COMMAND(RADIO_SUB_INIT)();
#ifdef FULLPC
    printf("Radio Byte handler initialized.\n");
#endif
    return 1;
}

char TOS_COMMAND(RADIO_BYTE_TX_BYTES)(char data){
	char bit;
#ifdef FULLPC_DEBUG
	printf("TX_bytes: state=%x, data=%x\n", VAR(state), data);
#endif
    if(VAR(state) == IDLE_CS && VAR(TxRequest) == 0){ // accept new Tx
		VAR(secondary[0]) = data;
	    VAR(TxRequest) = 1;
        // set timer for carrier sense
		bit = (VAR(shift_reg) & 0x2) >> 1;
		bit ^= ((VAR(shift_reg) & 0x4000) >> 14);
		bit ^= ((VAR(shift_reg) & 0x8000) >> 15);
		VAR(shift_reg) >>=1;
		if (bit & 0x1) VAR(shift_reg) |= 0x8000;
        // 20 < Var(csBits) < 160
        VAR(csBits) = ((char)(VAR(shift_reg) & 0x7) + 1) * 20;
		return 1;
    }else if(VAR(state) == ONE_ENCODED){
		//if in the middle of a transmission and one byte is encoded
		//go to the one byte encoded and one byte in the encode buffer.
		VAR(state) = ONE_WAITING;
		VAR(secondary[0]) = data;
		//schedule the encode task.
		TOS_POST_TASK(radio_encode_thread);
		return 1;
    }else if(VAR(state) == TWO_ENCODED){
		return 0;
    }
    return 0;
}

//mode 1 = active;
//mode 0 = sleep;

char TOS_COMMAND(RADIO_BYTE_PWR)(char mode){
    if(mode == 0){
	//if low power mode, tell lower components
    	VAR(state) = IDLE_CS;
	TOS_CALL_COMMAND(RADIO_SUB_PWR)(0);
    }else{
	//set the RMF component into "search for start symbol" mode.
	TOS_CALL_COMMAND(RADIO_SUB_PWR)(1);
	TOS_CALL_COMMAND(RADIO_SUB_RX_MODE)();
	TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
	VAR(state) = IDLE_CS;
        VAR(count) = 0;
    }
    return 1;
}


char TOS_EVENT(RADIO_BYTE_TX_BIT_EVENT)(){
#ifdef FULLPC_DEBUG
    printf("radio tx bit event %d\n", VAR(primary)[2] & 0x1);
#endif
    //if we're not it a transmit state, return false.
    if(VAR(state) != ONE_ENCODED && VAR(state) != ONE_WAITING &&
       VAR(state) != TWO_ENCODED) return 0;
    //send the next bit that we have stored.
    TOS_CALL_COMMAND(RADIO_SUB_TX_BIT)(VAR(primary)[2] & 0x01);
    //right shift the buffer.
    VAR(primary)[2] = VAR(primary)[2] >> 1;
    //increment our bytes sent count.
    VAR(count) ++;
    if(VAR(count) == 8){
	//once 8 have gone out, get ready to send out the nibble.
	VAR(primary)[2] = VAR(primary)[1];
    }else if(VAR(count) == 16){
	VAR(primary)[2] = VAR(primary)[0];
    }else if(VAR(count) == 18){
	if(VAR(state) == TWO_ENCODED){
	    //if another byte is ready, then shift the 
	    //data over to first and second.
	    VAR(primary)[0] = VAR(secondary)[0];
	    VAR(primary)[1] = VAR(secondary)[1];
	    VAR(primary)[2] = VAR(secondary)[2];
	    
	    VAR(count) = 0;
	    VAR(state) = ONE_ENCODED;//now only one byte is bufferred.
	    TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(1);//fire the byte transmitted event.
	}else{
	    //if there are no bytes bufferred, go back to idle.
	    VAR(state) = IDLE_CS;
	    TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(1);
	    TOS_SIGNAL_EVENT(RADIO_BYTE_TX_DONE)();
	    TOS_CALL_COMMAND(RADIO_SUB_RX_MODE)();
	    TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
	}
    }
    return 1;
}	
		

char TOS_EVENT(RADIO_BYTE_RX_BIT_EVENT)(char data){
	if(VAR(state) == IDLE_CS){  // idle and carrier sense mode
#ifdef FULLPC
		// skip preamble and to directly match start symbol
		if (data) VAR(state) = MATCH_START_SYMBOL;
#endif
		// trying to detect preamble in idle mode
		VAR(preambleH) = (VAR(preambleH) << 1) & 0x6;
		if ((VAR(preambleL) & 0x80) == 0x80) VAR(preambleH) |= 0x1;
		VAR(preambleL) = (VAR(preambleL) << 1) & 0xfe;
		VAR(preambleL) = VAR(preambleL) | (data & 0x1);
		if(VAR(preambleH) == 0x7 && (VAR(preambleL) & 0x77) == 0x7) {
			// found preamble
			VAR(csBits) = 24;   // read just 24 bits for start symbol
			VAR(primary)[1] = 0;
			VAR(primary)[2] = 0;
			VAR(secondary)[1] = 0;
			VAR(secondary)[2] = 0;
			VAR(last_bit) = 1;	// first group of samples
			VAR(preambleH) = 0;
			VAR(preambleL) = 0;
			VAR(state) = MATCH_START_SYMBOL;	// detecting start symbol
		} else if (VAR(csBits) > 0) {  // Tx pending
			VAR(csBits)--; // decrement carrier sense counter
			if (VAR(csBits) == 0) {
				// carrier sense succeeded, Tx immediately
				VAR(state) = START_TX;  // Tx state
				TOS_CALL_COMMAND(RADIO_SUB_TX_MODE)();
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);
				TOS_POST_TASK(radio_encode_thread);
				VAR(TxRequest) = 0;
			}
		}
	} else if (VAR(state) == MATCH_START_SYMBOL) {
#ifndef FULLPC
		VAR(csBits)--;
		if (VAR(csBits) == 0) {  // failed to find start symbol
			// preamble is faked by noise, medium is clean
			if (VAR(TxRequest)) {  // Tx pending, send directly
				VAR(TxRequest) = 0;
				VAR(state) = START_TX;
				TOS_CALL_COMMAND(RADIO_SUB_TX_MODE)();
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);
				TOS_POST_TASK(radio_encode_thread);
			} else {  // no Tx request
				VAR(state) = IDLE_CS;  // go back to idle
			}
			return 1;
		}
        // put new data into two groups to match start symbol
		if (VAR(last_bit)) {  // just put into second group, now for first
			VAR(last_bit) = 0;
#endif
			// Fullpc mode only has 1 group of samples (no 2x sampling)
			VAR(primary)[2] >>= 1;
			VAR(primary)[2] &= 0x7f;  // clear the highest bit
			//if lowest bit of first is one, store it in second
			if(VAR(primary)[1] & 0x1) VAR(primary)[2] |= 0x80;
			VAR(primary)[1] = data & 0x1;  // start symbol is 9 bits
			if (VAR(primary)[1] == 0x1 && VAR(primary)[2] == 0x35 ) {
				// 1st group matches, read one more bit for 2nd group
#ifndef FULLPC
				VAR(state) = ADJUST_SAMPLE_POS;
				VAR(secondary)[2] >>= 1;
				VAR(secondary)[2] &= 0x7f; 
				if (VAR(secondary)[1] & 0x1) VAR(secondary)[2] |= 0x80;
#else
				VAR(state) = READ_FIRST_BIT;  // directly start receiving data if FULLPC
#endif
			}
#ifndef FULLPC
		} else {  // just put into first group, now for second
			VAR(last_bit) = 1;
			VAR(secondary)[2] >>= 1;
			VAR(secondary)[2] &= 0x7f;  // clear the highest bit
			//if lowest bit of first is one, store it in second
			if(VAR(secondary)[1] & 0x1) VAR(secondary)[2] |= 0x80;
			VAR(secondary)[1] = data & 0x1;  // start symbol is 9 bits
			if (VAR(secondary)[1] == 0x1 && VAR(secondary)[2] == 0x35){
				// 2nd group matches, read one more bit for 1st group
				VAR(state) = ADJUST_SAMPLE_POS;
				VAR(primary)[2] >>= 1;
				VAR(primary)[2] &= 0x7f; 
				if(VAR(primary)[1] & 0x1) VAR(primary)[2] |= 0x80;
			}
		}
	} else if (VAR(state) == ADJUST_SAMPLE_POS) {
		// start symbol already detected
		// use this additional bit for better sampling alignment
		if (VAR(last_bit)) {
			if ((data & 0x1) && VAR(primary)[2] == (char)0x35 )
				// both groups match start symbol
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(1); // 1.5x bit rate
		} else {
			if ((data & 0x1) && VAR(secondary)[2] == (char)0x35)
				// both groups match start symbol
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(1); // 1.5x bit rate
		}
		VAR(csBits) = 0; // clear for next round
		VAR(state) = READ_FIRST_BIT;  // waiting for first bit
#endif
	
	} else if(VAR(state) == READ_FIRST_BIT){
		//just read first bit.
		//set bit rate to match TX rate.
		TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);
		VAR(state) = CLOCK_BITS;
		VAR(count) = 1;
		//store it.
		if(data){
			VAR(primary)[1] = 0x80;
		}else{
			VAR(primary)[1] = 0;
		}
		// if Tx request pending, now have time to signal failure of Tx,
		// so that upper layer will go to idle first, and then can receive
		if (VAR(TxRequest)) {
			VAR(TxRequest) = 0;
			TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(0);
		}
	}else if(VAR(state) == CLOCK_BITS){
		//clock in bit.
		VAR(count)++;
		VAR(primary)[1] >>= 1;
		VAR(primary)[1] &= 0x7f;
		if(data) VAR(primary)[1] |= 0x80;
		if(VAR(count) == 8){
			VAR(secondary[2]) = VAR(primary[1]);
		}else if(VAR(count) == 16){
			VAR(count)++;
			//sore the encoded data into a buffer.
			VAR(secondary)[1] = VAR(primary)[1];
			VAR(state) = READ_LAST_BIT;
		}
	}else if(VAR(state) == READ_LAST_BIT){
		VAR(secondary)[0] = data;
		VAR(state) = DECODE_READY;
    }else if(VAR(state) == DECODE_READY){
		//throw away the higest bit.
		VAR(state) = READ_FIRST_BIT;
		//scheduled the decode task.
		TOS_POST_TASK(radio_decode_thread);
#ifdef FULLPC_DEBUG
		printf("entire byte received: %x, %x\n", VAR(secondary)[1], VAR(secondary)[2]);
#endif
	}
    return 1;
}



 void encodeData(){
     char ret_high = 0;
     char ret_low = 0;
     char ret_mid = 0;
     char val = VAR(secondary[0]);
     if((val & 0x1) != 0) {
	 ret_high ^=0;
	 ret_mid ^=0x0;
	 ret_low ^=0x77;
     }
     if((val & 0x2) != 0) {
	 ret_high ^=0;
	 ret_mid ^=0x1;
	 ret_low ^=0x34;
     }	
     if((val & 0x4) != 0) {
	 ret_high ^=0;
	 ret_mid ^=0x2;
	 ret_low ^=0x32;
     }
     if((val & 0x8) != 0) {
	 ret_high ^=0;
	 ret_mid ^=0x8;
	 ret_low ^=0x31;
     }
     if((val & 0x10) != 0) {
	 ret_high ^=0;
	 ret_mid ^=0x10;
	 ret_low ^=0x26;
     }
     if((val & 0x20) != 0) {
	 ret_high ^=0;
	 ret_mid ^=0x60;
	 ret_low ^=0x25;
     }	
     if((val & 0x40) != 0) {
	 ret_high ^=0;
	 ret_mid ^=0x80;
	 ret_low ^=0x13;
     }	
     if((val & 0x80) != 0) {
	 ret_high ^=0x1;
	 ret_mid ^=0;
	 ret_low ^=0x7;
     }

     if((ret_low & 0xc) == 0) ret_low |= 0x8;
     if((ret_low & 0x40) == 0 && (ret_mid & 0x1) == 0) ret_low |= 0x80;
     if((ret_mid & 0xa) == 0) ret_mid |= 0x4;
     if((ret_mid & 0x50) == 0) ret_mid |= 0x20;
     if((ret_high & 0x1) == 0) ret_high |= 0x2;


     VAR(secondary[0]) = ret_high;
     VAR(secondary[1]) = ret_mid;
     VAR(secondary[2]) = ret_low;

 }

 char decodeData(){
    
     //strip the data
     char ret_high = 0;
     char ret_low = 0;
     char val, val2, output;


     ret_high = (char)((VAR(secondary)[0] << 4) & 0x10);
     ret_high |= (char)((VAR(secondary)[1] >> 4) & 0xc);
     ret_high |= (char)((VAR(secondary)[1] >> 3) & 0x3);
     ret_low = (char)((VAR(secondary)[1] << 6) & 0xc0);
     ret_low |= (char)((VAR(secondary)[2] >> 1) & 0x38);
     ret_low |= (char)(VAR(secondary)[2]  & 0x7);
     //check the data
     val = ret_low;
     val2 = ret_high;
     output = 0;
     if((val & 0x1) != 0) output ^= 0x1;  
     if((val & 0x2) != 0) output ^= 0x2;
     if((val & 0x4) != 0) output ^= 0x4;
     if((val & 0x8) != 0) output ^= 0x8;
     if((val & 0x10) != 0) output ^= 0x10;
     if((val & 0x20) != 0) output ^= 0x1f;
     if((val & 0x40) != 0) output ^= 0x1c;
     if((val & 0x80) != 0) output ^= 0x1a;
     if((val2 & 0x1) != 0) output ^= 0x19;
     if((val2 & 0x2) != 0) output ^= 0x16;
     if((val2 & 0x4) != 0) output ^= 0x15;
     if((val2 & 0x8) != 0) output ^= 0xb;
     if((val2 & 0x10) != 0) output ^= 0x7;
     if(output == 0){}
     else if(output == 0x1) { val ^= 0x1;} 
     else if(output == 0x2) { val ^= 0x2; }
     else if(output == 0x4) { val ^= 0x4; }
     else if(output == 0x8) { val ^= 0x8; }
     else if(output == 0x10) { val ^= 0x10;}
     else if(output == 0x1f) { val ^= 0x20;}
     else if(output == 0x1c) { val ^= 0x40;}
     else if(output == 0x1a) { val ^= 0x80;}
     else if(output == 0x19) { val2 ^= 0x1; }
     else if(output == 0x16) { val2 ^= 0x2; }
     else if(output == 0x15) { val2 ^= 0x4; }
     else if(output == 0xb) { val2 ^= 0x8; }
     else if(output == 0x7) { val2 ^= 0x10;}

     //pull off the data bits
     output = (char)((val >> 5) & 0x7);
     output |= ((char)val2 << 3) & 0xf8; 
     return output;
 }
