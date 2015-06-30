
#include "io.h"

int main() {
	outp(0x0, DDRB);
	outp(0x1e, PORTB);
	outp(0x22, MCUCR); 
	outp(0x00, GIMSK);
	while(1) {
	asm volatile("sleep");
	asm volatile("nop");
	asm volatile("nop");
	}
}


