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
    unsigned char port[9];
}
TOS_FRAME_END(SNOOZE_frame);

//
// init
//
char TOS_COMMAND(SNOOZE_INIT)()
{
    VAR(nintrs)=0;
    return(1);
}

//
// Sleep timeout/32 seconds for a maximum
// of more than 2000 seconds (or 36 minutes)
//
char TOS_COMMAND(SNOOZE_AWHILE)(unsigned short timeout)
{
    int tog = 0;

    //disable interrupts
    cli();

    // save port state
    VAR(port)[0] = inp(PORTA);
    VAR(port)[1] = inp(PORTB);
    VAR(port)[2] = inp(PORTC);
    VAR(port)[3] = inp(PORTD);
    VAR(port)[4] = inp(DDRA);
    VAR(port)[5] = inp(DDRB);
    VAR(port)[6] = inp(DDRD);
    VAR(port)[7] = inp(DDRE);
    VAR(port)[8] = inp(TCCR0);

    // Disable TC0 interrupt and set timer/counter0 to be asynchronous from the CPU
    // clock with a second external clock (32,768kHz) driving it.  Prescale to 32 Hz.
    cbi(TIMSK, OCIE0);
    sbi(ASSR, AS0); 
    outp(0x0f, TCCR0);

    VAR(nintrs) = (timeout >> 8) & 0xff;
    VAR(nintrs) <<= 1;

    outp(-(timeout & 0xff), TCNT0);

    sbi(TIMSK, TOIE0);
    while(inp(ASSR) & 0x07);

    // set minimum power state
    outp(0x00, DDRA);	// input
    outp(0x00, DDRB);	// input
    outp(0x00, DDRD);	// input
    outp(0x00, DDRE);	// input

    outp(0xff, PORTA);	// pull high
    outp(0xff, PORTB);	// pull high
    outp(0xff, PORTC);	// pull high
    outp(0xff, PORTD);	// pull high

    MAKE_RED_LED_OUTPUT();
    MAKE_GREEN_LED_OUTPUT();
    MAKE_YELLOW_LED_OUTPUT();

    MAKE_RFM_CTL0_OUTPUT();
    MAKE_RFM_CTL1_OUTPUT();
    CLR_RFM_CTL0_PIN();
    CLR_RFM_CTL1_PIN();

    MAKE_POT_SELECT_OUTPUT();
    CLR_POT_SELECT_PIN();
    MAKE_POT_POWER_OUTPUT();
    CLR_POT_POWER_PIN();

    MAKE_RFM_TXD_OUTPUT();
    CLR_RFM_TXD_PIN();

    MAKE_ONE_WIRE_OUTPUT();
    SET_ONE_WIRE_PIN();
    MAKE_FLASH_SELECT_OUTPUT();
    SET_FLASH_SELECT_PIN();

    MAKE_FLASH_IN_OUTPUT();
    CLR_FLASH_IN_PIN();

    MAKE_BOOST_ENABLE_OUTPUT();
    CLR_BOOST_ENABLE_PIN();

    // enable power save mode
    // next scheduler invokation
    sbi(MCUCR, SM1);
    sbi(MCUCR, SM0);
    sbi(MCUCR, SE); 

//    while(1) {
//	cli();
//	if(tog == 0) {
//	    CLR_BOOST_ENABLE_PIN();
//	} else {
//	    SET_BOOST_ENABLE_PIN();
//	}
//	tog = 1 - tog;
//
//	sbi(MCUCR, SM1);
//	cbi(MCUCR, SM0);
//	sbi(MCUCR, SE); 
//
//	asm volatile ("sleep" ::);
//	asm volatile ("nop" ::);
//	asm volatile ("nop" ::);
//    }

    // enable interrupts
    sei();
    return(1);
}

//
// Clock overflow handler
// 
TOS_SIGNAL_HANDLER(SIG_OVERFLOW0, (void))
{
    if(VAR(nintrs) <= 0) {
	cbi(MCUCR,SM0);
	cbi(MCUCR,SM1);
	outp(VAR(port)[0], PORTA);
	outp(VAR(port)[1], PORTB);
	outp(VAR(port)[2], PORTC);
	outp(VAR(port)[3], PORTD);
	outp(VAR(port)[4], DDRA);
	outp(VAR(port)[5], DDRB);
	outp(VAR(port)[6], DDRD);
	outp(VAR(port)[7], DDRE);
	outp(VAR(port)[8], TCCR0);
	cbi(TIMSK, TOIE0);
	sbi(TIMSK, OCIE0);
	outp(0x00, TCNT0);
	while(inp(ASSR) & 0x07) {};

	MAKE_BOOST_ENABLE_OUTPUT();
	SET_BOOST_ENABLE_PIN();

	TOS_SIGNAL_EVENT(SNOOZE_WAKEUP)();
	return;
    }

    VAR(nintrs)--;
    outp(0x80, TCNT0);
    while(inp(ASSR) & 0x7){}
}
