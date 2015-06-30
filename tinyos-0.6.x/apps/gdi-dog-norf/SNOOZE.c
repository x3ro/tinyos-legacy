/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * SNOOZE.c - 
 *
 */

#include "tos.h"
#include "SNOOZE.h"

//
// Watchdog
//
void TOS_COMMAND(SNOOZE_AWHILE)(char prescale)
{
    //disable interrupts
    cli();

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

    //Set watchdog timeout to specified period
    // prescalers:
    // #define period16 0x00 // 47ms
    // #define period32 0x01 // 94ms
    // #define period64 0x02 // 0.19s
    // #define period128 0x03 // 0.38s
    // #define period256 0x04 // 0.75s
    // #define period512 0x05 // 1.5s
    // #define period1024 0x06 // 3.0s
    // #define period2048 0x07 // 6.0s
    wdt_enable(0x7);

    // power down
    sbi(MCUCR, SM1);
    cbi(MCUCR, SM0);
    sbi(MCUCR, SE); 
    asm volatile ("sleep" ::);
    asm volatile ("nop" ::);
    asm volatile ("nop" ::);
}
