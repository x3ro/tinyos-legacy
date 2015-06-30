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

module ClockSCPM
{
  provides {
    interface ClockSCP as Clock;
  }
}

implementation
{
#define SCALE_1ms 1
#define INTERVAL_1ms 7650
#define INTERVAL_128us 1000

  command void Clock.start()
  {
    uint8_t intEnabled, scale = SCALE_1ms;
    uint16_t interval = INTERVAL_128us;
    scale |= 0x8;
    cbi(ETIMSK, OCIE3A);    // Disable output compareA match interrupt
    intEnabled = bit_is_set(SREG, 7);
    cli();      // disable interrupt before accessing 16-bit register
    __outw(0, TCNT3L);  // clear timer counter 1
    __outw(interval, OCR3AL);  // set compare match register
    if (intEnabled) sei();
    outp(scale, TCCR3B);    //prescale timer counter to be clock/8
    sbi(ETIMSK, OCIE3A); 
  }

  command void Clock.stop()
  {
    // stop the clock
    outp(0, TCCR3B);
  }
   
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE3A)
    {
      signal Clock.fire();
    }
}
