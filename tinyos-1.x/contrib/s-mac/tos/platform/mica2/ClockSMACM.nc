/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * Date created: 3/21/2003
 *
 * This Clock is internally used by S-MAC. User can specify which hardware
 *   Timer/Counter it is based on by defining the macro SMAC_USE_COUNTER_x.
 *   By default Timer/Counter 0 is used.
 */

// The Mica-specific parts of the hardware presentation layer.

module ClockSMACM
{
   provides {
      interface ClockSMAC as Clock;
      interface TimeStamp;
   }
}

implementation
{

#ifdef SMAC_USE_COUNTER_1

#define SCALE_1ms 1
#define INTERVAL_1ms 7650

   command void Clock.start()
   {
      uint8_t intEnabled, scale = SCALE_1ms;
      uint16_t interval = INTERVAL_1ms;
      scale |= 0x8;
      cbi(TIMSK, OCIE1A);    // Disable output compareA match interrupt
      intEnabled = bit_is_set(SREG, 7);
      cli();      // disable interrupt before accessing 16-bit register
      __outw(0, TCNT1L);  // clear timer counter 1
      __outw(interval, OCR1AL);  // set compare match register
      if (intEnabled) sei();
      outp(scale, TCCR1B);    //prescale timer counter to be clock/8
      sbi(TIMSK, OCIE1A); 
   }

   command void Clock.stop()
   {
      // stop the clock
      outp(0, TCCR1B);
   }
   
   TOSH_INTERRUPT(SIG_OUTPUT_COMPARE1A)
   {
      signal Clock.fire();
   }
   
   command void TimeStamp.getTime32(uint32_t *timePtr)
   {
      uint8_t intEnabled = bit_is_set(SREG, 7);
      cli();      // disable interrupt before accessing 16-bit register
      *timePtr = (uint32_t)__inw(TCNT1L);  // read timer counter 1
      if (intEnabled) sei();
   }
   
#else

#define SCALE_1ms 1
#define INTERVAL_1ms 33

   command void Clock.start()
   {
      uint8_t scale = SCALE_1ms;
      uint8_t interval = INTERVAL_1ms;
      scale |= 0x8;
      cbi(TIMSK, TOIE0);
      cbi(TIMSK, OCIE0);     //Disable TC0 interrupt
      sbi(ASSR, AS0);        //set Timer/Counter0 to be asynchronous
      //from the CPU clock with a second external
      //clock(32,768kHz)driving it.
      outp(scale, TCCR0);    //prescale the timer 
      outp(0, TCNT0);
      outp(interval, OCR0);
      sbi(TIMSK, OCIE0); 
   }

   command void Clock.stop()
   {
      // stop the clock
      outp(0, TCCR0);
   }
   
   TOSH_INTERRUPT(SIG_OUTPUT_COMPARE0) {
      signal Clock.fire();
   }
   
   command void TimeStamp.getTime32(uint32_t *timePtr)
   {
      *timePtr = (uint32_t)inp(TCNT0);
   }

#endif
}
