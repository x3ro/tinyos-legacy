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
 *                      Low power enhancements: Rob Szewczyk, based on
 *                      code of Jason Hill  
 */

#include "tos.h"
#include "MAC_LP.h"
#include "dbg.h"

/* Frame of the component */
#define TOS_FRAME_TYPE MACFrame
TOS_FRAME_BEGIN(MACFrame) {
  char state;
  char primary[3];
  char secondary[3];
  char count;                     // internal counter
  char power;
  char last_bit;                  // internal flag
  char startSymBits;              // time limit to go to preamble detect during start detect
  char sampled;                   // flag to indicate whether baseband has been sampled
  unsigned int waiting;           // MAC variable for waiting amount
  unsigned int delay;             // MAC variable for delay counter
  unsigned int strength;          // signal strength at the baseband of the radio
}
TOS_FRAME_END(MACFrame);

#define SINGLE_SAMPLE          0x0190   // 400 ticks
#define SINGLE_AND_HALF_SAMPLE 0x012c   // 300 ticks
#define DOUBLE_SAMPLE          0x00c8   // 200 ticks
#define OFF_TIME               0x0438   // 1040 ticks
#define ON_TIME                0x0078   // 80 ticks

#define RX_IDLE_STATE              0 // Searching for preamble
#define RX_DATA_BIT_WAITING_STATE  1 // Waiting for data to decode

#define TX_BACKOFF_STATE              4
#define TX_IDLE_WAITING_STATE         5

char TOS_COMMAND(MAC_INIT)(void) {
  VAR(state) = RX_IDLE_STATE;
  TOS_CALL_COMMAND(MAC_SUB_INIT)();
  TOS_CALL_COMMAND(MAC_SUB_RX_IDLE_ACTIVATE)();
  TOS_CALL_COMMAND(MAC_SUB_SET_BIT_RATE)(DOUBLE_SAMPLE);
  VAR(power) = 0;
  TOS_CALL_COMMAND(MAC_SUB_PWR_OFF)(OFF_TIME);
  VAR(delay) = 0;
  VAR(sampled) = 0;
  
  dbg(DBG_BOOT, ("MAC_LP initialized.\n"));

  return 1;
}

char TOS_EVENT(MAC_RX_IDLE_START)() {
    TOS_CALL_COMMAND(MAC_SUB_PWR_OFF)(OFF_TIME);
    VAR(power) = 0;
  return 1;
}

static inline unsigned short get_time() {
    return __inw(TCNT1L);
}

static inline void sleep_us() {
    asm volatile("nop" "\n\t" ::);
    asm volatile("nop" "\n\t" ::);
    asm volatile("nop" "\n\t" ::);
    asm volatile("nop" "\n\t" ::);
}

char TOS_EVENT(MAC_RX_IDLE_BIT_EVENT)(char bit) {
    // The kind of thing we'd like to incorporate here is:
    if (VAR(power) == 0) { // we've been sleeping. Ignore the reading, turn radio on, and pay attention to the next thing.  
	dbg(DBG_RADIO, ("RADIO: low power, taking on sample.\n"));
	TOS_CALL_COMMAND(MAC_SUB_PWR_ON)(OFF_TIME); //Set bit rate
	while (get_time() < ((unsigned short) ON_TIME)) {
	    sleep_us();
	}
	bit = READ_RFM_RXD_PIN();
	if (bit) { // we've detected a signal, transition to normal mode
	    TOS_CALL_COMMAND(MAC_SUB_SAMPLE_RSSI)(0);
	    VAR(power) = 2;
	    dbg(DBG_RADIO, ("RADIO: low power preamble detected. Swithing to double sample.\n"));
	    TOS_CALL_COMMAND(MAC_SUB_SET_BIT_RATE)(DOUBLE_SAMPLE);
	} else {
	    VAR(power) = 0;
	    dbg(DBG_RADIO, ("RADIO: low power, turning off sample.\n"));
	    TOS_CALL_COMMAND(MAC_SUB_PWR_OFF)(OFF_TIME);
	}
    } else {
	
	VAR(primary)[1] = (VAR(primary)[1] << 1) & 0x6;
	if (VAR(primary)[2] & 0x80) {
	    VAR(primary)[1] |= 0x1;
	}
	VAR(primary)[2] = VAR(primary)[2] << 1;
	VAR(primary)[2] = VAR(primary)[2] | (bit & 0x1);

	if ((VAR(primary)[2] & 0x3f) == 0) {
	    VAR(power) = 0;
	    TOS_CALL_COMMAND(MAC_SUB_PWR_OFF) (OFF_TIME);
	    dbg(DBG_RADIO, ("RADIO: low power. Nothing in the last few bits. Turning off.\n"));
	} else  if (VAR(primary)[1] == 0x7 && (VAR(primary)[2] & 0x77) == 0x7){
	    TOS_CALL_COMMAND(MAC_SUB_RX_START_ACTIVATE)();
	} 
    }
    return 1;
}

