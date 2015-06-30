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
 * Authors:		Jason Hill, Alec Woo, and Wei Ye
 *
 *$Log: SEC_DED_RADIO_BYTE_SIGNAL.c,v $
 *Revision 1.4  2002/01/31 02:31:48  rrubin
 *int to short
 *
 *Revision 1.3  2001/10/14 19:50:16  scipio
 *Fixed network stack to follow naming, etc.
 *
 *Revision 1.6  2001/10/12 04:23:43  alecwoo
 *Add in signal strength measurement of the radio baseband.
 *
 *Revision 1.5  2001/10/11 09:43:35  alecwoo
 *Integrated with ISI improvement on the start symbol detection.
 *Clean up the entire file.
 *Added relevant comments.
 *
 */

/***********************************************************************************************
This component implements the byte level abstraction of the network stack using
   Single Error Correction and Double Error Detection (SEC_DED) Encoding.  For one byte
   of data, 18 bits of encoded information is generated.  The functionalities of this component 
   include:
   - byte level network component
   - preamble and start symbol detection
   - SED_DED encode and decode
   - MAC layer specifics
     - pre-transmission random delay, CSMA, and backoff
   - baseband signal strength measurement (only perform 1 sample of a high bit)
       Contributors : Edward Cedeno 	 (edddie@eden.rutgers.edu)
                      Christopher Carrer (ccarrer@eden.rutgers.edu)
                      Kevin Wine 	 (kevinw@liman.Rutgers.edu)
       Date        : 6 Sept 2001
   
**************************************************************************************************/


#include "tos.h"
#include "SEC_DED_RADIO_BYTE_SIGNAL.h"
#include "dbg.h"

#define IDLE_STATE              0 // Searching for preamble
#define MATCH_START_SYMBOL      1 // Searching for start symbol
#define ADJUST_SAMPLE_POS       2 // Adjust sample position of incoming packet
#define BIT_WAITING_STATE       3 // Now, position is adjusted, waiting for data
#define START_STATE             4 // Starting transmission of a packet
#define CLOCKING_STATE          5 // Reading bits one by one from the radio
#define HAS_READ_STATE          6 // Now, the whole encoded byte (18 bit) is read
#define DECODE_READY_STATE      7 // Ready to decode the encoded byte just received and discard the highest bit
#define ONE_ENCODED_STATE       8 // One byte encoded
#define ONE_WAITING_STATE       9 // One byte has already encoded for transmission, next byte is pending to be encoded
#define TWO_ENCODED_STATE       10 // Two bytes encoded in the buffer
#define IDLE_WAITING_STATE      11 // This is for CSMA (MAC layer)
#define BACKOFF_STATE           12 // This is for Backoff (MAC layer)

/* Frame of the component */
#define TOS_FRAME_TYPE bitread_frame
TOS_FRAME_BEGIN(radio_frame) {
  char primary[3];                // internal buffer
  char secondary[3];              // internal buffer
  char state;                     // state of this component
  char count;                     // internal counter
  char last_bit;                  // internal flag
  char startSymBits;              // time limit to return to preamble detection if start symbol is not found
  char sampled;                   // flag to indicate whether baseband has been sampled
  unsigned int waiting;           // MAC variable for waiting amount
  unsigned int delay;             // MAC variable for delay counter
  unsigned int strength;          // signal strength at the baseband of the radio
}
TOS_FRAME_END(radio_frame);


/* This is a TASK for encoding a byte. (8 bits to 18 bits) */
TOS_TASK(radio_encode_thread)
{
    //encode byte and store it into buffer.
    encodeData();
    //if this is the start of a transmisison, encode the start symbol.
    if(VAR(state) == START_STATE){
	
	VAR(primary)[0] = 0x2;  //start frame 0x10
	VAR(primary)[1] = 0x6a; //start frame 0x01101010
	VAR(primary)[2] = 0xcd; //start frame 0x11001101
    	VAR(count) = 0;         // reset the counter

	VAR(state) = TWO_ENCODED_STATE;//there are now 2 bytes encoded.
    }else{
	VAR(state) = TWO_ENCODED_STATE;//there are now 2 bytes encoded.
    }	    
    dbg(DBG_ENCODE, ("radio_encode_thread running: %x, %x\n", VAR(secondary[1]), VAR(secondary[2])));
}


