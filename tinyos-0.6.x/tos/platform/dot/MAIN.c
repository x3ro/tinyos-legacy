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
#include "MAIN.h"
#include "dbg.h"

/* grody stuff to set mote address into code image */

short TOS_LOCAL_ADDRESS = 1;
unsigned char LOCAL_GROUP = DEFAULT_LOCAL_GROUP;

/**************************************************************
 *  Generic main routine.  Issues an init command to subordinate
 *  modules and then a start command.  These propagate down the
 *  tree as required.  The application component sits below main
 *  and above various levels of hardware support components
 *************************************************************/


/* DOT uses a different oscillator which seems to have higher variability than 
   the clock on RENE. To compensate, we calibrate the that clock to the 32kHz
   oscillator which is very accurate (though temperature dependent). Since
   applications for Rene seems to be limited by code size it makes sense to
   not include this code for Rene applications. RS. */
int bit_timer;
char value1;
char increment;
int value;
void set_bit_timer(){
    //start 32768 timer.
    //start the 4mhz timer.
    int i;
    //  int value;
    int reading = 1;
    cli();
    outp(0, TIMSK);
    sbi(ASSR, AS2);
    outp(0, OCR2);
    outp(1, TCCR2);
    outp(0x03, TCCR1B); // scale the counter
    outp(0x00, TCCR1A);
    outp(0, TCNT2);
    while(reading != 0) reading = inp(TCNT2) & 0xff;
    while(reading < 1) reading = inp(TCNT2) & 0xff;
    outp(0x00, TCNT1H); // clear current counter value
    outp(0x00, TCNT1L); // clear current couter high byte value
    //let the timer roll over the correct number of times
    for(i = 0; i < 13; i ++){
	reading = 0;
	while(reading < 100) reading  = inp(TCNT2) & 0xff;
	while(reading > 10) reading = inp(TCNT2) & 0xff;
    }
    reading = 0;
    while(reading < 28) reading = inp(TCNT2) & 0xff;
    value = inp(TCNT1L) & 0x00ff;
    value |= inp(TCNT1H) << 8;
    bit_timer = (value >> 4) & 0x1ff; 
    //  if((value >> 3) & 0x1) bit_timer ++;
    outp(0, TIMSK);
    cbi(ASSR, AS2);
    outp(0, OCR2);
    outp(0, TCCR2);
    outp(0x00, TCCR1B); // scale the counter
    outp(0x00, TCCR1A);
    outp(0, TCNT2);
    outp(0x00, TCNT1H); // clear current counter value
    outp(0x00, TCNT1L); // clear current couter high byte value
    if(bit_timer < 0x188) bit_timer = 0x190;
    if(bit_timer > 0x196) bit_timer = 0x193;
    value1 = value & 0x0f;
    increment = value1;
    //bit_timer = 0x193;
    //let the timer roll over the correct number of times
}

int main() {    
    /* reset the ports, and set the directions */
    SET_PIN_DIRECTIONS();
    set_bit_timer();
    set_bit_timer();
    TOS_CALL_COMMAND(MAIN_SUB_POT_INIT)(52);
    TOS_sched_init();
    TOS_CALL_COMMAND(MAIN_SUB_INIT)();
    TOS_CALL_COMMAND(MAIN_SUB_START)();
    while(1){
	while(!TOS_schedule_task()) { };
	sbi(MCUCR, SE);
	asm volatile ("sleep" ::);
        asm volatile ("nop" ::);
        asm volatile ("nop" ::);
    }
}
	

char TOS_EVENT(MAIN_SUB_SEND_DONE)(TOS_MsgPtr msg){return 1;}
char TOS_EVENT(MAIN_SUB_APPEND_DONE)(char success){return 1;}
char TOS_EVENT(MAIN_SUB_READ_DONE)(char* data, char success){return 1;}





