// $Id: SecDedRadioByteSignal.nc,v 1.2 2003/10/07 21:46:37 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Jason Hill, Alec Woo, Wei Ye, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 *
 *
 */

/*
 * This component implements the byte level abstraction of the 10Kb
 * rene network stack using Single Error Correction and Double Error
 * Detection (SEC_DED) Encoding.  For one byte of data, 18 bits of
 * encoded information is generated.  The functionalities of this
 * component include:
 *
 *  - byte level network component
 *  - preamble and start symbol detection
 *  - SED_DED encode and decode
 *  - MAC layer specifics
 *    - pre-transmission random delay, CSMA, and backoff
 *  - baseband signal strength measurement (only 1 sample of a high bit)
 *      Contributors : Edward Cedeno 	 (edddie@eden.rutgers.edu)
 *                     Christopher Carrer (ccarrer@eden.rutgers.edu)
 *                     Kevin Wine 	 (kevinw@liman.Rutgers.edu)
 *      Date        : 6 Sept 2001
 * 
 */

/**
 * @author Jason Hill
 * @author Alec Woo
 * @author Wei Ye
 * @author David Gay
 * @author Philip Levis
 */


module SecDedRadioByteSignal {
  provides {
    interface ByteComm;
    interface StdControl as Control;
  }
  uses {
    interface Radio;
    interface StdControl as RadioControl;
    interface ADC as StrengthADC;
    interface ADCControl;
    interface Random;
    interface Leds;
  }
}
implementation
{

  enum {
    IDLE_STATE =              0, // Searching for preamble
    MATCH_START_SYMBOL =      1, // Searching for start symbol
    ADJUST_SAMPLE_POS =       2, // Adjust sample position of incoming packet
    BIT_WAITING_STATE =       3, // Now, position is adjusted, waiting for data
    START_STATE =             4, // Starting transmission of a packet
    CLOCKING_STATE =          5, // Reading bits one by one from the radio
    HAS_READ_STATE =          6, // Now, the whole encoded byte (18 bit) is read
    DECODE_READY_STATE =      7, // Ready to decode the encoded byte just received and discard the highest bit
    ONE_ENCODED_STATE =       8, // One byte encoded
    ONE_WAITING_STATE =       9, // One byte has already encoded for transmission, next byte is pending to be encoded
    TWO_ENCODED_STATE =       10,// Two bytes encoded in the buffer
    IDLE_WAITING_STATE =      11,// This is for CSMA (MAC layer)
    BACKOFF_STATE =           12 // This is for Backoff (MAC layer)
  };

  uint8_t primary[3];		// internal buffer
  uint8_t secondary[3];		// internal buffer
  uint8_t state;		// state of this component
  uint8_t count;		// internal counter
  uint8_t last_bit;		// internal flag
  uint8_t startSymBits;		// time limit to return to preamble detection if start symbol is not found
  bool sampled;			// flag to indicate whether baseband has been sampled
  uint16_t waiting;		// MAC variable for waiting amount
  uint16_t delay;		// MAC variable for delay counter
  uint16_t strength;		// signal strength at the baseband of the radio


  /* This is a TASK for encoding a byte. (8 bits to 18 bits) */
  void encodeData();
  task void  radioEncodeThread() {
    //encode byte and store it into buffer.
    encodeData();
    //if this is the start of a transmisison, encode the start symbol.
    if (state == START_STATE)
      {
	
	primary[0] = 0x2;  //start frame 0x10
	primary[1] = 0x6a; //start frame 0x01101010
	primary[2] = 0xcd; //start frame 0x11001101
	count = 0;         // reset the counter

	state = TWO_ENCODED_STATE;//there are now 2 bytes encoded.
      }
    else
      state = TWO_ENCODED_STATE;//there are now 2 bytes encoded.

    dbg(DBG_ENCODE, "radio_encode_thread running: %x, %x\n",
	secondary[1], secondary[2]);
  }


  /* This is a TASK for decoding an encoded byte (18 bits to 8 bits)*/
  uint8_t decodeData();
  task void radioDecodeThread() {
    uint16_t st;
    dbg(DBG_ENCODE, "radio_decode_thread running: %x, %x\n", secondary[1], secondary[2]);
  
    st = strength;
    strength = 0;

    //decode the byte that has been recieved.
    if (!signal ByteComm.rxByteReady(decodeData(), 0, st))
      {
	//if the event returns false, then stop receiving, go to search for the
	//preamble at the high sampling rate.
	state = IDLE_STATE;
	sampled = FALSE;
	call Radio.setBitRate(0);
      }
  }


  /* This is the initialization of the component */
  command result_t Control.init() {
    result_t r1, r2, r3;

    state = IDLE_STATE;
    delay = 0;
    sampled = FALSE;

    dbg(DBG_BOOT, "Radio Byte handler initialized.\n");

    r1 = call RadioControl.init();
    r2 = call ADCControl.init();
    r3 = call Random.init();

    return rcombine3(r1, r2, r3);
  }

  /* This processes the command for transmitting a byte */
  command result_t ByteComm.txByte(uint8_t data) {

    dbg(DBG_ENCODE, "TX_bytes: state=%x, data=%x\n", state, data);

    switch (state)
      {
      case IDLE_STATE:
	//if currently in idle mode, then switch over to transmit mode
	//and set state to waiting to transmit first byte.
	secondary[0] = data;

	call RadioControl.power(2);	// Turn radio off
	call Radio.setBitRate(2); // Set rate to TX rate
	// Only pick the lowest 6 bits of the random number for random delay
	// Note:  This parameter can be changed for different MAC behavior
	waiting = call Random.rand() & 0x3f;
	// MAC Sepcific:  Goes to Random Delay before Transmission
	state = BACKOFF_STATE;

	return SUCCESS;

      case ONE_ENCODED_STATE:
	//if in the middle of a transmission and one byte is encoded
	//go to the one byte encoded and one byte in the encode buffer.
	state = ONE_WAITING_STATE;
	secondary[0] = data;
	//schedule the encode task.
	post radioEncodeThread();
	return SUCCESS;

      case TWO_ENCODED_STATE:
      default:
        // buffer is full, can't handle anymore!
        // so, return error!!
        return FAIL;
      }
  }

  /* This process the power command of the component */
  /* mode = 0 (low power) */
  /* mode = others (search for preamble) */
  command result_t Control.power(char mode) {
    if (mode == 0)
      {
	//if low power mode, tell lower components
    	state = IDLE_STATE;
	return call RadioControl.power(0);
      }
    else
      {
	//set the RFM component into "search for preamble" mode.
	call RadioControl.power(1);
	call Radio.rxMode();
	call Radio.setBitRate(0);
	// Reset this component
	state = IDLE_STATE;
        count = 0;
	return SUCCESS;
    }
  }

  // This event handler shfits out the next bit to the radio for transmission 
  event result_t Radio.txBitDone() {
    dbg(DBG_ENCODE, "radio tx bit event %d\n", primary[2] & 0x1);

    // if we're not it a transmit state, return false.
    if (state != ONE_ENCODED_STATE &&
	state != ONE_WAITING_STATE &&
	state != TWO_ENCODED_STATE)
      return FAIL;
    
    //send the next bit that we have stored.
    call Radio.txBit(primary[2] & 0x01);
    //right shift the buffer.
    primary[2] = primary[2] >> 1;
    //increment our bits sent count.
    count++;
    if (count == 8)
      //once 8 have gone out, get ready to send out the remaining bits
      primary[2] = primary[1];
    else if (count == 16)
      //once 16 have gone out, get ready to send out the remaining bits
      primary[2] = primary[0];
    else if (count == 18)
      {
	if (state == TWO_ENCODED_STATE)
	  {
	    //if another byte is ready, then shift the 
	    //ready to send data over to the primary buffer for transmission
	    primary[0] = secondary[0];
	    primary[1] = secondary[1];
	    primary[2] = secondary[2];
	    
	    count = 0;
	    //now only one byte is bufferred.
	    state = ONE_ENCODED_STATE;  
	    signal ByteComm.txByteReady(SUCCESS); //fire the byte transmitted event.
	  }
	else
	  {
	    //if there are no bytes bufferred, go back to idle.
	    state = IDLE_STATE;

	    // Signal to upper layer in the network stack that transmission is done
	    signal ByteComm.txDone();
	    signal ByteComm.txByteReady(SUCCESS);

	    // Restore the radio to the listen for the preamble
	    call Radio.rxMode();
	    call Radio.setBitRate(0);
	}
      }
    return SUCCESS;
  }
		
  /* This event handler shfits in the incoming bit sampled by the radio and
   attempts to detect preamble or start symbol.  Once start symbol is
   detected, it will shifts in the encoded data and post a TASK to decode
   the data accordingly.  */
  event result_t Radio.rxBit(uint8_t data) {
    switch (state)
      {
      case IDLE_STATE:
	// We are in the idle state and we just look for the preamble
	primary[1] = (primary[1] << 1) & 0x6;
	if (primary[2] & 0x80)
	  primary[1] |= 0x1;
	primary[2] = primary[2] << 1;
	primary[2] = primary[2] | (data & 0x1);
      
	if (primary[1] == 0x7 && (primary[2] & 0x77) == 0x7)
	  {
	    // found preamble
	    // clear the following buffer for matching start symbol
	    startSymBits = 24;
	    primary[1] = 0;
	    primary[2] = 0;
	    secondary[1] = 0;
	    secondary[2] = 0;
	    last_bit = 1; // set to use first group of samples
	    // Start to match start symbol
	    state = MATCH_START_SYMBOL;
	  }
	break;

      case MATCH_START_SYMBOL:
	startSymBits--;
	if (startSymBits == 0)
	  {
	    // failed to detect start symbol, go back to detect preamble
	    state = IDLE_STATE;
	    return SUCCESS;
	  }

	// put new data into two groups to match start symbol
	if (last_bit)
	  {  // just put into second group, now for first
	    last_bit = 0;
	
	    primary[2] >>= 1;
	    primary[2] &= 0x7f;  // clear the highest bit
	    //if lowest bit of first is one, store it in second
	    if (primary[1] & 0x1) primary[2] |= 0x80;
	    primary[1] = data & 0x1;  // start symbol is 9 bits
	    if (primary[1] == 0x1 && primary[2] == 0x35 )
	      {
		// 1st group matches, read one more bit for 2nd group
	  
		state = ADJUST_SAMPLE_POS;
		secondary[2] >>= 1;
		secondary[2] &= 0x7f; 
		if (secondary[1] & 0x1) secondary[2] |= 0x80;
	      }
	  }
	else
	  {  // just put into first group, now for second
	    last_bit = 1;
	    secondary[2] >>= 1;
	    secondary[2] &= 0x7f;  // clear the highest bit
	    //if lowest bit of first is one, store it in second
	    if (secondary[1] & 0x1) secondary[2] |= 0x80;
	    secondary[1] = data & 0x1;  // start symbol is 9 bits
	    if (secondary[1] == 0x1 && secondary[2] == 0x35)
	      {
		// 2nd group matches, read one more bit for 1st group
		state = ADJUST_SAMPLE_POS;
		primary[2] >>= 1;
		primary[2] &= 0x7f; 
		if (primary[1] & 0x1) primary[2] |= 0x80;
	      }
	  }                 
	break;

      case ADJUST_SAMPLE_POS:
	// start symbol already detected
	// use this additional bit for better sampling alignment
	if (last_bit)
	  {
	    if ((data & 0x1) && primary[2] == (char)0x35 )
	      // both groups match start symbol
	      call Radio.setBitRate(1); // 1.5x bit rate
	  }
	else
	  {
	    if ((data & 0x1) && secondary[2] == (char)0x35)
	      // both groups match start symbol
	      call Radio.setBitRate(1); // 1.5x bit rate
	  }
	state = BIT_WAITING_STATE;  // waiting for first bit	
	break;

      case BIT_WAITING_STATE: 
	//just read first bit.
	//set bit rate to do one time sampling
	call Radio.setBitRate(2);
	state = CLOCKING_STATE;
	count = 1;
	//store the first incoming bit
	if (data)
	  {
	    primary[1] = 0x80;
	    if (!sampled){
	      // Sample the baseband for signal strength if it is a one
	      call StrengthADC.getData();
	      sampled = TRUE;
	    }
	  }
	else
	  primary[1] = 0;
	break;

      case CLOCKING_STATE:
	//clock in the rest of the incoming bits
	count++;
	primary[1] >>= 1;
	primary[1] &= 0x7f;
	if (data)
	  {
	    primary[1] |= 0x80;
	    if (!sampled)
	      {
		// Sample the baseband for signal strength if it is a one
		call StrengthADC.getData();
		sampled = TRUE;
	      }
	  }
	if (count == 8)
	  secondary[2] = primary[1];
	else if (count == 16)
	  {
	    count++;
	    //store the encoded data into a buffer.
	    secondary[1] = primary[1];
	    state = HAS_READ_STATE;
	  }
	break;

      case HAS_READ_STATE:
	secondary[0] = data;
	state = DECODE_READY_STATE;
	break;

      case DECODE_READY_STATE:
	//throw away the higest bit.
	state = BIT_WAITING_STATE;
	//scheduled the decode task to decode the encoded byte just receive
	post radioDecodeThread();
	dbg(DBG_ENCODE, "entire byte received: %x, %x\n", secondary[1], secondary[2]);

	break;

      case IDLE_WAITING_STATE:
	// MAC CSMA:  waiting for channle to be idle.
	if (data)
	  {
	    //if we just read activity, then reset the waiting counter.
	    waiting = 0;
	    call RadioControl.power(2);  // Turn radio off
	    call Radio.setBitRate(2);  // Set rate to TX rate during radio off
	    // Pick a random number and use the lowest 11 bits as the random window for backoff
	    waiting = call Random.rand() & 0x3ff;
	    state = BACKOFF_STATE;  // Goes to Backoff/Delay
	  }
	else
	  {
	    //if we've not heard anything for more than 7 samples then
	    //assume channel is clean
	    if (waiting++ > 6)
	      {
		waiting = 0;
		//schedule task to start transfer, set TX_mode, and set bit
		//rate on the radio
		call Radio.txMode();
		call Radio.setBitRate(2);
		//go to the transmit state.
		state = START_STATE;
		post radioEncodeThread();
	      }	
	  }	
	break;

      case BACKOFF_STATE:
	// This is the delay during backoff
	delay++;
	if (delay >= waiting)
	  {
	    // Set the radio to listening again at 2x sampling rate
	    call RadioControl.power(1);
	    call Radio.rxMode();
	    call Radio.setBitRate(0);
	    delay = 0;
	    waiting = 0;
	    state = IDLE_WAITING_STATE;  // Goes back to CSMA listening
	  }
	break;
      }
    return SUCCESS;
  }


  /* This function encode the data using SEC_DED encoding */
  void encodeData() {
    char ret_high = 0;
    char ret_low = 0;
    char ret_mid = 0;
    char val = secondary[0];
    if ((val & 0x1) != 0) {
      ret_high ^=0;
      ret_mid ^=0x0;
      ret_low ^=0x77;
    }
    if ((val & 0x2) != 0) {
      ret_high ^=0;
      ret_mid ^=0x1;
      ret_low ^=0x34;
    }	
    if ((val & 0x4) != 0) {
      ret_high ^=0;
      ret_mid ^=0x2;
      ret_low ^=0x32;
    }
    if ((val & 0x8) != 0) {
      ret_high ^=0;
      ret_mid ^=0x8;
      ret_low ^=0x31;
    }
    if ((val & 0x10) != 0) {
      ret_high ^=0;
      ret_mid ^=0x10;
      ret_low ^=0x26;
    }
    if ((val & 0x20) != 0) {
      ret_high ^=0;
      ret_mid ^=0x60;
      ret_low ^=0x25;
    }	
    if ((val & 0x40) != 0) {
      ret_high ^=0;
      ret_mid ^=0x80;
      ret_low ^=0x13;
    }	
    if ((val & 0x80) != 0) {
      ret_high ^=0x1;
      ret_mid ^=0;
      ret_low ^=0x7;
    }
  
    if ((ret_low & 0xc) == 0) ret_low |= 0x8;
    if ((ret_low & 0x40) == 0 && (ret_mid & 0x1) == 0) ret_low |= 0x80;
    if ((ret_mid & 0xa) == 0) ret_mid |= 0x4;
    if ((ret_mid & 0x50) == 0) ret_mid |= 0x20;
    if ((ret_high & 0x1) == 0) ret_high |= 0x2;
  
  
    secondary[0] = ret_high;
    secondary[1] = ret_mid;
    secondary[2] = ret_low;
  }

  /* This function decodes SEC_DED encoded data */
  uint8_t  decodeData() {
    //strip the data
    char ret_high = 0;
    char ret_low = 0;
    char val, val2, output;
  
  
    ret_high = (char)((secondary[0] << 4) & 0x10);
    ret_high |= (char)((secondary[1] >> 4) & 0xc);
    ret_high |= (char)((secondary[1] >> 3) & 0x3);
    ret_low = (char)((secondary[1] << 6) & 0xc0);
    ret_low |= (char)((secondary[2] >> 1) & 0x38);
    ret_low |= (char)(secondary[2]  & 0x7);
    //check the data
    val = ret_low;
    val2 = ret_high;
    output = 0;
    if ((val & 0x1) != 0) output ^= 0x1;  
    if ((val & 0x2) != 0) output ^= 0x2;
    if ((val & 0x4) != 0) output ^= 0x4;
    if ((val & 0x8) != 0) output ^= 0x8;
    if ((val & 0x10) != 0) output ^= 0x10;
    if ((val & 0x20) != 0) output ^= 0x1f;
    if ((val & 0x40) != 0) output ^= 0x1c;
    if ((val & 0x80) != 0) output ^= 0x1a;
    if ((val2 & 0x1) != 0) output ^= 0x19;
    if ((val2 & 0x2) != 0) output ^= 0x16;
    if ((val2 & 0x4) != 0) output ^= 0x15;
    if ((val2 & 0x8) != 0) output ^= 0xb;
    if ((val2 & 0x10) != 0) output ^= 0x7;
    if (output == 0){}
    else if (output == 0x1) { val ^= 0x1;} 
    else if (output == 0x2) { val ^= 0x2; }
    else if (output == 0x4) { val ^= 0x4; }
    else if (output == 0x8) { val ^= 0x8; }
    else if (output == 0x10) { val ^= 0x10;}
    else if (output == 0x1f) { val ^= 0x20;}
    else if (output == 0x1c) { val ^= 0x40;}
    else if (output == 0x1a) { val ^= 0x80;}
    else if (output == 0x19) { val2 ^= 0x1; }
    else if (output == 0x16) { val2 ^= 0x2; }
    else if (output == 0x15) { val2 ^= 0x4; }
    else if (output == 0xb) { val2 ^= 0x8; }
    else if (output == 0x7) { val2 ^= 0x10;}
  
    //pull off the data bits
    output = (char)((val >> 5) & 0x7);
    output |= ((char)val2 << 3) & 0xf8; 
    return output;
  }

  // This handles the signal strength data
  event result_t StrengthADC.dataReady(uint16_t data) {
    strength = data;
    return SUCCESS;
  }
}
