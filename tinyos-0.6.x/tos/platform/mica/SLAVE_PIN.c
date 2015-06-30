



#include "tos.h"
#include "SLAVE_PIN.h"
#include "dbg.h"

#define TOS_FRAME_TYPE SLAVE_PIN_frame
TOS_FRAME_BEGIN(SLAVE_PIN_frame) {
        char n;
#ifdef DOT
	char precision;
#endif
}
TOS_FRAME_END(SLAVE_PIN_frame);

char TOS_COMMAND(SLAVE_PIN_INIT)() {
    VAR(n) = 1;
    MAKE_ONE_WIRE_OUTPUT();
    SET_ONE_WIRE_PIN();
    return 0;
} 

char TOS_COMMAND(SLAVE_PIN_LOW)() {
    char prev = inp(SREG) & 0x80;
    cli();
    VAR(n)--;
    MAKE_ONE_WIRE_OUTPUT();
    CLR_ONE_WIRE_PIN();
    if(prev) sei();
    return 0;
}

char TOS_COMMAND(SLAVE_PIN_HIGH)() {
    char prev = inp(SREG) & 0x80;
    cli();
    VAR(n)++;
    if (VAR(n) > 0) {
	MAKE_ONE_WIRE_OUTPUT();
	SET_ONE_WIRE_PIN();
	TOS_SIGNAL_EVENT(SLAVE_PIN_NOTIFY)(); // this should be done from a
					      // task, but I'm breaking the
					      // convention for the sake of
					      // speed. 
    }
    if(prev) sei();
    return 0;
}
