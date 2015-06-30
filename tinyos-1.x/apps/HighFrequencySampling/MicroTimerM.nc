// $Id: MicroTimerM.nc,v 1.5 2003/10/07 21:44:50 idgay Exp $

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
/** A micro-second interval timer, using clock1
 * (Don't use at the same time as the radio...), or with LogicalTime 
 */
module MicroTimerM
{
  /** The interval in start is in microseconds, and it only supports
      repeat timers. It does not support long intervals (max is about
      10s on the mica2) */
  provides interface MicroTimer; 
}
implementation {
#ifdef PLATFORM_MICA2
  enum { CYCLES_PER_MILLISECOND = 7373L };
#else
  enum { CYCLES_PER_MILLISECOND = 4000L };
#endif
  bool running;

  command result_t MicroTimer.start(uint32_t interval) {
    uint32_t overflow;
    uint8_t prescaler;
    bool wasRunning;

    // Avoid overflow in calculations below. When we have large values
    // of interval (close to a Hz), we drop the milliseconds to avoid
    // overflow
    if (interval > 0xffffffffUL / CYCLES_PER_MILLISECOND)
      overflow = (interval / 1000) * CYCLES_PER_MILLISECOND;
    else
      overflow = (interval * CYCLES_PER_MILLISECOND) / 1000;

    // Pick a prescaler
    if (overflow >= 65536 * 1024)
      return FAIL; // This is something like .1Hz on mica2s
    else if (overflow >= 65536UL * 256)
      {
	prescaler = 5;
	overflow /= 1024;
      }
    else if (overflow >= 65536UL * 64)
      {
	prescaler = 4;
	overflow /= 256;
      }
    else if (overflow >= 65536UL * 8)
      {
	prescaler = 3;
	overflow /= 64;
      }
    else if (overflow >= 65536UL)
      {
	overflow /= 8;
	prescaler = 2;
      }
    else
      prescaler = 1;

    atomic
      {
	wasRunning = running;
	running = TRUE;
      }
    if (wasRunning)
      return FAIL;

    outp(0, TCCR1A);
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
#define CTC1 WGM12
#endif
    outp(prescaler | 1 << CTC1, TCCR1B); // set prescaler  and overflow value
    outp(overflow >> 8, OCR1AH);
    outp(overflow, OCR1AL);
    outp(0, TCNT1H);		// reset timer
    outp(0, TCNT1L);
    sbi(TIFR, OCF1A);		// clear pending interrupt
    sbi(TIMSK, OCIE1A);		// enable overflow A interrupt

    return SUCCESS;
  }

  async command result_t MicroTimer.stop() {
    result_t ok = FAIL;

    atomic
      if (running)
	{
	  cbi(TIMSK, OCIE1A);	// disable overflow A interrupt
	  sbi(TIFR, OCF1A);	// clear pending interrupt
	  running = FALSE;
	  ok = SUCCESS;
	}
    return ok;
  }

  TOSH_SIGNAL(SIG_OUTPUT_COMPARE1A) {
    signal MicroTimer.fired();
  }
}
