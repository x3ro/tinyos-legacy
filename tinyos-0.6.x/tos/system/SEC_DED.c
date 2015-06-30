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
 * Authors:		Philip Levis (from code by  Alec Woo and Wei Ye)
 */

#include "tos.h"
#include "SEC_DED.h"
#include "dbg.h"

/* Frame of the component */
#define TOS_FRAME_TYPE ISIDataFrame
TOS_FRAME_BEGIN(ISIDataFrame) {
  char state;
  char primary[3];
  char secondary[3];
  short strength;
  short sampled;
  short count;
}
TOS_FRAME_END(ISIDataFrame);

#define SINGLE_SAMPLE          0x0190   // 400 ticks
#define SINGLE_AND_HALF_SAMPLE 0x012c   // 300 ticks
#define DOUBLE_SAMPLE          0x00c8   // 200 ticks

#define RX_IDLE_STATE              0 // Searching for preamble
#define RX_DATA_BIT_WAITING_STATE  1 // Waiting for data to decode
#define RX_DATA_CLOCKING_STATE     2 // Reading bits one by one from the radio
#define RX_DATA_READ_STATE         3 // The whole encoded byte (18 bit) is read
#define RX_DATA_DECODE_STATE       4 // Decode the byte just received,
                                     // discard the highest bit
#define RX_IDLE_STATE1             5
#define TX_TWO_ENCODED_STATE       8
#define TX_ONE_ENCODED_STATE       9
#define TX_ONE_WAITING_STATE       10
#define TX_NONE_ENCODED_STATE      11

#define IN_TX()  (VAR(state) & 0x08)

/* This function decodes SEC_DED encoded data */
short decodeData(){
  char error = 0;
  //strip the data
  char ret_high = 0;
  char ret_low = 0;
  char val, val2;
  short output;
  
  
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
  else {
    error = 1;
  }
  //pull off the data bits
  output = (char)((val >> 5) & 0x7);
  output |= ((char)val2 << 3) & 0xf8; 
  if (error) {
    output |= (1 << 15);
  }
  return output;
}

void encodeData() {
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
  
  if((ret_low & 0xc) == 0) {ret_low |= 0x8;}
  if((ret_low & 0x40) == 0 && (ret_mid & 0x1) == 0) {ret_low |= 0x80;}
  if((ret_mid & 0xa) == 0) {ret_mid |= 0x4;}
  if((ret_mid & 0x50) == 0) {ret_mid |= 0x20;}
  if((ret_high & 0x1) == 0) {ret_high |= 0x2;}

  VAR(secondary[0]) = ret_high;
  VAR(secondary[1]) = ret_mid;
  VAR(secondary[2]) = ret_low;

}

TOS_TASK(radio_encode_thread) {
  //encode byte and store it into buffer.
  encodeData();
  //if this is the start of a transmisison, encode the start symbol.
  if (VAR(state) == TX_NONE_ENCODED_STATE) {
    VAR(state) = TX_ONE_ENCODED_STATE;
    VAR(primary)[0] = VAR(secondary)[0];
    VAR(primary)[1] = VAR(secondary)[1];
    VAR(primary)[2] = VAR(secondary)[2];
    //    TOS_SIGNAL_EVENT(SEC_DED_TX_BYTE_READY)(1);
  }
  else if (VAR(state) == TX_ONE_WAITING_STATE) {
    VAR(state) = TX_TWO_ENCODED_STATE;
  }

  dbg(DBG_ENCODE, ("radio_encode_thread ran: %x, %x\n", VAR(secondary[1]), VAR(secondary[2])));
}

TOS_TASK(radio_decode_thread) {
  unsigned short strength;
  char error = 0;
  short val;
  
  dbg(DBG_ENCODE, ("radio_decode_thread running: %x, %x\n", VAR(secondary[1]), VAR(secondary[2])));
  
  strength = VAR(strength);
  VAR(strength) = 0;
  val = decodeData();

  if (val & (1 << 15)) {
    error = 1;
    val &= ~(1 << 15);
  }
  
  //decode the byte that has been recieved.
  if(!(TOS_SIGNAL_EVENT(SEC_DED_RX_BYTE_READY)((char)(val & 0xff), error, strength))){
    //if the event returns false, then stop receiving, go to search for the
    //preamble at the high sampling rate.
    VAR(state) = RX_IDLE_STATE;
    VAR(sampled) = 0;
    TOS_CALL_COMMAND(SEC_DED_SUB_RX_IDLE_ACTIVATE)();
  }
}

char TOS_COMMAND(SEC_DED_INIT)(void) {
  TOS_CALL_COMMAND(SEC_DED_SUB_INIT)();
  dbg(DBG_BOOT, ("SEC_DED initialized.\n"));

  return 1;
}

char TOS_EVENT(SEC_DED_RX_DATA_START)() {
  VAR(state) = RX_DATA_BIT_WAITING_STATE;
  TOS_CALL_COMMAND(SEC_DED_SUB_SET_BIT_RATE)(SINGLE_SAMPLE);
  VAR(count) = 0;
  return 1;
}

