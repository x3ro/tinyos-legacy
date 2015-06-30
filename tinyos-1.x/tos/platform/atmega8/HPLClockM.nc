/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:		Sarah Bergbreiter
 * Date last modified:  3/20/2003
 *
 * This is the hardware clock interface for the motor board.  Scale is
 * listed as follows:
 * Clock scale:
 * 0 - off
 * 1 - 2000000 ticks/second  -> 7812 overflows/sec
 * 2 - 250000 ticks/second   -> 977 overflows/sec
 * 3 - 31250 ticks/second    -> 122 overflows/sec 
 * 4 - 7813 ticks/second     -> 30.5 overflows/sec
 * 5 - 1953 ticks/second     -> 7.6 overflows/sec
 *
 * It is based on a 2MHz clock and we count overflow interrupts to
 * specify intervals.  Clock.setRate(3,4) will fire ~10 times/sec.
 *
 */

module HPLClock {
  provides interface Clock;
  provides interface StdControl;
}
implementation {

  uint8_t intervalCnt;
  uint8_t ticks;
  uint8_t mScale;

  command result_t StdControl.init(){
    return SUCCESS;
  }

  command result_t StdControl.start(){
    return SUCCESS;
  }

  command result_t StdControl.stop(){
    return SUCCESS;
  }

  async default event result_t Clock.fire() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_OVERFLOW0) {
    atomic{
    ticks++;
      if (ticks == intervalCnt) {
	signal Clock.fire();
	ticks = 0;
      }
    }
  }

  async command result_t Clock.setRate(char interval, char scale) {
    scale &= 0x7;
    atomic{
      mScale = scale;
      cbi(TIMSK, TOIE0);     //Disable overflow interrupt
      outp(scale, TCCR0);
      outp(0, TCNT0);
      sbi(TIMSK, TOIE0);
      
      intervalCnt = interval;
      ticks = 0;
    }
    return SUCCESS;
  }

    async command uint8_t Clock.readCounter() {
        return (inp(TCNT0));
    }

    async command void Clock.setCounter(uint8_t n) {
        outp(n, TCNT0);
    }

    async command void Clock.intDisable() {
        cbi(TIMSK, TOIE0);
    }

    async command void Clock.intEnable() {
        sbi(TIMSK, TOIE0);
    }




    async command void Clock.setInterval(uint8_t value) {
        intervalCnt = value;
    } 

    // Currently does nothing in this implementation of the Clock interface
    async command void Clock.setNextInterval(uint8_t value) {
    }

    async command uint8_t Clock.getInterval() {
        return intervalCnt;
    }

    async command uint8_t Clock.getScale() {
        return mScale;
    }

    // Currently does nothing in this implementation of the Clock interface
    async command void Clock.setNextScale(uint8_t scale) {
    }
       
    // Does same thing as setRate above but with uint8_t arguments
    async command result_t Clock.setIntervalAndScale(uint8_t interval, uint8_t scale) {
        
        if (scale >5) return FAIL;

        scale &= 0x7;
        mScale = scale;
        cbi(TIMSK, TOIE0);     //Disable overflow interrupt
        outp(scale, TCCR0);
        outp(0, TCNT0);
        sbi(TIMSK, TOIE0);
        sei();
        intervalCnt = interval;
        ticks = 0;
        return SUCCESS;

    }

}
