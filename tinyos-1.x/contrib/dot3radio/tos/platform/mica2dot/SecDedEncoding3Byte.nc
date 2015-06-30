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
module SecDedEncoding3Byte
{
   provides {
	interface RadioEncoding as Code;
   }
}

implementation{





enum {

/*
	IDLE_STATE         = 0,
	DECODING_BYTE_3    = 1,
	DECODING_BYTE_2    = 2,
	DECODING_BYTE_1    = 3,
	ENCODING_BYTE      = 4
*/
        IDLE_STATE         = 0,
	DECODING_BYTE_4    = 1,
        DECODING_BYTE_3    = 2,
        DECODING_BYTE_2    = 3,
        DECODING_BYTE_1    = 4,
        ENCODING_BYTE_3    = 5,
        ENCODING_BYTE_2    = 6,
        ENCODING_BYTE_1    = 7
};

char data1;
char data2;
char data3;
char data4;
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
		return 1;
        }else if(state == DECODING_BYTE_2){
                state = DECODING_BYTE_3;
                data3 = d1;
                return 1;
	}else if(state == DECODING_BYTE_3){
		state = DECODING_BYTE_4;
		data4 = d1;	
		radio_decode_thread();
		return 1;
	}

	return 0;	
}


command result_t Code.encode_flush(){
	// no data to flush
        if (state == IDLE_STATE){
                return 1;
        }
        else if (state == ENCODING_BYTE_3) {
                return 1;
        }
        // flush in the middle of byte, insert 0
        else if (state == ENCODING_BYTE_2) {
                state = ENCODING_BYTE_3;
                data3 = 0;
                radio_encode_thread();
                return 1;
        }
        else if (state == ENCODING_BYTE_1) {
                state = ENCODING_BYTE_3;
                data3 = 0;
                data2 = 0;
                radio_encode_thread();
                return 1;
        }
	return 1;
}

command result_t Code.encode(char d){
        if(state == IDLE_STATE){
                state = ENCODING_BYTE_1;
                data1 = d;
                return 1;
        }else if(state == ENCODING_BYTE_1){
                state = ENCODING_BYTE_2;
                data2 = d;
                return 1;
        }else if(state == ENCODING_BYTE_2){
                state = ENCODING_BYTE_3;
                data3 = d;
                radio_encode_thread();
                return 1;
        }
        return 0;
}

/* This function encode the data using SEC_DED encoding */
void radio_encode_thread(){
     char ret_high = 0;
     char ret_mid = 0;
     char ret_low = 0;
     char parity = 0;
     char val1 = data1;
     char val2 = data2;
     char val3 = data3;
 
	//encode then expand.

        //encode first byte.
        if((val1 & 0x1) != 0) {
                parity ^= 0x3e;
                ret_low |= 0x01;
        }
        if((val1 & 0x2) != 0) {
                parity ^= 0x3d;
                ret_low |= 0x02;
        }
        if((val1 & 0x4) != 0) {
                parity ^= 0x3b;
                ret_low |= 0x04;
        }
        if((val1 & 0x8) != 0) {
                parity ^= 0x37;
                ret_low |= 0x08;
        }
        if((val1 & 0x10) != 0) {
                parity ^= 0x34;
                ret_low |= 0x10;
        }
        if((val1 & 0x20) != 0) {
                parity ^= 0x2a;
                ret_low |= 0x20;
        }
        if((val1 & 0x40) != 0) {
                parity ^= 0x15;
                ret_low |= 0x40;
        }
        if((val1 & 0x80) != 0) {
                parity ^= 0x0b;
                ret_low |= 0x80;
        }

	//encode second byte.
	if((val2 & 0x1) != 0) {
    		parity ^= 0x38;
 		ret_mid |= 0x01;
	} 
	if((val2 & 0x2) != 0) {
    		parity ^= 0x32; 
 		ret_mid |= 0x02;
        } 
	if((val2 & 0x4) != 0) {
    		parity ^= 0x31; 
 		ret_mid |= 0x04;
        } 
	if((val2 & 0x8) != 0) {
    		parity ^= 0x23; 
 		ret_mid |= 0x08;
        } 
	if((val2 & 0x10) != 0) {
    		parity ^= 0x29; 
  		ret_mid |= 0x10;
        } 
 	if((val2 & 0x20) != 0) {
     		parity ^= 0x25; 
  		ret_mid |= 0x20;
        } 
 	if((val2 & 0x40) != 0) {
     		parity ^= 0x1c;
  		ret_mid |= 0x40;
        } 
 	if((val2 & 0x80) != 0) {
     		parity ^= 0x1a; 
                ret_mid |= 0x80;
        } 

        // encode third byte
        if((val3 & 0x1) != 0) {
                parity ^= 0x19;
                ret_high |= 0x01;
        }
        if((val3 & 0x2) != 0) {
                parity ^= 0x16;
                ret_high |= 0x02;
        }
        if((val3 & 0x4) != 0) {
                parity ^= 0x26;
                ret_high |= 0x04;
        }
        if((val3 & 0x8) != 0) {
                parity ^= 0x07;
                ret_high |= 0x08;
        }
        if((val3 & 0x10) != 0) {
                parity ^= 0x13;
                ret_high |= 0x10;
        }
        if((val3 & 0x20) != 0) {
                parity ^= 0x0e;
                ret_high |= 0x20;
        }
        if((val3 & 0x40) != 0) {
                parity ^= 0x2c;
                ret_high |= 0x40;
        }
        if((val3 & 0x80) != 0) {
                parity ^= 0x0d;
                ret_high |= 0x80;
        }

     state = IDLE_STATE;
     signal Code.encodeDone(parity);
     signal Code.encodeDone(ret_high);
     signal Code.encodeDone(ret_mid);
     signal Code.encodeDone(ret_low);

 }