/* This is a TASK for decoding an encoded byte (18 bits to 8 bits)*/
TOS_TASK(radio_decode_thread)
{

  unsigned int strength;

  dbg(DBG_ENCODE, ("radio_decode_thread running: %x, %x\n", VAR(secondary[1]), VAR(secondary[2])));
  
  strength = VAR(strength);
  VAR(strength) = 0;

  //decode the byte that has been recieved.
  if(!(TOS_SIGNAL_EVENT(RADIO_BYTE_RX_BYTE_READY)(decodeData(), 0, strength))){
    //if the event returns false, then stop receiving, go to search for the
    //preamble at the high sampling rate.
    VAR(state) = IDLE_STATE;
    VAR(sampled) = 0;
    TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
  }
  
}		


/* This is the initialization of the component */
char TOS_COMMAND(RADIO_BYTE_INIT)(){
    VAR(state) = IDLE_STATE;
    TOS_CALL_COMMAND(RADIO_SUB_INIT)();
    VAR(delay) = 0;
    VAR(sampled) = 0;

    dbg(DBG_BOOT, ("Radio Byte handler initialized.\n"));

    return 1;
}

/* This processes the command for transmitting a byte */
char TOS_COMMAND(RADIO_BYTE_TX_BYTES)(char data){

    dbg(DBG_ENCODE, ("TX_bytes: state=%x, data=%x\n", VAR(state), data));

    if(VAR(state) == IDLE_STATE){
	//if currently in idle mode, then switch over to transmit mode
	//and set state to waiting to transmit first byte.
	VAR(secondary[0]) = data;

	TOS_CALL_COMMAND(RADIO_SUB_PWR)(2);           // Turn radio off
	TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);  // Set rate to TX rate
	// Only pick the lowest 64 bits of the random number for random delay
	// Note:  This parameter can be changed for different MAC behavior
	VAR(waiting) = TOS_CALL_COMMAND(RADIO_SUB_NEXT_RAND)() & 0x3f;
	// MAC Sepcific:  Goes to Random Delay before Transmission
	VAR(state) = BACKOFF_STATE;

	return 1;
    }else if(VAR(state) == ONE_ENCODED_STATE){
	//if in the middle of a transmission and one byte is encoded
	//go to the one byte encoded and one byte in the encode buffer.
	VAR(state) = ONE_WAITING_STATE;
	VAR(secondary[0]) = data;
	//schedule the encode task.
	TOS_POST_TASK(radio_encode_thread);
	return 1;
    }else if(VAR(state) == TWO_ENCODED_STATE){
        // buffer is full, can't handle anymore!
        // so, return error!!
        return 0;
    }
    return 0;
}

/* This process the power command of the component */
/* mode = 0 (low power) */
/* mode = others (search for preamble) */
char TOS_COMMAND(RADIO_BYTE_PWR)(char mode){
    if(mode == 0){
	//if low power mode, tell lower components
    	VAR(state) = IDLE_STATE;
	TOS_CALL_COMMAND(RADIO_SUB_PWR)(0);
    }else{
	//set the RMF component into "search for preamble" mode.
	TOS_CALL_COMMAND(RADIO_SUB_PWR)(1);
	TOS_CALL_COMMAND(RADIO_SUB_RX_MODE)();
	TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
	// Reset this component
	VAR(state) = IDLE_STATE;
        VAR(count) = 0;
        //VAR(last_bit) = 0xff;
    }
    return 1;
}


