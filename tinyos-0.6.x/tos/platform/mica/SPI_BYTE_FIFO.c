/*									tab:4
 * "Copyright (c) 2002 and The Regents of the University 
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
 */
#include "tos.h"
#include "dbg.h"
#include "SPI_BYTE_FIFO.h"


/* Frame of the component */

char spi_local_next_byte;
#define TOS_FRAME_TYPE bitread_frame
TOS_FRAME_BEGIN(radio_frame) {
	char state;
}
TOS_FRAME_END(radio_frame);

#define IDLE 0
#define FULL 1
#define OPEN 2
#define SPI_BYTE_READY 3
#define READING 3
extern char dest;


#define BIT_RATE 20 * 4 / 2 * 5/4

TOS_SIGNAL_HANDLER(SIG_SPI, ()){
	char temp = inp(SPDR);
	outp(spi_local_next_byte, SPDR);
	VAR(state) = OPEN;
	TOS_SIGNAL_EVENT(SPI_DATA_SEND_READY)(temp);
}

char TOS_EVENT(SPI_SLAVE_NOTIFY)() {
    return 0;// we don't care
}

char TOS_COMMAND(SPI_SEND_DATA)(char data){
	if(VAR(state) == OPEN){
		spi_local_next_byte = data;	
		VAR(state) = FULL;
		return 1;
	}if(VAR(state) == IDLE){
		VAR(state) = OPEN;
		TOS_SIGNAL_EVENT(SPI_DATA_SEND_READY)(0);
		//		MAKE_ONE_WIRE_OUTPUT();
		//		CLR_ONE_WIRE_PIN();
		TOS_CALL_COMMAND(SPI_SLAVE_PIN_LOW)();
		cbi(PORTB, 7);
		cbi(PORTB, 0);
		sbi(DDRB, 7);
		outp(0xc0, SPCR);
		outp(data, SPDR);
		//set the radio to TX.
		CLR_RFM_CTL0_PIN();
		SET_RFM_CTL1_PIN();
		//start the timer.
		cbi(TIMSK, TOIE2);
		cbi(TIMSK, OCIE2);
		outp(0, TCNT2);
		outp(BIT_RATE, OCR2);
		outp(0x19, TCCR2);
		return 1;
	}
	return 0;
}

char TOS_COMMAND(SPI_IDLE)(){
	outp(0x00, SPCR);
	outp(0x00, TCCR2);
	TOS_CALL_COMMAND(SPI_SLAVE_PIN_HIGH)();
	MAKE_RFM_TXD_OUTPUT();
	CLR_RFM_TXD_PIN();
	CLR_RFM_CTL0_PIN();
	CLR_RFM_CTL1_PIN();
	VAR(state) = IDLE;
	spi_local_next_byte = 0;
	return 1;
}

char TOS_COMMAND(SPI_START_READ_BYTES)(short timing){
	if(VAR(state) == IDLE){
		VAR(state) = READING;
		dest = 0;
		//		MAKE_ONE_WIRE_OUTPUT();
		//		CLR_ONE_WIRE_PIN();
		TOS_CALL_COMMAND(SPI_SLAVE_PIN_LOW)();
		outp(0x00, SPCR);
		cbi(PORTB, 7);
		sbi(DDRB, 7);
		outp(0x0, TCCR2);
		outp(0x1, TCNT2);
		outp(BIT_RATE, OCR2);
		//don't change the radio state.
		timing += (400-19);
		if(timing > 0xfff0) timing = 0xfff0;
		//set the phase of the clock line
		outp(0x19, TCCR2);
		outp(BIT_RATE - 20, TCNT2);
		while(inp(PINB) & 0x80){;}
		while(__inw(TCNT1L) < timing){outp(0x0,TCNT2);}
		outp(0xc0, SPCR);
		outp(0x00, SPDR);
		sbi(PORTB, 6);
		cbi(PORTB, 6);
		return 1;
	}
	return 0;
}

