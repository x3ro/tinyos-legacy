/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * SNOOZE.c - 
 *
 */

#include "tos.h"
#include "SNOOZE.h"

// Component frame
#define TOS_FRAME_TYPE SNOOZE_frame
TOS_FRAME_BEGIN(SNOOZE_frame) {
    char nintrs; 
    unsigned char port[10];
}
TOS_FRAME_END(SNOOZE_frame);

#if 0
#define nops(int i) { while(--i) asm volatile ("nop"::); }
#endif

#define nops(x)

//
// init
//
char TOS_COMMAND(SNOOZE_INIT)()
{
    VAR(nintrs)=0;
    return(1);
}

//
// This comment is really old...
// Sleep timeout/32 seconds for a maximum
// of more than 2000 seconds (or 36 minutes)
//
char TOS_COMMAND(SNOOZE_AWHILE)(unsigned short stagger)
{
    unsigned short timeout;

    //disable interrupts
    cli();

    // save port state
    VAR(port)[0] = inp(PORTA); nops(8);
    VAR(port)[1] = inp(PORTB); nops(8);
    VAR(port)[2] = inp(PORTC); nops(8);
    VAR(port)[3] = inp(PORTD); nops(8);
    VAR(port)[4] = inp(PORTE); nops(8);
    VAR(port)[5] = inp(DDRA);  nops(8);
    VAR(port)[6] = inp(DDRB);  nops(8);
    VAR(port)[7] = inp(DDRD);  nops(8);
    VAR(port)[8] = inp(DDRE);  nops(8);
    VAR(port)[9] = inp(TCCR0); nops(8);

    // Disable TC0 interrupt and set timer/counter0 to be asynchronous from the CPU
    // clock with a second external clock (32,768kHz) driving it.  Prescale to 32 Hz.

    cbi(TIMSK, OCIE0);  nops(8);
    sbi(ASSR, AS0);  	nops(8);
    outp(0x0f, TCCR0);	nops(8);

//    VAR(nintrs) = (timeout >> 8) & 0xff;
//    VAR(nintrs) <<= 1;
//

//    VAR(nintrs) = 1;
//

    timeout = 32 * 4;    //  4 second sleep intervals
    VAR(nintrs) = 16;     // 4 sleep periods (16s total)

//    if(stagger) {
//	VAR(nintrs)++;    // sometimes add another 4 second interval
//    }

    outp(-(timeout & 0xff), TCNT0); nops(8);
    while(inp(ASSR) & 0x07) nops(8);
    sbi(TIMSK, TOIE0); nops(8);

    // set minimum power state
    outp(0x00, DDRA);	// input
    outp(0x00, DDRB);	// input
    outp(0x00, DDRD);	// input
    outp(0x00, DDRE);	// input

    outp(0xff, PORTA);	// pull high
    outp(0xff, PORTB);	// pull high
    outp(0xff, PORTC);	// pull high
    outp(0xff, PORTD);	// pull high

    MAKE_RFM_CTL0_OUTPUT();	// port D pin 7
    CLR_RFM_CTL0_PIN();		// set low
    MAKE_RFM_CTL1_OUTPUT();	// port D pin 6
    CLR_RFM_CTL1_PIN();		// set low
    MAKE_RFM_TXD_OUTPUT();	// port B pin 3
    CLR_RFM_TXD_PIN();		// set low

    MAKE_POT_SELECT_OUTPUT();	// port D pin 5	??
    SET_POT_SELECT_PIN();	// set low	??
    MAKE_POT_POWER_OUTPUT();	// port E pin 7
    CLR_POT_POWER_PIN();	// set low
    MAKE_FLASH_IN_OUTPUT();	// port A pin 5
    CLR_FLASH_IN_PIN();		// set low
    MAKE_FLASH_SELECT_OUTPUT();	// port B pin 0
    SET_FLASH_SELECT_PIN();	// set high

    MAKE_ONE_WIRE_OUTPUT();	// port E pin 5
    SET_ONE_WIRE_PIN();		// set high
    MAKE_BOOST_ENABLE_OUTPUT();	// port E pin 4
    CLR_BOOST_ENABLE_PIN();	// set low

    MAKE_PW7_OUTPUT(); CLR_PW7_PIN();
    MAKE_PW6_OUTPUT(); CLR_PW6_PIN();
    MAKE_PW5_OUTPUT(); CLR_PW5_PIN();
    MAKE_PW4_OUTPUT(); CLR_PW4_PIN();
    MAKE_PW3_OUTPUT(); CLR_PW3_PIN();
    MAKE_PW2_OUTPUT(); CLR_PW2_PIN();
    MAKE_PW1_OUTPUT(); CLR_PW1_PIN();
    MAKE_PW0_OUTPUT(); CLR_PW0_PIN();

    // enable power save mode
    // next scheduler invokation
    sbi(MCUCR, SM1); nops(8);
    sbi(MCUCR, SM0); nops(8);
    sbi(MCUCR, SE);  nops(8);

//  TOS_CALL_COMMAND(GDI_YELLOW_LED_OFF)();
    // enable interrupts
    sei(); nops(8);
    return(1);
}

//
// Clock overflow handler
// 
TOS_SIGNAL_HANDLER(SIG_OVERFLOW0, (void))
{
    if(VAR(nintrs) <= 0) {
	cbi(MCUCR,SM0);  nops(8);
	cbi(MCUCR,SM1);  nops(8);
	outp(VAR(port)[0], PORTA); nops(8);
	outp(VAR(port)[1], PORTB); nops(8);
	outp(VAR(port)[2], PORTC); nops(8);
	outp(VAR(port)[3], PORTD); nops(8);
	outp(VAR(port)[4], PORTE); nops(8);
	outp(VAR(port)[5], DDRA);  nops(8);
	outp(VAR(port)[6], DDRB);  nops(8);
	outp(VAR(port)[7], DDRD);  nops(8);
	outp(VAR(port)[8], DDRE);  nops(8);
	outp(VAR(port)[9], TCCR0); nops(8);
	cbi(TIMSK, TOIE0); nops(8);
	sbi(TIMSK, OCIE0); nops(8);
	outp(0x00, TCNT0); nops(8);
	while(inp(ASSR) & 0x07) { nops(8);};

	MAKE_BOOST_ENABLE_OUTPUT();
	SET_BOOST_ENABLE_PIN();

	TOS_SIGNAL_EVENT(SNOOZE_WAKEUP)();
	return;
    }

    VAR(nintrs)--;
    outp(0x80, TCNT0);  nops(8);
    while(inp(ASSR) & 0x7){ nops(8);}
}