char TOS_EVENT(MAC_RX_START_START)() {
  // clear the following buffer for matching start symbol
  VAR(startSymBits) = 24;
  VAR(primary)[1] = 0;
  VAR(primary)[2] = 0;
  VAR(secondary)[1] = 0;
  VAR(secondary)[2] = 0;
  VAR(last_bit) = 1; // set to use first group of samples
  return 1;
}

char TOS_EVENT(MAC_RX_START_BIT_EVENT)(char bit) {
  VAR(startSymBits)--;
  if (VAR(startSymBits) == 0){
    // failed to detect start symbol, go back to detect preamble
      VAR(power) = 0;
    TOS_CALL_COMMAND(MAC_SUB_RX_IDLE_ACTIVATE)();
    return 1;
  }
  // put new data into two groups to match start symbol
  if (VAR(last_bit)) {  // just put into second group, now for first
    VAR(last_bit) = 0;
    
    VAR(primary)[2] >>= 1;
    VAR(primary)[2] &= 0x7f;  // clear the highest bit

    //if lowest bit of first is one, store it in second
    if(VAR(primary)[1] & 0x1) VAR(primary)[2] |= 0x80;
    VAR(primary)[1] = bit & 0x1;  // start symbol is 9 bits

    if (VAR(primary)[1] == 0x1 && VAR(primary)[2] == 0x35 ) {
      // 1st group matches, read one more bit for 2nd group
      TOS_CALL_COMMAND(MAC_SUB_RX_SYNC_ACTIVATE)();
      VAR(secondary)[2] >>= 1;
      VAR(secondary)[2] &= 0x7f; 
      if (VAR(secondary)[1] & 0x1) {
	VAR(secondary)[2] |= 0x80;
      }
    }
  }
  else {  // just put into first group, now for second
    VAR(last_bit) = 1;
    VAR(secondary)[2] >>= 1;
    VAR(secondary)[2] &= 0x7f;  // clear the highest bit
    //if lowest bit of first is one, store it in second
    if(VAR(secondary)[1] & 0x1) VAR(secondary)[2] |= 0x80;
    VAR(secondary)[1] = bit & 0x1;  // start symbol is 9 bits
    if (VAR(secondary)[1] == 0x1 && VAR(secondary)[2] == 0x35){
      // 2nd group matches, read one more bit for 1st group
      TOS_CALL_COMMAND(MAC_SUB_RX_SYNC_ACTIVATE)();
      VAR(primary)[2] >>= 1;
      VAR(primary)[2] &= 0x7f; 
      if(VAR(primary)[1] & 0x1) VAR(primary)[2] |= 0x80;
    }
  }
  return 1;
}

char TOS_EVENT(MAC_RX_SYNC_START)() {
  // do nothing
  return 1;
}

char TOS_EVENT(MAC_RX_SYNC_BIT_EVENT)(char bit) {
  // use this additional bit for better sampling alignment
  if (VAR(last_bit) && (bit & 0x1) && (VAR(primary)[2] == (char)0x35)) {
    // both groups match start symbol
    dbg(DBG_RADIO, ("RADIO: sample and a half to lock on signal.\n"));
    TOS_CALL_COMMAND(MAC_SUB_SET_BIT_RATE)(SINGLE_AND_HALF_SAMPLE); // 1.5x bit rate
  }
  else if ((bit & 0x1) && VAR(secondary)[2] == (char)0x35) {
    // both groups match start symbol
    dbg(DBG_RADIO, ("RADIO: sample and a half to lock on signal.\n"));
    TOS_CALL_COMMAND(MAC_SUB_SET_BIT_RATE)(SINGLE_AND_HALF_SAMPLE); // 1.5x bit rate
  }
  TOS_CALL_COMMAND(MAC_SUB_RX_DATA_ACTIVATE)();
  return 1;
}

