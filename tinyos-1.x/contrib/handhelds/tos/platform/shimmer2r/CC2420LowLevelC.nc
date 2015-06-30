/**
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Abstraction interface for CC2420LowLevel
 */

configuration CC2420LowLevelC {
  provides { 
    interface StdControl;
    interface CC2420LowLevel;
    interface CC2420Interrupt as CC2420InterruptFIFO;
    interface CC2420Interrupt as CC2420InterruptFIFOP;
  }
}
implementation {
  components CC2420LowLevelM, HPLUSART1M, MSP430InterruptC;

  StdControl         = CC2420LowLevelM;
  CC2420LowLevel     = CC2420LowLevelM;
  CC2420InterruptFIFO  = CC2420LowLevelM.CC2420InterruptFIFO;
  CC2420InterruptFIFOP = CC2420LowLevelM.CC2420InterruptFIFOP;

  CC2420LowLevelM.USARTControl   -> HPLUSART1M;
  CC2420LowLevelM.FIFOPInterrupt -> MSP430InterruptC.Port10;
  CC2420LowLevelM.FIFOInterrupt  -> MSP430InterruptC.Port15;
}
