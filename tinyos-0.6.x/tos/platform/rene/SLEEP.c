/*									tab:4
 * SLEEP.c
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
 */


#include "tos.h"
#include "SLEEP.h"
// Frame of the component
#define TOS_FRAME_TYPE BCAST_sleep_frame
TOS_FRAME_BEGIN(BCAST_sleep_frame) {
    char nepochs; 
    unsigned char port[9];
}

TOS_FRAME_END(SOLAR_frame);


//The function will sleep for timeout /32 seconds, which corresponds to a
//maximum sleep of over 2000 seconds (36 minutes)

char TOS_COMMAND(SLEEP_INIT)(unsigned short timeout) {
    //    unsigned char da, db, dc, dd;
    //    unsigned char pa, pb, pc, pd;
    int i = 0;
    unsigned char count;
    cli();   //disable interrupts
    // save port state
    VAR(port)[i++] = inp(PORTA);
    VAR(port)[i++] = inp(PORTB);
    VAR(port)[i++] = inp(PORTC);
    VAR(port)[i++] = inp(PORTD);
    VAR(port)[i++] = inp(DDRA);
    VAR(port)[i++] = inp(DDRB);
    VAR(port)[i++] = inp(DDRC);
    VAR(port)[i++] = inp(DDRD);
    VAR(port)[i++] = inp(TCCR2);
    
    // Save all the pins
/*     pa = in(PORTA); */
/*     pb = in(PORTB); */
/*     pc = in(PORTC); */
/*     pd = in(PORTD); */
/*     da = in(DDRA); */
/*     db = in(DDRB); */
/*     dc = in(DDRC); */
/*     dd = in(DDRD); */
/*     scale = in(TCCR2); */
    
    /* for the rene: set pins for minimal power consumption */
    outp(0x00, DDRA);
    outp(0x07, DDRB); //Set rfm txmod/ctrl1/ctrl2 bits to output
    outp(0x00, DDRC);
    outp(0x00, DDRD);
    outp(0xff, PORTA);
    outp(0xf8, PORTB); //Set rfm txmod/ctrl1/ctrl2 bits to 0
    outp(0xff, PORTC);
    outp(0xff, PORTD);
    
    cbi(TIMSK, OCIE2);     //Disable TC0 interrupt
    sbi(ASSR, AS2);        //set Timer/Counter0 to be asynchronous
                           //from the CPU clock with a second external
                           //clock(32,768kHz)driving it.
    outp(0x0f, TCCR2);    // prescale the timer to 32 Hz 
    VAR(nepochs) = (timeout >> 8) & 0xff;
    VAR(nepochs) <<= 1;
    count = -(timeout & 0xff);
    outp(count, TCNT2); // 
    
    sbi(TIMSK, TOIE2);
    while (inp(ASSR) & 0x07) {};

    //    loop_until_bit_is_clear(ASSR, TCNT2UB);
    //     loop_until_bit_is_clear(ASSR, TCCR2UB);
    sbi(MCUCR, SM1); //enable power save mode
    sbi(MCUCR, SM0);
    sbi(MCUCR, SE); 
    sei();
    return 1;
}
 
TOS_SIGNAL_HANDLER(SIG_OVERFLOW2, (void)) {
    char i = 0;
    if (VAR(nepochs) <= 0) {
	cbi(MCUCR,SM0);
	cbi(MCUCR,SM1);
	outp(VAR(port)[i++], PORTA);
	outp(VAR(port)[i++], PORTB);
	outp(VAR(port)[i++], PORTC);
	outp(VAR(port)[i++], PORTD);
	outp(VAR(port)[i++], DDRA);
	outp(VAR(port)[i++], DDRB);
	outp(VAR(port)[i++], DDRC);
	outp(VAR(port)[i++], DDRD);
	outp(VAR(port)[i++], TCCR2);
	cbi(TIMSK, TOIE2);
	sbi(TIMSK, OCIE2);
	outp(0x00, TCNT2);
	while (inp(ASSR) & 0x07) {};
/* 	loop_until_bit_is_clear(ASSR, TCNT2UB); */
/* 	loop_until_bit_is_clear(ASSR, TCCR2UB); */
	TOS_SIGNAL_EVENT(SLEEP_WAKEUP)();
    } else {

	VAR(nepochs)--;
        outp(0x80, TCNT2);
	if ((inp(ASSR) & 0x7) == 0) {
	MAKE_RED_LED_OUTPUT();
	    while (1) 
		TOS_CALL_COMMAND(RED_LED_OFF)();
	}
        while(inp(ASSR) & 0x7){}
    }
}
	
/*     outp(da, DDRA); */
/*     outp(db, DDRB); */
/*     outp(dc, DDRC); */
/*     outp(dd, DDRD); */
/*     outp(pa, PORTA); */
/*     outp(pb, PORTB); */
/*     outp(pc, PORTC); */
/*     outp(pd, PORTD);  */
/*     outp(scale, TCCR2); */