char TOS_EVENT(MAC_TX_MAC_START)(void)   {
  VAR(state) = TX_BACKOFF_STATE;
  TOS_CALL_COMMAND(MAC_SUB_PWR_OFF)(DOUBLE_SAMPLE);
  VAR(waiting) = TOS_CALL_COMMAND(MAC_SUB_NEXT_RAND)() & 0x3f;
  VAR(delay) = 0;
  return 1;
}

char TOS_EVENT(MAC_TX_START_START)(void) {
    VAR(primary)[0] = 0x4d; // 0xX1001101
    VAR(primary)[1] = 0x59; // 0x01011001
    VAR(primary)[2] = 0xb5; // 0x10110101

    //  VAR(primary)[0] = 0x2;  //start frame 0x10
    //  VAR(primary)[1] = 0x6a; //start frame 0x01101010
    //  VAR(primary)[2] = 0xcd; //start frame 0x11001101
    VAR(count) = 0;         // reset the counter
    return 1;
}

char TOS_EVENT(MAC_TX_SYNC_START)(void)  {return 1;}

char TOS_EVENT(MAC_TX_MAC_BIT_EVENT)(char bit)   {
  if (VAR(state) == TX_BACKOFF_STATE) {
    VAR(delay)++;
    if (VAR(delay) >= VAR(waiting)) {
      // Set the radio to listening again at 2x sampling rate
      TOS_CALL_COMMAND(MAC_SUB_PWR_ON)(DOUBLE_SAMPLE);
      VAR(delay) = 0;
      VAR(waiting) = 6; // We listen for 7 samples
      VAR(state) = TX_IDLE_WAITING_STATE;  // Goes back to CSMA listening
    }

  }
  else if (VAR(state) == TX_IDLE_WAITING_STATE) {
    if (bit) {
      //we just read activity, reset the waiting counter.
      VAR(waiting) = 0;
      TOS_CALL_COMMAND(MAC_SUB_PWR_OFF)(SINGLE_SAMPLE);
      // Use 11 bits of randomnesss for the backoff windows
      VAR(waiting) = TOS_CALL_COMMAND(MAC_SUB_NEXT_RAND)() & 0x3ff;
      VAR(state) = TX_BACKOFF_STATE;  // Goes to Backoff/Delay
    }
    else {
      //if we've not heard anything for more than 7 samples then assume channel is clean
      if(VAR(delay)++ > VAR(waiting)){
	VAR(delay) = 0;
	//go to the transmit state.
	TOS_CALL_COMMAND(MAC_SUB_PWR_ON)(SINGLE_SAMPLE);
	TOS_CALL_COMMAND(MAC_SUB_TX_START_ACTIVATE)();
      }
    }
  }
  return 1;
}


char TOS_EVENT(MAC_TX_START_BIT_EVENT)(void) {
  TOS_CALL_COMMAND(MAC_SUB_TX_BIT)(VAR(primary)[2] & 0x01);
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
  else if(VAR(count) >= 23){
    TOS_CALL_COMMAND(MAC_SUB_TX_SYNC_ACTIVATE)();
    TOS_CALL_COMMAND(MAC_SUB_TX_DATA_ACTIVATE)();
  }
  else if (VAR(count) < 0) {
      VAR(power) = 0;
    TOS_CALL_COMMAND(MAC_SUB_RX_IDLE_ACTIVATE)();
  }
  return 1;
}
  
char TOS_EVENT(MAC_TX_SYNC_BIT_EVENT)(void)  {
  //  TOS_CALL_COMMAND(MAC_SUB_TX_DATA_ACTIVATE)();
  //TOS_CALL_COMMAND(MAC_SUB_RX_IDLE_ACTIVATE)();
  return 1;
}

