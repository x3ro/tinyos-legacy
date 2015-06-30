/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

// 20 Apr 2005 : GWA : MultiTimerC.nc : MultiTimer wiring diagrams.

configuration MultiTimerC {
  provides {
    interface StdControl;
    interface MicroTimer;
    interface SysTime;
  }
} implementation {
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICAZ)
  components MultiTimerATMega128M as MultiTimerM;
#elif defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
  components MultiTimerMSP430M as MultiTimerM, MSP430TimerC;
#endif

  StdControl = MultiTimerM;
  SysTime = MultiTimerM;
  MicroTimer = MultiTimerM;

#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)
  MultiTimerM.MSP430Timer -> MSP430TimerC.TimerA;
  MultiTimerM.MSP430Compare -> MSP430TimerC.CompareA0;
  MultiTimerM.MSP430TimerControl -> MSP430TimerC.ControlA0;
  MultiTimerM.MSP430OverflowControl -> MSP430TimerC.ControlA1;
#endif
}
