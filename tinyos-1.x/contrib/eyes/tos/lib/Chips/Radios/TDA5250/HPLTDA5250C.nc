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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250 at the HPL layer for use with the MSP430 on the 
 * eyesIFX platforms, Configuration.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2005/05/18 14:06:00 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
includes msp430baudrates; 
 
configuration HPLTDA5250C {
  provides {
    interface StdControl;
    interface HPLTDA5250Config;
    interface HPLTDA5250Data;
  }
}
implementation {
  components TimerC, HPLTDA5250M, HPLUSART0M, MSP430InterruptC;
   
  StdControl = TimerC;
  StdControl = HPLTDA5250M;
  HPLTDA5250Config = HPLTDA5250M;
  HPLTDA5250Data = HPLTDA5250M;
  
  HPLTDA5250M.SetupDelay -> TimerC.TimerJiffy[unique("TimerJiffy")];
  HPLTDA5250M.ReceiverDelay -> TimerC.TimerJiffy[unique("TimerJiffy")];
  HPLTDA5250M.TransmitterDelay -> TimerC.TimerJiffy[unique("TimerJiffy")];
  HPLTDA5250M.RSSIDelay -> TimerC.TimerJiffy[unique("TimerJiffy")];
  HPLTDA5250M.USARTControl -> HPLUSART0M;
  HPLTDA5250M.USARTFeedback -> HPLUSART0M;
  HPLTDA5250M.InterruptPort10 -> MSP430InterruptC.Port10;
}
