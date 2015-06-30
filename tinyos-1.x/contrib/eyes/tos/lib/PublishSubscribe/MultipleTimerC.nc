/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/10/19 14:00:59 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
generic configuration MultipleTimerC()
{
  provides interface StdControl;
  provides interface Timer[uint8_t num];
} implementation {
  components TimerC, MultipleTimerM;
   
  enum {
    TIMER_ID0 = unique("Timer"),
    TIMER_ID1 = unique("Timer"),
    TIMER_ID2 = unique("Timer"),
    TIMER_ID3 = unique("Timer"),
    TIMER_ID4 = unique("Timer"),
    TIMER_ID5 = unique("Timer"),
    TIMER_ID6 = unique("Timer"),
    TIMER_ID7 = unique("Timer"),
    TIMER_ID8 = unique("Timer"),
    TIMER_ID9 = unique("Timer"),
  };
  
  StdControl = TimerC;
  Timer = MultipleTimerM;

  MultipleTimerM.Timer0 -> TimerC.Timer[TIMER_ID0];
  MultipleTimerM.Timer1 -> TimerC.Timer[TIMER_ID1];
  MultipleTimerM.Timer2 -> TimerC.Timer[TIMER_ID2];
  MultipleTimerM.Timer3 -> TimerC.Timer[TIMER_ID3];
  MultipleTimerM.Timer4 -> TimerC.Timer[TIMER_ID4];
  MultipleTimerM.Timer5 -> TimerC.Timer[TIMER_ID5];
  MultipleTimerM.Timer6 -> TimerC.Timer[TIMER_ID6];
  MultipleTimerM.Timer7 -> TimerC.Timer[TIMER_ID7];
  MultipleTimerM.Timer8 -> TimerC.Timer[TIMER_ID8];
  MultipleTimerM.Timer9 -> TimerC.Timer[TIMER_ID9];
}
