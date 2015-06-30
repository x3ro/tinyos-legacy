/*									tab:4
 *
 * Completely rewritten 4b/6b byte component with simple CSMA MAC
 *
 * Major features:
 * 1. Add a preamble (x111x000x111 at 2X rate) for early noise rejection
 * 2. Carrier sense is combined at idle state -- don't miss packets arrived 
 *    during carrier sense.
 * 3. Use 2 groups of samples to match the start symbol -- don't miss start 
 *    symbol even if one group of samples falling on edges.
 * 4. Align sampling positions by 2 groups of samples -- close to center of
 *    of each pulses.
 *
 * encodeNibble() and decodeNibbles() are adopted from UC Berkeley's code
 *
 * Authors:	Wei Ye (USC/ISI)
 *
 *
 */


#include "tos.h"
#include "FOUR_B_RADIO_BYTE.h"
//#define FULLPC_DEBUG

#define PREAMBLE 0xcd	// 11001101 for noise rejection
#define STARTSYM1 0x6a	// 01101010 for sampling alignment
#define STARTSYM2 0x2	// 10

/* list of states:
 *
 * SLEEP -- low power mode
 * IDLE_CS -- idle and carrier sense. Searching for preamble x111x000x111
 * TX_START_SYMBOL -- sending preamble and start symbol
 * TX_DATA -- sending packet data
 * MATCH_START_SYMBOL -- matching start symbol 101011001
 * ADJUST_SAMPLE_POS -- adjust sampling positions 
 * READ_FIRST_BIT -- matched start symbol, waiting for first bit
 * CLOCK_BITS -- clocking in bits
 *
 */

#define SLEEP 0
#define IDLE_CS 1
#define TX_START_SYMBOL 2
#define TX_DATA 3
#define MATCH_START_SYMBOL 4
#define ADJUST_SAMPLE_POS 5
#define READ_FIRST_BIT 6
#define CLOCK_BITS 7

extern short TOS_LOCAL_ADDRESS;

//table for performing the encoding.
static const char bldTbl[16] =
{0x15,
 0x31,
 0x32,
 0x23,
 0x34,
 0x25,
 0x26,
 0x07,
 0x38,
 0x29,
 0x2A,
 0x0B,
 0x2C,
 0x0D,
 0x0E,
 0x1C};


#define TOS_FRAME_TYPE bitread_frame
TOS_FRAME_BEGIN(radio_frame) {
	char byteBuf;
	char TxRxBuf0;
	char TxRxBuf1;
	char codecBuf0;
	char codecBuf1;
	char state;
	char count;
	char last_bit;
	char TxRequest;
	char encodeReady;
	unsigned int shift_reg;	// random number generation
	unsigned char csBits;  // number of bits to be read for carrier sense
}
TOS_FRAME_END(radio_frame);

                          
TOS_TASK(radio_encode_thread)
{
	//encode byte and store it into buffer.
	VAR(codecBuf0) = encodeNibble(VAR(byteBuf) & 0xf);
	VAR(codecBuf1) = encodeNibble((VAR(byteBuf) >> 4) & 0xf);
	VAR(encodeReady) = 1;
	    
#ifdef FULLPC_DEBUG
	printf("encoding byte done: %x, %x\n", VAR(codecBuf1), VAR(codecBuf0));
#endif
}

TOS_TASK(radio_decode_thread)
{
    //decode received byte, and signal upper layer
#ifdef FULLPC_DEBUG
	printf("decoding byte: %x, %x\n", VAR(codecBuf1), VAR(codecBuf0));
#endif
	if (!(TOS_SIGNAL_EVENT(RADIO_BYTE_RX_BYTE_READY)(decodeNibbles(
		VAR(codecBuf1), VAR(codecBuf0)), 0))){
		// stop receiving when upper layer returns false (got all bytes)
		// go to search for preamble at 2x sampling rate.
		VAR(state) = IDLE_CS;
		VAR(csBits) = 0;
		VAR(TxRxBuf0) = 0;
		TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
	}
}		


char TOS_COMMAND(RADIO_BYTE_INIT)(){
	VAR(state) = IDLE_CS;
	VAR(TxRxBuf0) = 0;
	VAR(TxRequest) = 0;
	VAR(csBits) = 0;
	VAR(shift_reg) = 119 * TOS_LOCAL_ADDRESS;
	TOS_CALL_COMMAND(RADIO_SUB_INIT)();
#ifdef FULL_PC	
	printf("Radio Byte handler initialized.\n");
#endif
	return 1;
}


