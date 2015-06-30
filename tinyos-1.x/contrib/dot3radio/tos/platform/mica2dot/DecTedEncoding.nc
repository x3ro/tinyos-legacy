/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */

includes Syndromes;

module DecTedEncoding
{
   provides {
	interface RadioEncoding as Code;
   }
}

implementation{

enum {
	IDLE_STATE         = 0,
	DECODING_BYTE_2    = 1,
	DECODING_BYTE_1    = 2,
	ENCODING_BYTE      = 3
};

char data1;
char data2;
char state;                     // state of this component

void radio_decode_thread();
void radio_encode_thread();

command result_t Code.decode(char d1){
	
	if(state == IDLE_STATE){
		state = DECODING_BYTE_1;
		data1 = d1;
		return 1;
	}else if(state == DECODING_BYTE_1){
		state = DECODING_BYTE_2;
		data2 = d1;
		radio_decode_thread();
		return 1;
	}
	return 0;	
}


command result_t Code.encode_flush(){

	return 1;
}

command result_t Code.encode(char d){
	if(state == IDLE_STATE){
		state = ENCODING_BYTE;
		data1 = d;
		radio_encode_thread();
		return 1;
	}
	return 0;	
}

/* This function encodes the data using DEC_TED encoding */
void radio_encode_thread(){

     char parity = 0;

	if (data1 & 0x80)
	  parity ^= 0x6a;
	if (data1 & 0x40)
	  parity ^= 0x35;
	if (data1 & 0x20)
	  parity ^= 0x9a;
	if (data1 & 0x10)
	  parity ^= 0x4d;
	if (data1 & 0x08)
	  parity ^= 0xa6;
	if (data1 & 0x04)
	  parity ^= 0x53;
	if (data1 & 0x02)
	  parity ^= 0xa9;
	if (data1 & 0x01)
	  parity ^= 0xd4;

     state = IDLE_STATE;
     signal Code.encodeDone(parity);
     signal Code.encodeDone(data1);
 }

/* This function decodes DEC_TED encoded data */
void radio_decode_thread(){

     unsigned short error = 0;
     unsigned short syndrome = 0;
     short encoded_value = 0;

     encoded_value =  data2;
     encoded_value <<= 8;
     encoded_value |= data1 & 0xff;

	syndrome = 0;

	if (encoded_value & 0x8000)
	  syndrome ^= 0x006a;
	if (encoded_value & 0x4000)
	  syndrome ^= 0x0035;
	if (encoded_value & 0x2000)
	  syndrome ^= 0x009a;
	if (encoded_value & 0x1000)
	  syndrome ^= 0x004d;
	if (encoded_value & 0x0800)
	  syndrome ^= 0x00a6;
	if (encoded_value & 0x0400)
	  syndrome ^= 0x0053;
	if (encoded_value & 0x0200)
	  syndrome ^= 0x00a9;
	if (encoded_value & 0x0100)
	  syndrome ^= 0x00d4;
	if (encoded_value & 0x0080)
	  syndrome ^= 0x0080;
	if (encoded_value & 0x0040)
	  syndrome ^= 0x0040;
	if (encoded_value & 0x0020)
	  syndrome ^= 0x0020;
	if (encoded_value & 0x0010)
	  syndrome ^= 0x0010;
	if (encoded_value & 0x0008)
	  syndrome ^= 0x0008;
	if (encoded_value & 0x0004)
	  syndrome ^= 0x0004;
	if (encoded_value & 0x0002)
	  syndrome ^= 0x0002;
	if (encoded_value & 0x0001)
	  syndrome ^= 0x0001;

	//signal Code.decodeDone((encoded_value >> 8) & 0xff, 0);

	error = syndromes[syndrome];
	state = IDLE_STATE;
	if (error == 0)
	  signal Code.decodeDone(data2 & 0xff, 0);
	else if (error == 0xffff)
	  signal Code.decodeDone(data2 & 0xff, 1);
	else
	  signal Code.decodeDone(((encoded_value ^ error) >> 8) & 0xff, 0);
  }
}