/* This event handler shfits out the next bit to the radio for transmission */
char TOS_EVENT(RADIO_BYTE_TX_BIT_EVENT)(){

    dbg(DBG_ENCODE, ("radio tx bit event %d\n", VAR(primary)[2] & 0x1));

    //if we're not it a transmit state, return false.
    if(VAR(state) != ONE_ENCODED_STATE &&
       VAR(state) != ONE_WAITING_STATE &&
       VAR(state) != TWO_ENCODED_STATE) {
      return 0;
    }
    
    //send the next bit that we have stored.
    TOS_CALL_COMMAND(RADIO_SUB_TX_BIT)(VAR(primary)[2] & 0x01);
    //right shift the buffer.
    VAR(primary)[2] = VAR(primary)[2] >> 1;
    //increment our bytes sent count.
    VAR(count) ++;
    if(VAR(count) == 8){
	//once 8 have gone out, get ready to send out the remaining bits
	VAR(primary)[2] = VAR(primary)[1];
    }else if(VAR(count) == 16){
	//once 16 have gone out, get ready to send out the remaining bits
	VAR(primary)[2] = VAR(primary)[0];
    }else if(VAR(count) == 18){
	if(VAR(state) == TWO_ENCODED_STATE){
	    //if another byte is ready, then shift the 
	    //ready to send data over to the primary buffer for transmission
	    VAR(primary)[0] = VAR(secondary)[0];
	    VAR(primary)[1] = VAR(secondary)[1];
	    VAR(primary)[2] = VAR(secondary)[2];
	    
	    VAR(count) = 0;
	    //now only one byte is bufferred.
	    VAR(state) = ONE_ENCODED_STATE;  
	    TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(1);//fire the byte transmitted event.
	}else{
	    //if there are no bytes bufferred, go back to idle.
	    VAR(state) = IDLE_STATE;

	    // Signal to upper layer in the network stack that transmission is done
	    TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(1);
	    TOS_SIGNAL_EVENT(RADIO_BYTE_TX_DONE)();

	    // Restore the radio to the listen for the preamble
	    TOS_CALL_COMMAND(RADIO_SUB_RX_MODE)();
	    TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
	}
    }
    return 1;
}	
		
