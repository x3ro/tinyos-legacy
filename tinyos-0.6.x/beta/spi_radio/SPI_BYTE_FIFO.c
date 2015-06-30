#include "SPI_BYTE_FIFO.h"
#include "tos.h"
#include "dbg.h"


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

char TOS_COMMAND(SPI_SEND_DATA)(char data){
	if(VAR(state) == OPEN){
		spi_local_next_byte = data;	
		VAR(state) = FULL;
		return 1;
	}if(VAR(state) == IDLE){
		VAR(state) = OPEN;
		TOS_SIGNAL_EVENT(SPI_DATA_SEND_READY)(0);
		MAKE_ONE_WIRE_OUTPUT();
		CLR_ONE_WIRE_PIN();
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
	outp(0x00, SPDR);
	outp(0x00, TCCR2);
	VAR(state) = IDLE;
	return 1;
}

char TOS_COMMAND(SPI_START_READ_BYTES)(int timing){
	if(VAR(state) == IDLE){
		VAR(state) = READING;
		dest = 0;
		MAKE_ONE_WIRE_OUTPUT();
		CLR_ONE_WIRE_PIN();
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