char TOS_EVENT(SEC_DED_RX_DATA_BIT_EVENT)(char bit) {
  switch(VAR(state)) {
  case RX_DATA_BIT_WAITING_STATE: {
    VAR(state) = RX_DATA_CLOCKING_STATE;
    VAR(count) = 1;
    
    //store the first incoming bit
    if(bit) {
      VAR(primary)[1] = 0x80;
      if (VAR(sampled) == 0){
	// Sample the baseband for signal strength if it is a one
	//TOS_CALL_COMMAND(RADIO_SUB_ADC_GET_DATA)(0);
	VAR(sampled) = 1;
      }
    }
    else{
      VAR(primary)[1] = 0;
    }
    break;
  }
  case RX_DATA_CLOCKING_STATE: {
    //clock in the rest of the incoming bits.
    VAR(count)++;
    VAR(primary)[1] >>= 1;
    VAR(primary)[1] &= 0x7f;
    if(bit){
      VAR(primary)[1] |= 0x80;
      if (VAR(sampled) == 0){
	VAR(sampled) = 1;
      }
    }
    if(VAR(count) == 8){
      VAR(secondary[2]) = VAR(primary[1]);
    }else if(VAR(count) == 16){
      VAR(count)++;
      //store the encoded data into a buffer.
      VAR(secondary)[1] = VAR(primary)[1];
      VAR(state) = RX_DATA_READ_STATE;
    }
    break;
  }
  case RX_DATA_READ_STATE: {
    VAR(secondary)[0] = bit;
    VAR(state) = RX_DATA_DECODE_STATE;
    break;
  }
  case RX_DATA_DECODE_STATE: {
    //throw away the higest bit.
    VAR(state) = RX_DATA_BIT_WAITING_STATE;
    //scheduled the decode task to decode the encoded byte just receive
    TOS_POST_TASK(radio_decode_thread);
    dbg(DBG_ENCODE, ("entire byte received: %x, %x\n", VAR(secondary)[1], VAR(secondary)[2]));
    break;
  }
  }
  return 1;
}

char TOS_EVENT(SEC_DED_TX_DATA_START)(void)  {
  TOS_CALL_COMMAND(SEC_DED_SUB_SET_BIT_RATE)(SINGLE_SAMPLE);
  VAR(count) = 0;
  return 1;
}

char TOS_EVENT(SEC_DED_TX_DATA_BIT_EVENT)(void)  {

  if (VAR(state) == TX_ONE_ENCODED_STATE) {
    TOS_SIGNAL_EVENT(SEC_DED_TX_BYTE_READY)(1);
  }
  
  // if (VAR(count) == 0) {
  //  VAR(primary)[0] = VAR(secondary)[0];
  //  VAR(primary)[1] = VAR(secondary)[1];
  //  VAR(primary)[2] = VAR(secondary)[2];
  //}

  dbg(DBG_ENCODE, ("radio tx bit event %d\n", VAR(primary)[2] & 0x1));
  //send the next bit that we have stored.
  TOS_CALL_COMMAND(SEC_DED_SUB_TX_BIT)(VAR(primary)[2] & 0x01);
  //right shift the buffer.
  VAR(primary)[2] = VAR(primary)[2] >> 1;
  //increment our bytes sent count.
  VAR(count) ++;
  if(VAR(count) == 8){
    //once 8 have gone out, get ready to send out the remaining bits
    VAR(primary)[2] = VAR(primary)[1];
  }
  else if(VAR(count) == 16){
    //once 16 have gone out, get ready to send out the remaining bits
    VAR(primary)[2] = VAR(primary)[0];
  }
  else if(VAR(count) == 18){
    if(VAR(state) == TX_TWO_ENCODED_STATE){
      //if another byte is ready, then shift the 
      //ready to send data over to the primary buffer for transmission
      VAR(primary)[0] = VAR(secondary)[0];
      VAR(primary)[1] = VAR(secondary)[1];
      VAR(primary)[2] = VAR(secondary)[2];
      
      VAR(count) = 0;
      //now only one byte is bufferred.
      VAR(state) = TX_ONE_ENCODED_STATE;  
      //TOS_SIGNAL_EVENT(SEC_DED_TX_BYTE_READY)(1);//fire the byte transmitted event.
    }
    else{
      //if there are no bytes buffered, go back to idle.
      VAR(state) = RX_IDLE_STATE;
      VAR(count) = 0;
      // Restore the radio to the listen for the preamble
      TOS_CALL_COMMAND(SEC_DED_SUB_RX_IDLE_ACTIVATE)();
	// Signal to upper layer in the network stack that transmission is done
      TOS_SIGNAL_EVENT(SEC_DED_TX_BYTE_READY)(1);
      TOS_SIGNAL_EVENT(SEC_DED_TX_DONE)();
    }
  }
  return 1;
}

char TOS_COMMAND(SEC_DED_TX_BYTES)(char data) {
  char rval = 1;
  if (!IN_TX()) {
    rval = TOS_CALL_COMMAND(SEC_DED_SUB_TX_MAC_ACTIVATE)();
    if (rval) {
      VAR(count) = 0;
      VAR(secondary[0]) = data;
      TOS_POST_TASK(radio_encode_thread);
      VAR(state) = TX_NONE_ENCODED_STATE;
    }
  }
  else if (VAR(state) == TX_ONE_ENCODED_STATE){
	//if in the middle of a transmission and one byte is encoded
	//go to the one byte encoded and one byte in the encode buffer.
	VAR(state) = TX_ONE_WAITING_STATE;
	VAR(secondary[0]) = data;
	//schedule the encode task.
	TOS_POST_TASK(radio_encode_thread);
	return 1;
  }
  else if(VAR(state) == TX_TWO_ENCODED_STATE){
    // buffer is full, can't handle anymore!
    // so, return error!!
    return 0;
  }
  return rval;
}
  
// This handles the signal strength data
char TOS_EVENT(SEC_DED_SIGNAL_DATA_READY)(short data)
{
  VAR(strength) = data;
  return 1;
}


  
