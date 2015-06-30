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
 * Authors:		Jason Hill
 *
 *$Log: SEC_DED_ENCONDING.c,v 
 *Revision 1.1  2002/01/19 01:57:02  jlhil
 **** empty log message **
 *
 *
 */


#include "tos.h"
#include "SEC_DED_ENCODING.h"
#include "dbg.h"

#define IDLE_STATE         0
#define DECODING_BYTE_3    1 
#define DECODING_BYTE_2    2 
#define DECODING_BYTE_1    3 
#define ENCODING_BYTE      4

/* Frame of the component */
#define TOS_FRAME_TYPE encoding_frame
TOS_FRAME_BEGIN(encoding_frame) {
  char data1;
  char data2;
  char data3;
  char state;                     // state of this component
}
TOS_FRAME_END(encoding_frame);

void radio_decode_thread();
void radio_encode_thread();

char TOS_COMMAND(RADIO_DECODE)(char d1){
	if(VAR(state) == IDLE_STATE){
		VAR(state) = DECODING_BYTE_1;
		VAR(data1) = d1;
		return 1;
	}else if(VAR(state) == DECODING_BYTE_1){
		VAR(state) = DECODING_BYTE_2;
		VAR(data2) = d1;
		return 1;
	}else if(VAR(state) == DECODING_BYTE_2){
		VAR(state) = DECODING_BYTE_3;
		VAR(data3) = d1;	
		radio_decode_thread();
		return 1;
	}
	return 0;	
}


char TOS_COMMAND(RADIO_ENCODE_FLUSH)(){
	return 1;
}

char TOS_COMMAND(RADIO_ENCODE)(char d){
	if(VAR(state) == IDLE_STATE){
		VAR(state) = ENCODING_BYTE;
		VAR(data1) = d;
		radio_encode_thread();
		return 1;
	}
	return 0;	
}

/* This function encode the data using SEC_DED encoding */
void radio_encode_thread(){
     char ret_high = 0;
     char ret_low = 0;
     char parity = 0;
     char val = VAR(data1);
	//encode then expand.

	//encode first.

	if((val & 0x1) != 0) {
    		parity ^=0x5b;
 		ret_low |= 0x1;
	} else { ret_low |= 0x2;}

	if((val & 0x2) != 0) {
    		parity ^=0x58;
 		ret_low |= 0x4;} 
	else { ret_low |= 0x8;}
	if((val & 0x4) != 0) {
    		parity ^=0x52;
 		ret_low |= 0x10;} 
	else { ret_low |= 0x20;}
	if((val & 0x8) != 0) {
    		parity ^=0x51;
 		ret_low |= 0x40;} 
	else { ret_low |= 0x80;}
	if((val & 0x10) != 0) {
    		parity ^=0x4a;
  		ret_high |= 0x1;} 
	else { ret_high |= 0x2;}
 	if((val & 0x20) != 0) {
     		parity ^=0x49;
  		ret_high |= 0x4;} 
	else { ret_high |= 0x8;}
 	if((val & 0x40) != 0) {
     		parity ^=0x13;
  		ret_high |= 0x10;} 
	else { ret_high |= 0x20;}
 	if((val & 0x80) != 0) {
     		parity ^=0x0b;
  		ret_high |= 0x40;} 
	else { ret_high |= 0x80;}


	//now balance the the parity parts.

	if((parity & 0x40) == 0x40) parity |= 0x80;
	if((parity & 0x50) == 0x50) parity |= 0x20;
	if((parity & 0xa) == 0xa) parity |= 0x4;
		
     VAR(state) = IDLE_STATE;
     TOS_SIGNAL_EVENT(RADIO_ENCODE_DONE)(parity);
     TOS_SIGNAL_EVENT(RADIO_ENCODE_DONE)(ret_high);
     TOS_SIGNAL_EVENT(RADIO_ENCODE_DONE)(ret_low);

 }

/* This function decodes SEC_DED encoded data */
void radio_decode_thread(){
    
     //strip the data
     char ret_high = 0;
     char ret_low = 0;
     char parity;
     char error = 0;
     short encoded_value = 0;
     parity = VAR(data1);
     ret_high = VAR(data2);
     ret_low = VAR(data3);
     if((ret_low & 0x1) != 0) encoded_value |= 0x1;  
     if((ret_low & 0x4) != 0) encoded_value |= 0x2;
     if((ret_low & 0x10) != 0) encoded_value |= 0x4;
     if((ret_low & 0x40) != 0) encoded_value |= 0x8;
     if((ret_high & 0x01) != 0) encoded_value |= 0x10;
     if((ret_high & 0x04) != 0) encoded_value |= 0x20;
     if((ret_high & 0x10) != 0) encoded_value |= 0x40;
     if((ret_high & 0x40) != 0) encoded_value |= 0x80;
     parity = (parity & 0x3) | ((parity & 0x18) >> 1) | ((parity & 0x40) >> 2);
     encoded_value =  encoded_value << 5 | parity;

	// check the parity
	parity = 0;
	if((encoded_value & 0x1) != 0) parity ^= 0x1;
	if((encoded_value & 0x2) != 0) parity ^= 0x2;
	if((encoded_value & 0x4) != 0) parity ^= 0x4;
	if((encoded_value & 0x8) != 0) parity ^= 0x8;
	if((encoded_value & 0x10) != 0) parity ^= 0x10;
	if((encoded_value & 0x20) != 0) parity ^= 0x1f;
	if((encoded_value & 0x40) != 0) parity ^= 0x1c;
	if((encoded_value & 0x80) != 0) parity ^= 0x1a;
	if((encoded_value & 0x100) != 0) parity ^= 0x19;
	if((encoded_value & 0x200) != 0) parity ^= 0x16;
	if((encoded_value & 0x400) != 0) parity ^= 0x15;
	if((encoded_value & 0x800) != 0) parity ^= 0xb;
	if((encoded_value & 0x1000) != 0) parity ^= 0x7;
	
	//now fix the error.
	error = -1;
	if(parity == 0){}
	else if(parity == 0x1) { encoded_value ^= 0x1;}
	else if(parity == 0x2) { encoded_value ^= 0x2; }
	else if(parity == 0x4) { encoded_value ^= 0x4; }
	else if(parity == 0x8) { encoded_value ^= 0x8; }
	else if(parity == 0x10) { encoded_value ^= 0x10;}
	else{
		error = 0;
		if(parity == 0x1f) { encoded_value ^= 0x20;}
		else if(parity == 0x1c) { encoded_value ^= 0x40;}
		else if(parity == 0x1a) { encoded_value ^= 0x80;}
		else if(parity == 0x19) { encoded_value ^= 0x100; }
		else if(parity == 0x16) { encoded_value ^= 0x200; }
		else if(parity == 0x15) { encoded_value ^= 0x400; }
		else if(parity == 0xb) { encoded_value ^= 0x800; }
		else if(parity == 0x7) { encoded_value ^= 0x1000;}
		else error = 1;
	}

	//pull off the data bits
     VAR(state) = IDLE_STATE;
     TOS_SIGNAL_EVENT(RADIO_DECODE_DONE)((encoded_value >> 5) & 0xff, error);
}