/* This event handler shfits in the incoming bit sampled by the radio and attempts to
   detect preamble or start symbol.  Once start symbol is detected, it will shifts in 
   the encoded data and post a TASK to decode the data accordingly.
*/
char TOS_EVENT(RADIO_BYTE_RX_BIT_EVENT)(char data){

    if(VAR(state) == IDLE_STATE){
      // We are in the idle state and we just look for the preamble
      VAR(primary)[1] = (VAR(primary)[1] << 1) & 0x6;
      if (VAR(primary)[2] & 0x80)
	VAR(primary)[1] |= 0x1;
      VAR(primary)[2] = VAR(primary)[2] << 1;
      VAR(primary)[2] = VAR(primary)[2] | (data & 0x1);
      
      if (VAR(primary)[1] == 0x7 && (VAR(primary)[2] & 0x77) == 0x7){
	// found preamble
	// clear the following buffer for matching start symbol
	VAR(startSymBits) = 24;
	VAR(primary)[1] = 0;
	VAR(primary)[2] = 0;
	VAR(secondary)[1] = 0;
	VAR(secondary)[2] = 0;
	VAR(last_bit) = 1; // set to use first group of samples
	// Start to match start symbol
	VAR(state) = MATCH_START_SYMBOL;
      }
    } else if (VAR(state) == MATCH_START_SYMBOL){
      VAR(startSymBits)--;
      if (VAR(startSymBits) == 0){
	// failed to detect start symbol, go back to detect preamble
	VAR(state) = IDLE_STATE;
	return 1;
      }
      // put new data into two groups to match start symbol
      if (VAR(last_bit)) {  // just put into second group, now for first
	VAR(last_bit) = 0;
	
	VAR(primary)[2] >>= 1;
	VAR(primary)[2] &= 0x7f;  // clear the highest bit
	//if lowest bit of first is one, store it in second
	if(VAR(primary)[1] & 0x1) VAR(primary)[2] |= 0x80;
	VAR(primary)[1] = data & 0x1;  // start symbol is 9 bits
	if (VAR(primary)[1] == 0x1 && VAR(primary)[2] == 0x35 ) {
	  // 1st group matches, read one more bit for 2nd group
	  
	  VAR(state) = ADJUST_SAMPLE_POS;
	  VAR(secondary)[2] >>= 1;
	  VAR(secondary)[2] &= 0x7f; 
	  if (VAR(secondary)[1] & 0x1) VAR(secondary)[2] |= 0x80;
	}
	
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

      VAR(state) = BIT_WAITING_STATE;  // waiting for first bit	
    }else if(VAR(state) == BIT_WAITING_STATE){
	//just read first bit.
	//set bit rate to do one time sampling
	TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);
	VAR(state) = CLOCKING_STATE;
	VAR(count) = 1;
	//store the first incoming bit
	if(data){
	    VAR(primary)[1] = 0x80;
	    if (VAR(sampled) == 0){
	      // Sample the baseband for signal strength if it is a one
	      TOS_CALL_COMMAND(RADIO_SUB_ADC_GET_DATA)(0);
	      VAR(sampled) = 1;
	    }
	}else{
	    VAR(primary)[1] = 0;
	}
    }else if(VAR(state) == CLOCKING_STATE){
	//clock in the rest of the incoming bits.
	VAR(count)++;
	VAR(primary)[1] >>= 1;
	VAR(primary)[1] &= 0x7f;
	if(data){
	    VAR(primary)[1] |= 0x80;
	    if (VAR(sampled) == 0){
	      // Sample the baseband for signal strength if it is a one
	      TOS_CALL_COMMAND(RADIO_SUB_ADC_GET_DATA)(0);
	      VAR(sampled) = 1;
	    }
	}
	if(VAR(count) == 8){
	    VAR(secondary[2]) = VAR(primary[1]);
	}else if(VAR(count) == 16){
	    VAR(count)++;
	    //store the encoded data into a buffer.
	    VAR(secondary)[1] = VAR(primary)[1];
	    VAR(state) = HAS_READ_STATE;
	}
    }else if(VAR(state) == HAS_READ_STATE){
         VAR(secondary)[0] = data;
	 VAR(state) = DECODE_READY_STATE;
    }else if(VAR(state) == DECODE_READY_STATE){
	//throw away the higest bit.
	 VAR(state) = BIT_WAITING_STATE;
	 //scheduled the decode task to decode the encoded byte just receive
	 TOS_POST_TASK(radio_decode_thread);
	 dbg(DBG_ENCODE, ("entire byte received: %x, %x\n", VAR(secondary)[1], VAR(secondary)[2]));

    }else if(VAR(state) == IDLE_WAITING_STATE){
	// MAC CSMA:  waiting for channle to be idle.
	if(data){
	    //if we just read activity, then reset the waiting counter.
	   VAR(waiting) = 0;
	   TOS_CALL_COMMAND(RADIO_SUB_PWR)(2);  // Turn radio off
	   TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);  // Set rate to TX rate during radio off
	   // Pick a random number and use the lowest 11 bits as the random window for backoff
	   VAR(waiting) = TOS_CALL_COMMAND(RADIO_SUB_NEXT_RAND)() & 0x3ff;
	   VAR(state) = BACKOFF_STATE;  // Goes to Backoff/Delay
        }else{
	   //if we've not heard anything for more than 7 samples then assume channel is clean
	   if(VAR(waiting)++ > 6){
	       VAR(waiting) = 0;
	       //schedule task to start transfer, set TX_mode, and set bit rate on the radio
	       TOS_CALL_COMMAND(RADIO_SUB_TX_MODE)();
	       TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);
	       //go to the transmit state.
	       VAR(state) = START_STATE;
	       TOS_POST_TASK(radio_encode_thread);
	   }	
	}	
    } else if (VAR(state) == BACKOFF_STATE){
      // This is the delay during backoff
      VAR(delay)++;
      if (VAR(delay) >= VAR(waiting)){
	// Set the radio to listening again at 2x sampling rate
	TOS_CALL_COMMAND(RADIO_SUB_PWR)(1);
	TOS_CALL_COMMAND(RADIO_SUB_RX_MODE)();
	TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
	VAR(delay) = 0;
	VAR(waiting) = 0;
	VAR(state) = IDLE_WAITING_STATE;  // Goes back to CSMA listening
      }
    }
    return 1;
}


/* This function encode the data using SEC_DED encoding */
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

/* This function decodes SEC_DED encoded data */
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

// This handles the signal strength data
char TOS_EVENT(RADIO_BYTE_ADC_DATA_READY)(short data)
{
  VAR(strength) = data;
  return 1;
}