/* This function decodes SEC_DED encoded data */
void radio_decode_thread(){
    
     //strip the data
     char ret_high = 0;
     char ret_mid = 0;
     char ret_low = 0;
     char parity;
     char error = 0;
     uint32_t encoded_value = 0;
     parity = data1;
     ret_high = data2;
     ret_mid = data3;
     ret_low = data4;
     if((ret_low & 0x01) != 0) encoded_value |= 0x01;  
     if((ret_low & 0x02) != 0) encoded_value |= 0x02;
     if((ret_low & 0x04) != 0) encoded_value |= 0x04;
     if((ret_low & 0x08) != 0) encoded_value |= 0x08;
     if((ret_low & 0x10) != 0) encoded_value |= 0x10;
     if((ret_low & 0x20) != 0) encoded_value |= 0x20;
     if((ret_low & 0x40) != 0) encoded_value |= 0x40;
     if((ret_low & 0x80) != 0) encoded_value |= 0x80;
     if((ret_mid & 0x01) != 0) encoded_value |= 0x0100;
     if((ret_mid & 0x02) != 0) encoded_value |= 0x0200;
     if((ret_mid & 0x04) != 0) encoded_value |= 0x0400;
     if((ret_mid & 0x08) != 0) encoded_value |= 0x0800;
     if((ret_mid & 0x10) != 0) encoded_value |= 0x1000;
     if((ret_mid & 0x20) != 0) encoded_value |= 0x2000;
     if((ret_mid & 0x40) != 0) encoded_value |= 0x4000;
     if((ret_mid & 0x80) != 0) encoded_value |= 0x8000;
     if((ret_high & 0x01) != 0) encoded_value |= 0x010000;
     if((ret_high & 0x02) != 0) encoded_value |= 0x020000;
     if((ret_high & 0x04) != 0) encoded_value |= 0x040000;
     if((ret_high & 0x08) != 0) encoded_value |= 0x080000;
     if((ret_high & 0x10) != 0) encoded_value |= 0x100000;
     if((ret_high & 0x20) != 0) encoded_value |= 0x200000;
     if((ret_high & 0x40) != 0) encoded_value |= 0x400000;
     if((ret_high & 0x80) != 0) encoded_value |= 0x800000;

     encoded_value =  encoded_value << 6 | (parity & 0x3f);

	// check the parity
	parity = 0;
	if((encoded_value & 0x1) != 0) parity ^= 0x01;
	if((encoded_value & 0x2) != 0) parity ^= 0x02;
	if((encoded_value & 0x4) != 0) parity ^= 0x04;
	if((encoded_value & 0x8) != 0) parity ^= 0x08;
	if((encoded_value & 0x10) != 0) parity ^= 0x10;
	if((encoded_value & 0x20) != 0) parity ^= 0x20;
	if((encoded_value & 0x40) != 0) parity ^= 0x0d;
	if((encoded_value & 0x80) != 0) parity ^= 0x2c;
	if((encoded_value & 0x100) != 0) parity ^= 0x0e;
	if((encoded_value & 0x200) != 0) parity ^= 0x13;
	if((encoded_value & 0x400) != 0) parity ^= 0x07;
	if((encoded_value & 0x800) != 0) parity ^= 0x26;
	if((encoded_value & 0x1000) != 0) parity ^= 0x16;
        if((encoded_value & 0x2000) != 0) parity ^= 0x19;
        if((encoded_value & 0x4000) != 0) parity ^= 0x1a;
        if((encoded_value & 0x8000) != 0) parity ^= 0x1c;
        if((encoded_value & 0x10000) != 0) parity ^= 0x25;
        if((encoded_value & 0x20000) != 0) parity ^= 0x29;
        if((encoded_value & 0x40000) != 0) parity ^= 0x23;
        if((encoded_value & 0x80000) != 0) parity ^= 0x31;
        if((encoded_value & 0x100000) != 0) parity ^= 0x32;
        if((encoded_value & 0x200000) != 0) parity ^= 0x38;
        if((encoded_value & 0x400000) != 0) parity ^= 0x0b;
        if((encoded_value & 0x800000) != 0) parity ^= 0x15;
        if((encoded_value & 0x1000000) != 0) parity ^= 0x2a;
        if((encoded_value & 0x2000000) != 0) parity ^= 0x34;
        if((encoded_value & 0x4000000) != 0) parity ^= 0x37;
        if((encoded_value & 0x8000000) != 0) parity ^= 0x3b;
        if((encoded_value & 0x10000000) != 0) parity ^= 0x3d;
        if((encoded_value & 0x20000000) != 0) parity ^= 0x3e;
	
	//now fix the error.
	error = -1;
	if(parity == 0){}
	else if(parity == 0x1) { encoded_value ^= 0x1;}
	else if(parity == 0x2) { encoded_value ^= 0x2; }
	else if(parity == 0x4) { encoded_value ^= 0x4; }
	else if(parity == 0x8) { encoded_value ^= 0x8; }
	else if(parity == 0x10) { encoded_value ^= 0x10;}
        else if(parity == 0x20) { encoded_value ^= 0x20;}
	else{
		error = 0;
		if(parity == 0x0d) { encoded_value ^= 0x40;}
		else if(parity == 0x2c) { encoded_value ^= 0x80;}
		else if(parity == 0x0e) { encoded_value ^= 0x100;}
		else if(parity == 0x13) { encoded_value ^= 0x200; }
		else if(parity == 0x07) { encoded_value ^= 0x400; }
		else if(parity == 0x26) { encoded_value ^= 0x800; }
		else if(parity == 0x16) { encoded_value ^= 0x1000; }
		else if(parity == 0x19) { encoded_value ^= 0x2000;}
                else if(parity == 0x1a) { encoded_value ^= 0x4000;}
                else if(parity == 0x1c) { encoded_value ^= 0x8000;}
                else if(parity == 0x25) { encoded_value ^= 0x10000; }
                else if(parity == 0x29) { encoded_value ^= 0x20000; }
                else if(parity == 0x23) { encoded_value ^= 0x40000; }
                else if(parity == 0x31) { encoded_value ^= 0x80000; }
                else if(parity == 0x32) { encoded_value ^= 0x100000;}
                else if(parity == 0x38) { encoded_value ^= 0x200000;}
                else if(parity == 0x0b) { encoded_value ^= 0x400000;}
                else if(parity == 0x15) { encoded_value ^= 0x800000;}
                else if(parity == 0x2a) { encoded_value ^= 0x1000000;}
                else if(parity == 0x34) { encoded_value ^= 0x2000000;}
                else if(parity == 0x37) { encoded_value ^= 0x4000000;}
                else if(parity == 0x3b) { encoded_value ^= 0x8000000;}
                else if(parity == 0x3d) { encoded_value ^= 0x10000000;}
                else if(parity == 0x3e) { encoded_value ^= 0x20000000;}
		else {
			error = 1;
		}
	}

	//pull off the data bits
     state = IDLE_STATE;
     signal Code.decodeDone((encoded_value >> 6) & 0xff, error);
     signal Code.decodeDone((encoded_value >> 14) & 0xff, error);
     signal Code.decodeDone((encoded_value >> 22) & 0xff, error);
}
}
