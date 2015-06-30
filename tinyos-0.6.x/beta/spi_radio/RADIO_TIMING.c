





#include "tos.h"
#include "RADIO_TIMING.h"



int TOS_COMMAND(GET_TIMING)(){
	//enable input capture.
	//	
	cbi(DDRB, 4);
	while(READ_RFM_RXD_PIN()){;}
	outp(0x41, TCCR1B);
	sbi(TIFR, ICF1);
	//wait for the capture.
	while((inp(TIFR) & (0x1 << ICF1)) == 0){;}
	sbi(PORTB, 6);
	cbi(PORTB, 6);
	return __inw_atomic(ICR1L);

}