char TOS_COMMAND(RADIO_BYTE_TX_BYTES)(char data){
	char bit;
    if(VAR(state) == IDLE_CS && VAR(TxRequest) == 0){ // accept new Tx
		VAR(byteBuf) = data;
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
	}else if(VAR(state) == TX_DATA && VAR(encodeReady) == 0){
		// in the middle of a transmission and encode buffer is empty
		VAR(byteBuf) = data;
		TOS_POST_TASK(radio_encode_thread); //schedule encode task
		return 1;
	}
    return 0;
}


char TOS_COMMAND(RADIO_BYTE_PWR)(char mode){
	if(mode == 0){  // sleep
		TOS_CALL_COMMAND(RADIO_SUB_PWR)(0); // power down lower components
		VAR(state) = SLEEP;
	}else{  // active
		TOS_CALL_COMMAND(RADIO_SUB_RX_MODE)();
		TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
		VAR(state) = IDLE_CS;
		VAR(csBits) = 0;
		VAR(TxRxBuf0) = 0; 
	}
	return 1;
}


char TOS_EVENT(RADIO_BYTE_TX_BIT_EVENT)(){
	// trasmit each bit in the TxRxBuf
	if (VAR(state) == TX_START_SYMBOL && VAR(encodeReady) == 0) return 0;
    	TOS_CALL_COMMAND(RADIO_SUB_TX_BIT)(VAR(TxRxBuf0) & 0x1);
		VAR(count)++;
		VAR(TxRxBuf0) >>= 1;
	if (VAR(state) == TX_START_SYMBOL) {
		if (VAR(count) == 8) {  // preamble is done
			VAR(TxRxBuf0) = STARTSYM1;
		} else if (VAR(count) == 16) {
			VAR(TxRxBuf0) = STARTSYM2;
		} else if (VAR(count) == 18) {  // start symbol is done
			VAR(state) = TX_DATA;
			VAR(count) = 0;
			VAR(TxRxBuf0) = VAR(codecBuf0);
			VAR(TxRxBuf1) = VAR(codecBuf1);
			VAR(encodeReady) = 0;
			TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(1); // ask for 1 more byte
		}
	} else if (VAR(state) == TX_DATA) {
		if (VAR(count) == 6) {  // first part is done
			VAR(TxRxBuf0) = VAR(TxRxBuf1);
		} else if (VAR(count) == 12) {  // entire byte is done
			VAR(count) = 0;
			if (VAR(encodeReady) == 1) {  // has more data buffered
				VAR(TxRxBuf0) = VAR(codecBuf0);
				VAR(TxRxBuf1) = VAR(codecBuf1);
				VAR(encodeReady) = 0;
				TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(1);
			} else {  // no more data, go back to idle
				VAR(state) = IDLE_CS;
				VAR(csBits) = 0;
				VAR(TxRxBuf0) = 0;
				TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(1);
				TOS_SIGNAL_EVENT(RADIO_BYTE_TX_DONE)();
				TOS_CALL_COMMAND(RADIO_SUB_RX_MODE)();
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(0);
			}
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
		VAR(TxRxBuf1) = (VAR(TxRxBuf1) << 1) & 0x6;
		if ((VAR(TxRxBuf0) & 0x80) == 0x80) VAR(TxRxBuf1) |= 0x1;
		VAR(TxRxBuf0) = (VAR(TxRxBuf0) << 1) & 0xfe;
		VAR(TxRxBuf0) = VAR(TxRxBuf0) | (data & 0x1);
		if(VAR(TxRxBuf1) == 0x7 && (VAR(TxRxBuf0) & 0x77) == 0x7) {
			// found preamble
			VAR(csBits) = 24;   // read just 24 bits for start symbol
			VAR(last_bit) = 1;	// first group of samples
			VAR(TxRxBuf0) = 0;
			VAR(codecBuf0) = 0;
			VAR(state) = MATCH_START_SYMBOL;	// detecting start symbol
		} else if (VAR(csBits) > 0) {  // Tx pending
			VAR(csBits)--; // decrement carrier sense counter
			if (VAR(csBits) == 0) {
				// carrier sense succeeded, Tx immediately
				VAR(state) = TX_START_SYMBOL;
				VAR(TxRxBuf0) = PREAMBLE;
				VAR(count) = 0;
				VAR(encodeReady) = 0;
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
				VAR(state) = TX_START_SYMBOL;
				TOS_CALL_COMMAND(RADIO_SUB_TX_MODE)();
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);
				TOS_POST_TASK(radio_encode_thread);
			} else {  // no Tx request
				VAR(state) = IDLE_CS;  // go back to idle
				VAR(TxRxBuf0) = 0;
			}
			return 1;
		}
        // put new data into two groups to match start symbol
		if (VAR(last_bit)) {  // just put into second group, now for first
			VAR(last_bit) = 0;
#endif
			// Fullpc mode only has 1 group of samples (no 2x sampling)
			VAR(TxRxBuf0) >>= 1;
			VAR(TxRxBuf0) &= 0x7f;  // clear the highest bit
			// if lowest bit of higher byte is one, store it in second
			if(VAR(TxRxBuf1) & 0x1) VAR(TxRxBuf0) |= 0x80;
			VAR(TxRxBuf1) = data & 0x1;  // start symbol is 9 bits
			if (VAR(TxRxBuf1) == 0x1 && VAR(TxRxBuf0) == 0x35 ) {
				// 1st group matches, read one more bit for 2nd group
#ifndef FULLPC
				VAR(state) = ADJUST_SAMPLE_POS;
				VAR(codecBuf0) >>= 1;
				VAR(codecBuf0) &= 0x7f; 
				if (VAR(codecBuf1) & 0x1) VAR(codecBuf0) |= 0x80;
#else
				VAR(state) = READ_FIRST_BIT;  // directly start receiving data if FULLPC
#endif
			}
#ifndef FULLPC
		} else {  // just put into first group, now for second
			VAR(last_bit) = 1;
			VAR(codecBuf0) >>= 1;
			VAR(codecBuf0) &= 0x7f;  // clear the highest bit
			//if lowest bit of first is one, store it in second
			if(VAR(codecBuf1) & 0x1) VAR(codecBuf0) |= 0x80;
			VAR(codecBuf1) = data & 0x1;  // start symbol is 9 bits
			if (VAR(codecBuf1) == 0x1 && VAR(codecBuf0) == 0x35){
				// 2nd group matches, read one more bit for 1st group
				VAR(state) = ADJUST_SAMPLE_POS;
				VAR(TxRxBuf0) >>= 1;
				VAR(TxRxBuf0) &= 0x7f;
				if(VAR(TxRxBuf1) & 0x1) VAR(TxRxBuf0) |= 0x80;
			}
		}
	} else if (VAR(state) == ADJUST_SAMPLE_POS) {
		// start symbol already detected
		// use this additional bit for better sampling alignment
		if (VAR(last_bit)) {
			if ((data & 0x1) && VAR(TxRxBuf0) == (char)0x35 )
				// both groups match start symbol
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(1); // 1.5x bit rate
		} else {
			if ((data & 0x1) && VAR(codecBuf0) == (char)0x35)
				// both groups match start symbol
				TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(1); // 1.5x bit rate
		}
		VAR(state) = READ_FIRST_BIT;  // waiting for first bit
#endif
	
	} else if(VAR(state) == READ_FIRST_BIT){
		TOS_CALL_COMMAND(RADIO_SUB_SET_BIT_RATE)(2);  // 1X sampling rate
		VAR(state) = CLOCK_BITS;
		VAR(count) = 1;
		if(data) {
	    	VAR(TxRxBuf0) = 0x20;
		} else {
			VAR(TxRxBuf0) = 0;
		}
		// if Tx request pending, now have time to signal failure of Tx,
		// so that upper layer will go to idle first, and then can receive
		if (VAR(TxRequest)) {
			VAR(TxRequest) = 0;
			TOS_SIGNAL_EVENT(RADIO_BYTE_TX_BYTE_READY)(0);
		}
    }else if(VAR(state) == CLOCK_BITS){
		VAR(count)++;
		VAR(TxRxBuf0) >>= 1;
		VAR(TxRxBuf0) &= 0x1f;
		if (data) {
		    VAR(TxRxBuf0) |= 0x20;
		}
		if (VAR(count) == 6) {
		    VAR(codecBuf0) = VAR(TxRxBuf0);
		} else if (VAR(count) == 12){
			VAR(codecBuf1) = VAR(TxRxBuf0);
			VAR(count) = 0;
			//scheduled the decode task.
			TOS_POST_TASK(radio_decode_thread);
		}
	}	
    return 1;
}



char encodeNibble(char in){
    //use table to encode data.
    return bldTbl[(int)in];

}

char decodeNibbles(char first, char second){
    //generic function for decoding data.
    char out;
    if (first == 0x15) first = 0;
    else if(first == 0x1c) first = 0xf;
    if (second == 0x15) second = 0;
    else if(second == 0x1c) second = 0xf;
    out = first << 4;
    out |= second & 0xf;
    return out;
}
