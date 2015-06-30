/*									tab:4
 *
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
 * Authors:		Jason Hill
 *
 *
 */

#include "tos.h"
#include "CLOCK.h"
#include "dbg.h"

#ifndef FULLPC
#include "progmem.h"

#else
#define PROGMEM
#define __lpm_inline(x) *((char *)(x))

#endif

#define TINY
#ifndef TINY
unsigned char shifts[] PROGMEM = {8, 8, 7, 5, 4, 3, 2, 0};
unsigned char increment[] PROGMEM = {0, 0, 1, 7, 15, 31, 63, 255};


#define TOS_FRAME_TYPE CLOCK_frame
TOS_FRAME_BEGIN(CLOCK_frame) {
        int cnt;
	int time;
}
TOS_FRAME_END(CLOCK_frame);
#endif


char TOS_COMMAND(CLOCK_INIT)(char interval, char scale){

    dbg(DBG_BOOT, ("Clock initialized\n"));
    scale &= 0x7;
    scale |= 0x8;
    cbi(TIMSK, TOIE2);
    cbi(TIMSK, OCIE2);     //Disable TC0 interrupt
    sbi(ASSR, AS2);        //set Timer/Counter0 to be asynchronous
                           //from the CPU clock with a second external
                           //clock(32,768kHz)driving it.
    outp(scale, TCCR2);    //prescale the timer to be clock/128 to make it
    outp(0, TCNT2);
    outp(interval, OCR2);
    sbi(TIMSK, OCIE2); 
    sei();

    return 1;
}


TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE2, (void)) {
#ifndef TINY
    char scale;
    int advance;
    VAR(cnt) += inp(OCR2);
    if (VAR(cnt) > 255) {
	VAR(cnt) -= 256;
	scale = inp(TCCR2) & 0x07;
	advance = (int) __lpm_inline(increment+scale);
	VAR(time) += advance+1;
    }
#endif
    TOS_SIGNAL_EVENT(CLOCK_FIRE_EVENT)();
}

char TOS_COMMAND(CLOCK_GET_TIME)(short *clock) {
#ifndef TINY
    char scale;
    scale = inp(TCCR2) & 0x07;
    scale = __lpm_inline(shifts+scale);
    *clock = VAR(time)+ (int) (((inp(TCNT2)+VAR(cnt)) >> scale));
#endif
    return 0;
}

char TOS_COMMAND(CLOCK_SET_TIME) (short clock) {
#ifndef TINY
    char scale;
    scale = inp(TCCR2) & 0x07;
    scale - __lpm_inline(shifts+scale);
    VAR(cnt) = 0;
    VAR(time) = clock - (inp(TCNT2) >> scale);
#endif
    return 0;
}
