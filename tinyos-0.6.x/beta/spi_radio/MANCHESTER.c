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
 *$Log: MANCHESTER.c,v 
 *Revision 1.1  2002/01/19 01:57:02  jlhil
 **** empty log message **
 *
 *
 */


#include "tos.h"
#include "MANCHESTER.h"
#include "dbg.h"

#define IDLE_STATE         0
#define DECODING_BYTE_2      1 
#define DECODING_BYTE_1      2 
#define ENCODING_BYTE      3

/* Frame of the component */
#define TOS_FRAME_TYPE encoding_frame
TOS_FRAME_BEGIN(encoding_frame) {
  char data1;
  char data2;
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
     char val = VAR(data1);

	if(val & 0x1){ ret_low |= 0x1;} else { ret_low |= 0x2;}
	if(val & 0x2){ ret_low |= 0x4;} else { ret_low |= 0x8;}
	if(val & 0x4){ ret_low |= 0x10;} else { ret_low |= 0x20;}
	if(val & 0x8){ ret_low |= 0x40;} else { ret_low |= 0x80;}
	if(val & 0x10){ ret_high |= 0x1;} else { ret_high |= 0x2;}
	if(val & 0x20){ ret_high |= 0x4;} else { ret_high |= 0x8;}
	if(val & 0x40){ ret_high |= 0x10;} else { ret_high |= 0x20;}
	if(val & 0x80){ ret_high |= 0x40;} else { ret_high |= 0x80;}

     VAR(state) = IDLE_STATE;
     TOS_SIGNAL_EVENT(RADIO_ENCODE_DONE)(ret_high);
     TOS_SIGNAL_EVENT(RADIO_ENCODE_DONE)(ret_low);

 }

/* This function decodes SEC_DED encoded data */
void radio_decode_thread(){
    
     //strip the data
     char ret_high = 0;
     char ret_low = 0;
     char output = 0;
     char error = 0;
     ret_high = VAR(data1);
     ret_low = VAR(data2);
     if((ret_low & 0x1) != 0) output |= 0x1;  
     if((ret_low & 0x4) != 0) output |= 0x2;
     if((ret_low & 0x10) != 0) output |= 0x4;
     if((ret_low & 0x40) != 0) output |= 0x8;
     if((ret_high & 0x01) != 0) output |= 0x10;
     if((ret_high & 0x04) != 0) output |= 0x20;
     if((ret_high & 0x10) != 0) output |= 0x40;
     if((ret_high & 0x40) != 0) output |= 0x80;
     VAR(state) = IDLE_STATE;
     TOS_SIGNAL_EVENT(RADIO_DECODE_DONE)(output, error);
}
